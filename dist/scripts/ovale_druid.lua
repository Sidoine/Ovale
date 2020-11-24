local __exports = LibStub:NewLibrary("ovale/scripts/ovale_druid", 80300)
if not __exports then return end
__exports.registerDruid = function(OvaleScripts)
    do
        local name = "sc_t25_druid_balance"
        local desc = "[9.0] Simulationcraft: T25_Druid_Balance"
        local code = [[
# Based on SimulationCraft profile "T25_Druid_Balance".
#	class=druid
#	spec=balance
#	talents=1000231

Include(ovale_common)
Include(ovale_druid_spells)


AddFunction prev_starsurge
{
 previousspell(starsurge)
}

AddFunction prev_starfire
{
 previousspell(starfire)
}

AddFunction prev_wrath
{
 previousspell(wrath)
}

AddFunction is_cleave
{
 enemies() > 1
}

AddFunction is_aoe
{
 enemies() > 1 and { not hastalent(starlord_talent) or hastalent(stellar_drift_talent) } or enemies() > 2
}

AddFunction starfire_in_solar
{
 enemies() > 4 + masteryeffect() / 100 / 20 + buffstacks(starsurge_empowerment_buff) / 4
}

AddFunction starfall_wont_fall_off
{
 astralpower() > 80 - 10 * buffstacks(timeworn_dreambinder_buff) - buffremaining(starfall) * 3 / { 100 / { 100 + spellcastspeedpercent() } } - target.debuffremaining(fury_of_elune) * 5 and buffpresent(starfall)
}

AddFunction dream_will_fall_off
{
 { buffremaining(timeworn_dreambinder_buff) < gcd() + 0.1 or buffremaining(timeworn_dreambinder_buff) < executetime(starfire) + 0.1 and { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 } } and buffpresent(timeworn_dreambinder_buff) and equippedruneforge(timeworn_dreambinder_runeforge)
}

AddFunction aspPerSec
{
 buffpresent(eclipse_lunar) * 8 / executetime(starfire) + { not buffpresent(eclipse_lunar) * 6 / executetime(wrath) + 0.2 / { 100 / { 100 + spellcastspeedpercent() } } }
}

AddFunction critnotup
{
 not buffpresent(balance_of_all_things_nature_buff) and not buffpresent(balance_of_all_things_arcane_buff)
}

AddFunction safe_to_use_spell
{
 buffremaining(timeworn_dreambinder_buff) > gcd() + 0.1 and { buffpresent(eclipse_solar) and buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) or counter(lunar) == 1 } or buffremaining(timeworn_dreambinder_buff) > executetime(starfire) + 0.1 and { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 } or not buffpresent(timeworn_dreambinder_buff)
}

AddFunction convoke_desync
{
 { fightremains() - 20 } / 120 > { fightremains() - 25 - 10 * talentpoints(incarnation_chosen_of_elune_talent) - 4 * conduit(precise_alignment_conduit) } / 180
}

AddFunction save_for_ca_inc
{
 not spellcooldown(celestial_alignment) == 0 or not convoke_condition() and iscovenant(night_fae)
 not spellcooldown(celestial_alignment) == 0
 not spellcooldown(celestial_alignment) == 0 or not convoke_condition() and iscovenant(night_fae)
}

AddFunction convoke_condition
{
 iscovenant(night_fae) and { buffamount(primordial_arcanic_pulsar) < 240 and { spellcooldown(celestial_alignment) + 10 > fightremains() or spellcooldown(celestial_alignment) + 30 < fightremains() and fightremains() > 130 or buffremaining(celestial_alignment) > 7 } and buffremaining(eclipse_solar) > 10 or fightremains() % 120 < 15 }
 iscovenant(night_fae) and { buffamount(primordial_arcanic_pulsar) < 240 and { spellcooldown(celestial_alignment) + 10 > fightremains() or spellcooldown(celestial_alignment) + 30 < fightremains() and fightremains() > 130 or buffremaining(celestial_alignment) > 7 } and buffremaining(eclipse_solar) > 10 or fightremains() % 120 < 15 }
 buffamount(primordial_arcanic_pulsar) < 250 - astralpower() and { spellcooldown(celestial_alignment) + 10 > fightremains() or spellcooldown(celestial_alignment) + 30 < fightremains() and fightremains() > 130 or buffremaining(celestial_alignment) > 7 } and buffpresent(eclipse_any) or fightremains() % 120 < 15
}

AddFunction dot_requirements
{
 { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and { buffremaining(eclipse_solar) > gcd() or buffremaining(eclipse_lunar) > gcd() }
}

AddCheckBox(opt_interrupt l(interrupt) default enabled=(specialization(balance)))
AddCheckBox(opt_use_consumables l(opt_use_consumables) default enabled=(specialization(balance)))

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

### actions.st

AddFunction balancestmainactions
{
 #adaptive_swarm,target_if=!dot.adaptive_swarm_damage.ticking&!action.adaptive_swarm_damage.in_flight&(!dot.adaptive_swarm_heal.ticking|dot.adaptive_swarm_heal.remains>5)|dot.adaptive_swarm_damage.stack<3&dot.adaptive_swarm_damage.remains<3&dot.adaptive_swarm_damage.ticking
 if not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) spell(adaptive_swarm)
 #variable,name=dot_requirements,value=(buff.ca_inc.remains>5&(buff.ravenous_frenzy.remains>5|!buff.ravenous_frenzy.up)|!buff.ca_inc.up|astral_power<30)&(!buff.kindred_empowerment_energize.up|astral_power<30)&(buff.eclipse_solar.remains>gcd.max|buff.eclipse_lunar.remains>gcd.max)
 #moonfire,target_if=refreshable&target.time_to_die>12,if=ap_check&variable.dot_requirements
 if target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { astralpower() >= astralpowercost(moonfire) and dot_requirements() } spell(moonfire)
 #sunfire,target_if=refreshable&target.time_to_die>12,if=ap_check&variable.dot_requirements
 if target.refreshable(sunfire) and target.timetodie() > 12 and { astralpower() >= astralpowercost(sunfire) and dot_requirements() } spell(sunfire)
 #stellar_flare,target_if=refreshable&target.time_to_die>16,if=ap_check&variable.dot_requirements
 if target.refreshable(stellar_flare) and target.timetodie() > 16 and { astralpower() >= astralpowercost(stellar_flare) and dot_requirements() } spell(stellar_flare)
 #kindred_spirits,if=((buff.eclipse_solar.remains>10|buff.eclipse_lunar.remains>10)&cooldown.ca_inc.remains>30&(buff.primordial_arcanic_pulsar.value<240|!runeforge.primordial_arcanic_pulsar.equipped))|buff.primordial_arcanic_pulsar.value>=270|cooldown.ca_inc.ready&(astral_power>90|variable.is_aoe)
 if { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 and { buffamount(primordial_arcanic_pulsar) < 240 or not equippedruneforge(primordial_arcanic_pulsar_runeforge) } or buffamount(primordial_arcanic_pulsar) >= 270 or spellcooldown(celestial_alignment) == 0 and { astralpower() > 90 or is_aoe() } spell(kindred_spirits)
 #incarnation,if=(astral_power>90&(buff.kindred_empowerment_energize.up|!covenant.kyrian)|covenant.night_fae|variable.is_aoe|buff.bloodlust.up&buff.bloodlust.remains<30+((9*runeforge.primordial_arcanic_pulsar.equipped)+(4*conduit.precise_alignment.enabled)))&!buff.ca_inc.up&(interpolated_fight_remains<cooldown.convoke_the_spirits.remains+7|interpolated_fight_remains<32+(9*(buff.primordial_arcanic_pulsar.value>100))|interpolated_fight_remains%%180<32|cooldown.convoke_the_spirits.up|!covenant.night_fae)
 if { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 9 * equippedruneforge(primordial_arcanic_pulsar_runeforge) + 4 * conduit(precise_alignment_conduit) } and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 + 9 * { buffamount(primordial_arcanic_pulsar) > 100 } or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } spell(incarnation)
 #starfall,if=buff.oneths_perception.up&buff.starfall.refreshable
 if buffpresent(oneths_perception) and buffrefreshable(starfall) spell(starfall)
 #cancel_buff,name=starlord,if=buff.starlord.remains<5&(buff.eclipse_solar.remains>5|buff.eclipse_lunar.remains>5)&astral_power>90
 if buffremaining(starlord_buff) < 5 and { buffremaining(eclipse_solar) > 5 or buffremaining(eclipse_lunar) > 5 } and astralpower() > 90 and buffpresent(starlord_buff) texture(starlord text=cancel)
 #starsurge,if=covenant.night_fae&variable.convoke_condition&cooldown.convoke_the_spirits.remains<gcd.max*ceil(astral_power%30)
 if iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } spell(starsurge)
 #starfall,if=talent.stellar_drift.enabled&!talent.starlord.enabled&buff.starfall.refreshable&(buff.eclipse_lunar.remains>6&eclipse.in_lunar&buff.primordial_arcanic_pulsar.value<250|buff.primordial_arcanic_pulsar.value>=250&astral_power>90|dot.adaptive_swarm_damage.remains>8|action.adaptive_swarm_damage.in_flight)&!cooldown.ca_inc.ready
 if hastalent(stellar_drift_talent) and not hastalent(starlord_talent) and buffrefreshable(starfall) and { buffremaining(eclipse_lunar) > 6 and buffpresent(eclipse_lunar) and buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 and astralpower() > 90 or target.debuffremaining(adaptive_swarm_damage) > 8 or inflighttotarget(adaptive_swarm_damage) } and not spellcooldown(celestial_alignment) == 0 spell(starfall)
 #starsurge,if=buff.oneths_clear_vision.up|buff.kindred_empowerment_energize.up|buff.ca_inc.up&(buff.ravenous_frenzy.remains<gcd.max*ceil(astral_power%30)&buff.ravenous_frenzy.up|!buff.ravenous_frenzy.up&!cooldown.ravenous_frenzy.ready|!covenant.venthyr)|astral_power>90&eclipse.in_any
 if buffpresent(oneths_clear_vision) or buffpresent(kindred_empowerment_energize) or buffpresent(celestial_alignment) and { buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or not buffpresent(ravenous_frenzy) and not spellcooldown(ravenous_frenzy) == 0 or not iscovenant(venthyr) } or astralpower() > 90 and buffpresent(eclipse_any) spell(starsurge)
 #starsurge,if=talent.starlord.enabled&(buff.starlord.up|astral_power>90)&buff.starlord.stack<3&(buff.eclipse_solar.up|buff.eclipse_lunar.up)&buff.primordial_arcanic_pulsar.value<270&(cooldown.ca_inc.remains>10|!variable.convoke_condition&covenant.night_fae)
 if hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and buffamount(primordial_arcanic_pulsar) < 270 and { spellcooldown(celestial_alignment) > 10 or not convoke_condition() and iscovenant(night_fae) } spell(starsurge)
 #starsurge,if=(buff.primordial_arcanic_pulsar.value<270|buff.primordial_arcanic_pulsar.value<250&talent.stellar_drift.enabled)&buff.eclipse_solar.remains>7&eclipse.in_solar&!buff.oneths_perception.up&!talent.starlord.enabled&cooldown.ca_inc.remains>7&(cooldown.kindred_spirits.remains>7|!covenant.kyrian)
 if { buffamount(primordial_arcanic_pulsar) < 270 or buffamount(primordial_arcanic_pulsar) < 250 and hastalent(stellar_drift_talent) } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not buffpresent(oneths_perception) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and { spellcooldown(kindred_spirits) > 7 or not iscovenant(kyrian) } spell(starsurge)
 #new_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } spell(new_moon)
 #half_moon,if=(buff.eclipse_lunar.up&!covenant.kyrian|(buff.kindred_empowerment_energize.up&covenant.kyrian)|(charges=2&recharge_time<5)|charges=3|buff.ca_inc.up)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) spell(half_moon)
 #full_moon,if=(buff.eclipse_lunar.up&!covenant.kyrian|(buff.kindred_empowerment_energize.up&covenant.kyrian)|(charges=2&recharge_time<5)|charges=3|buff.ca_inc.up)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) spell(full_moon)
 #starfire,if=eclipse.in_lunar|eclipse.solar_next|eclipse.any_next|buff.warrior_of_elune.up&buff.eclipse_lunar.up|(buff.ca_inc.remains<action.wrath.execute_time&buff.ca_inc.up)
 if buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) spell(starfire)
 #wrath
 spell(wrath)
 #run_action_list,name=fallthru
 balancefallthrumainactions()
}

AddFunction balancestmainpostconditions
{
 balancefallthrumainpostconditions()
}

AddFunction balancestshortcdactions
{
 unless { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { astralpower() >= astralpowercost(moonfire) and dot_requirements() } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { astralpower() >= astralpowercost(sunfire) and dot_requirements() } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { astralpower() >= astralpowercost(stellar_flare) and dot_requirements() } and spell(stellar_flare)
 {
  #force_of_nature,if=ap_check
  if astralpower() >= astralpowercost(force_of_nature) spell(force_of_nature)

  unless { { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 and { buffamount(primordial_arcanic_pulsar) < 240 or not equippedruneforge(primordial_arcanic_pulsar_runeforge) } or buffamount(primordial_arcanic_pulsar) >= 270 or spellcooldown(celestial_alignment) == 0 and { astralpower() > 90 or is_aoe() } } and spell(kindred_spirits) or { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 9 * equippedruneforge(primordial_arcanic_pulsar_runeforge) + 4 * conduit(precise_alignment_conduit) } and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 + 9 * { buffamount(primordial_arcanic_pulsar) > 100 } or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } and spell(incarnation)
  {
   #fury_of_elune,if=eclipse.in_any&ap_check&buff.primordial_arcanic_pulsar.value<240&(dot.adaptive_swarm_damage.ticking|!covenant.necrolord)&variable.save_for_ca_inc
   if buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 240 and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) } and save_for_ca_inc() spell(fury_of_elune)

   unless buffpresent(oneths_perception) and buffrefreshable(starfall) and spell(starfall) or buffremaining(starlord_buff) < 5 and { buffremaining(eclipse_solar) > 5 or buffremaining(eclipse_lunar) > 5 } and astralpower() > 90 and buffpresent(starlord_buff) and texture(starlord text=cancel) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and spell(starsurge) or hastalent(stellar_drift_talent) and not hastalent(starlord_talent) and buffrefreshable(starfall) and { buffremaining(eclipse_lunar) > 6 and buffpresent(eclipse_lunar) and buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 and astralpower() > 90 or target.debuffremaining(adaptive_swarm_damage) > 8 or inflighttotarget(adaptive_swarm_damage) } and not spellcooldown(celestial_alignment) == 0 and spell(starfall) or { buffpresent(oneths_clear_vision) or buffpresent(kindred_empowerment_energize) or buffpresent(celestial_alignment) and { buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or not buffpresent(ravenous_frenzy) and not spellcooldown(ravenous_frenzy) == 0 or not iscovenant(venthyr) } or astralpower() > 90 and buffpresent(eclipse_any) } and spell(starsurge) or hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and buffamount(primordial_arcanic_pulsar) < 270 and { spellcooldown(celestial_alignment) > 10 or not convoke_condition() and iscovenant(night_fae) } and spell(starsurge) or { buffamount(primordial_arcanic_pulsar) < 270 or buffamount(primordial_arcanic_pulsar) < 250 and hastalent(stellar_drift_talent) } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not buffpresent(oneths_perception) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and { spellcooldown(kindred_spirits) > 7 or not iscovenant(kyrian) } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon)
   {
    #warrior_of_elune
    spell(warrior_of_elune)

    unless { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath)
    {
     #run_action_list,name=fallthru
     balancefallthrushortcdactions()
    }
   }
  }
 }
}

AddFunction balancestshortcdpostconditions
{
 { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { astralpower() >= astralpowercost(moonfire) and dot_requirements() } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { astralpower() >= astralpowercost(sunfire) and dot_requirements() } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { astralpower() >= astralpowercost(stellar_flare) and dot_requirements() } and spell(stellar_flare) or { { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 and { buffamount(primordial_arcanic_pulsar) < 240 or not equippedruneforge(primordial_arcanic_pulsar_runeforge) } or buffamount(primordial_arcanic_pulsar) >= 270 or spellcooldown(celestial_alignment) == 0 and { astralpower() > 90 or is_aoe() } } and spell(kindred_spirits) or { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 9 * equippedruneforge(primordial_arcanic_pulsar_runeforge) + 4 * conduit(precise_alignment_conduit) } and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 + 9 * { buffamount(primordial_arcanic_pulsar) > 100 } or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } and spell(incarnation) or buffpresent(oneths_perception) and buffrefreshable(starfall) and spell(starfall) or buffremaining(starlord_buff) < 5 and { buffremaining(eclipse_solar) > 5 or buffremaining(eclipse_lunar) > 5 } and astralpower() > 90 and buffpresent(starlord_buff) and texture(starlord text=cancel) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and spell(starsurge) or hastalent(stellar_drift_talent) and not hastalent(starlord_talent) and buffrefreshable(starfall) and { buffremaining(eclipse_lunar) > 6 and buffpresent(eclipse_lunar) and buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 and astralpower() > 90 or target.debuffremaining(adaptive_swarm_damage) > 8 or inflighttotarget(adaptive_swarm_damage) } and not spellcooldown(celestial_alignment) == 0 and spell(starfall) or { buffpresent(oneths_clear_vision) or buffpresent(kindred_empowerment_energize) or buffpresent(celestial_alignment) and { buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or not buffpresent(ravenous_frenzy) and not spellcooldown(ravenous_frenzy) == 0 or not iscovenant(venthyr) } or astralpower() > 90 and buffpresent(eclipse_any) } and spell(starsurge) or hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and buffamount(primordial_arcanic_pulsar) < 270 and { spellcooldown(celestial_alignment) > 10 or not convoke_condition() and iscovenant(night_fae) } and spell(starsurge) or { buffamount(primordial_arcanic_pulsar) < 270 or buffamount(primordial_arcanic_pulsar) < 250 and hastalent(stellar_drift_talent) } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not buffpresent(oneths_perception) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and { spellcooldown(kindred_spirits) > 7 or not iscovenant(kyrian) } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath) or balancefallthrushortcdpostconditions()
}

AddFunction balancestcdactions
{
 unless { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { astralpower() >= astralpowercost(moonfire) and dot_requirements() } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { astralpower() >= astralpowercost(sunfire) and dot_requirements() } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { astralpower() >= astralpowercost(stellar_flare) and dot_requirements() } and spell(stellar_flare) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature)
 {
  #ravenous_frenzy,if=buff.ca_inc.up
  if buffpresent(celestial_alignment) spell(ravenous_frenzy)

  unless { { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 and { buffamount(primordial_arcanic_pulsar) < 240 or not equippedruneforge(primordial_arcanic_pulsar_runeforge) } or buffamount(primordial_arcanic_pulsar) >= 270 or spellcooldown(celestial_alignment) == 0 and { astralpower() > 90 or is_aoe() } } and spell(kindred_spirits)
  {
   #celestial_alignment,if=(astral_power>90&(buff.kindred_empowerment_energize.up|!covenant.kyrian)|covenant.night_fae|variable.is_aoe|buff.bloodlust.up&buff.bloodlust.remains<20+((9*runeforge.primordial_arcanic_pulsar.equipped)+(4*conduit.precise_alignment.enabled)))&!buff.ca_inc.up&(interpolated_fight_remains<cooldown.convoke_the_spirits.remains+7|interpolated_fight_remains<22+(9*(buff.primordial_arcanic_pulsar.value>100))|interpolated_fight_remains%%180<22|cooldown.convoke_the_spirits.up|!covenant.night_fae)
   if { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 20 + 9 * equippedruneforge(primordial_arcanic_pulsar_runeforge) + 4 * conduit(precise_alignment_conduit) } and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 22 + 9 * { buffamount(primordial_arcanic_pulsar) > 100 } or fightremains() % 180 < 22 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } spell(celestial_alignment)

   unless { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 9 * equippedruneforge(primordial_arcanic_pulsar_runeforge) + 4 * conduit(precise_alignment_conduit) } and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 + 9 * { buffamount(primordial_arcanic_pulsar) > 100 } or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } and spell(incarnation)
   {
    #variable,name=convoke_condition,value=covenant.night_fae&(buff.primordial_arcanic_pulsar.value<240&(cooldown.ca_inc.remains+10>interpolated_fight_remains|cooldown.ca_inc.remains+30<interpolated_fight_remains&interpolated_fight_remains>130|buff.ca_inc.remains>7)&buff.eclipse_solar.remains>10|interpolated_fight_remains%%120<15)
    #variable,name=save_for_ca_inc,value=(!cooldown.ca_inc.ready|!variable.convoke_condition&covenant.night_fae)
    #convoke_the_spirits,if=variable.convoke_condition&astral_power<30
    if convoke_condition() and astralpower() < 30 spell(convoke_the_spirits)

    unless buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 240 and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) } and save_for_ca_inc() and spell(fury_of_elune) or buffpresent(oneths_perception) and buffrefreshable(starfall) and spell(starfall) or buffremaining(starlord_buff) < 5 and { buffremaining(eclipse_solar) > 5 or buffremaining(eclipse_lunar) > 5 } and astralpower() > 90 and buffpresent(starlord_buff) and texture(starlord text=cancel) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and spell(starsurge) or hastalent(stellar_drift_talent) and not hastalent(starlord_talent) and buffrefreshable(starfall) and { buffremaining(eclipse_lunar) > 6 and buffpresent(eclipse_lunar) and buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 and astralpower() > 90 or target.debuffremaining(adaptive_swarm_damage) > 8 or inflighttotarget(adaptive_swarm_damage) } and not spellcooldown(celestial_alignment) == 0 and spell(starfall) or { buffpresent(oneths_clear_vision) or buffpresent(kindred_empowerment_energize) or buffpresent(celestial_alignment) and { buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or not buffpresent(ravenous_frenzy) and not spellcooldown(ravenous_frenzy) == 0 or not iscovenant(venthyr) } or astralpower() > 90 and buffpresent(eclipse_any) } and spell(starsurge) or hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and buffamount(primordial_arcanic_pulsar) < 270 and { spellcooldown(celestial_alignment) > 10 or not convoke_condition() and iscovenant(night_fae) } and spell(starsurge) or { buffamount(primordial_arcanic_pulsar) < 270 or buffamount(primordial_arcanic_pulsar) < 250 and hastalent(stellar_drift_talent) } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not buffpresent(oneths_perception) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and { spellcooldown(kindred_spirits) > 7 or not iscovenant(kyrian) } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath)
    {
     #run_action_list,name=fallthru
     balancefallthrucdactions()
    }
   }
  }
 }
}

AddFunction balancestcdpostconditions
{
 { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { astralpower() >= astralpowercost(moonfire) and dot_requirements() } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { astralpower() >= astralpowercost(sunfire) and dot_requirements() } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { astralpower() >= astralpowercost(stellar_flare) and dot_requirements() } and spell(stellar_flare) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or { { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 and { buffamount(primordial_arcanic_pulsar) < 240 or not equippedruneforge(primordial_arcanic_pulsar_runeforge) } or buffamount(primordial_arcanic_pulsar) >= 270 or spellcooldown(celestial_alignment) == 0 and { astralpower() > 90 or is_aoe() } } and spell(kindred_spirits) or { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 9 * equippedruneforge(primordial_arcanic_pulsar_runeforge) + 4 * conduit(precise_alignment_conduit) } and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 + 9 * { buffamount(primordial_arcanic_pulsar) > 100 } or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } and spell(incarnation) or buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 240 and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) } and save_for_ca_inc() and spell(fury_of_elune) or buffpresent(oneths_perception) and buffrefreshable(starfall) and spell(starfall) or buffremaining(starlord_buff) < 5 and { buffremaining(eclipse_solar) > 5 or buffremaining(eclipse_lunar) > 5 } and astralpower() > 90 and buffpresent(starlord_buff) and texture(starlord text=cancel) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and spell(starsurge) or hastalent(stellar_drift_talent) and not hastalent(starlord_talent) and buffrefreshable(starfall) and { buffremaining(eclipse_lunar) > 6 and buffpresent(eclipse_lunar) and buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 and astralpower() > 90 or target.debuffremaining(adaptive_swarm_damage) > 8 or inflighttotarget(adaptive_swarm_damage) } and not spellcooldown(celestial_alignment) == 0 and spell(starfall) or { buffpresent(oneths_clear_vision) or buffpresent(kindred_empowerment_energize) or buffpresent(celestial_alignment) and { buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or not buffpresent(ravenous_frenzy) and not spellcooldown(ravenous_frenzy) == 0 or not iscovenant(venthyr) } or astralpower() > 90 and buffpresent(eclipse_any) } and spell(starsurge) or hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and buffamount(primordial_arcanic_pulsar) < 270 and { spellcooldown(celestial_alignment) > 10 or not convoke_condition() and iscovenant(night_fae) } and spell(starsurge) or { buffamount(primordial_arcanic_pulsar) < 270 or buffamount(primordial_arcanic_pulsar) < 250 and hastalent(stellar_drift_talent) } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not buffpresent(oneths_perception) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and { spellcooldown(kindred_spirits) > 7 or not iscovenant(kyrian) } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath) or balancefallthrucdpostconditions()
}

### actions.prepatch_st

AddFunction balanceprepatch_stmainactions
{
 #moonfire,target_if=refreshable&target.time_to_die>12,if=(buff.ca_inc.remains>5|!buff.ca_inc.up|astral_power<30)&ap_check
 if target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } spell(moonfire)
 #sunfire,target_if=refreshable&target.time_to_die>12,if=(buff.ca_inc.remains>5|!buff.ca_inc.up|astral_power<30)&ap_check
 if target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } spell(sunfire)
 #stellar_flare,target_if=refreshable&target.time_to_die>16,if=(buff.ca_inc.remains>5|!buff.ca_inc.up|astral_power<30)&ap_check
 if target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } spell(stellar_flare)
 #incarnation,if=(astral_power>90|buff.bloodlust.up&buff.bloodlust.remains<36)&!buff.ca_inc.up
 if { astralpower() > 90 or buffpresent(bloodlust) and buffremaining(bloodlust) < 36 } and not buffpresent(celestial_alignment) spell(incarnation)
 #cancel_buff,name=starlord,if=buff.starlord.remains<6&(buff.eclipse_solar.up|buff.eclipse_lunar.up)&astral_power>90
 if buffremaining(starlord_buff) < 6 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and astralpower() > 90 and buffpresent(starlord_buff) texture(starlord text=cancel)
 #starsurge,if=(!azerite.streaking_stars.rank|buff.ca_inc.remains<execute_time|!variable.prev_starsurge)&(buff.ca_inc.up|astral_power>90&eclipse.in_any)
 if { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and { buffpresent(celestial_alignment) or astralpower() > 90 and buffpresent(eclipse_any) } spell(starsurge)
 #starsurge,if=(!azerite.streaking_stars.rank|buff.ca_inc.remains<execute_time|!variable.prev_starsurge)&talent.starlord.enabled&(buff.starlord.up|astral_power>90)&buff.starlord.stack<3&(buff.eclipse_solar.up|buff.eclipse_lunar.up)&cooldown.ca_inc.remains>7
 if { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and spellcooldown(celestial_alignment) > 7 spell(starsurge)
 #starsurge,if=(!azerite.streaking_stars.rank|buff.ca_inc.remains<execute_time|!variable.prev_starsurge)&buff.eclipse_solar.remains>7&eclipse.in_solar&!talent.starlord.enabled&cooldown.ca_inc.remains>7
 if { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 spell(starsurge)
 #new_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } spell(new_moon)
 #half_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3|buff.ca_inc.up)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) spell(half_moon)
 #full_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3|buff.ca_inc.up)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) spell(full_moon)
 #starfire,if=(azerite.streaking_stars.rank&buff.ca_inc.remains>execute_time&variable.prev_wrath)|(!azerite.streaking_stars.rank|buff.ca_inc.remains<execute_time|!variable.prev_starfire)&(eclipse.in_lunar|eclipse.solar_next|eclipse.any_next|buff.warrior_of_elune.up&buff.eclipse_lunar.up|(buff.ca_inc.remains<action.wrath.execute_time&buff.ca_inc.up))|(azerite.dawning_sun.rank>2&buff.eclipse_solar.remains>5&!buff.dawning_sun.remains>action.wrath.execute_time)
 if azeritetraitrank(streaking_stars_trait) and buffremaining(celestial_alignment) > executetime(starfire) and prev_wrath() or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starfire) or not prev_starfire() } and { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } or azeritetraitrank(dawning_sun_trait) > 2 and buffremaining(eclipse_solar) > 5 and not buffremaining(dawning_sun_buff) > executetime(wrath) spell(starfire)
 #wrath
 spell(wrath)
 #run_action_list,name=fallthru
 balancefallthrumainactions()
}

AddFunction balanceprepatch_stmainpostconditions
{
 balancefallthrumainpostconditions()
}

AddFunction balanceprepatch_stshortcdactions
{
 unless target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } and spell(stellar_flare)
 {
  #force_of_nature,if=ap_check
  if astralpower() >= astralpowercost(force_of_nature) spell(force_of_nature)

  unless { astralpower() > 90 or buffpresent(bloodlust) and buffremaining(bloodlust) < 36 } and not buffpresent(celestial_alignment) and spell(incarnation)
  {
   #variable,name=save_for_ca_inc,value=!cooldown.ca_inc.ready
   #fury_of_elune,if=eclipse.in_any&ap_check&variable.save_for_ca_inc
   if buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and save_for_ca_inc() spell(fury_of_elune)

   unless buffremaining(starlord_buff) < 6 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and astralpower() > 90 and buffpresent(starlord_buff) and texture(starlord text=cancel) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and { buffpresent(celestial_alignment) or astralpower() > 90 and buffpresent(eclipse_any) } and spell(starsurge) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and spellcooldown(celestial_alignment) > 7 and spell(starsurge) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon)
   {
    #warrior_of_elune
    spell(warrior_of_elune)

    unless { azeritetraitrank(streaking_stars_trait) and buffremaining(celestial_alignment) > executetime(starfire) and prev_wrath() or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starfire) or not prev_starfire() } and { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } or azeritetraitrank(dawning_sun_trait) > 2 and buffremaining(eclipse_solar) > 5 and not buffremaining(dawning_sun_buff) > executetime(wrath) } and spell(starfire) or spell(wrath)
    {
     #run_action_list,name=fallthru
     balancefallthrushortcdactions()
    }
   }
  }
 }
}

AddFunction balanceprepatch_stshortcdpostconditions
{
 target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } and spell(stellar_flare) or { astralpower() > 90 or buffpresent(bloodlust) and buffremaining(bloodlust) < 36 } and not buffpresent(celestial_alignment) and spell(incarnation) or buffremaining(starlord_buff) < 6 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and astralpower() > 90 and buffpresent(starlord_buff) and texture(starlord text=cancel) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and { buffpresent(celestial_alignment) or astralpower() > 90 and buffpresent(eclipse_any) } and spell(starsurge) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and spellcooldown(celestial_alignment) > 7 and spell(starsurge) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or { azeritetraitrank(streaking_stars_trait) and buffremaining(celestial_alignment) > executetime(starfire) and prev_wrath() or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starfire) or not prev_starfire() } and { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } or azeritetraitrank(dawning_sun_trait) > 2 and buffremaining(eclipse_solar) > 5 and not buffremaining(dawning_sun_buff) > executetime(wrath) } and spell(starfire) or spell(wrath) or balancefallthrushortcdpostconditions()
}

AddFunction balanceprepatch_stcdactions
{
 unless target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } and spell(stellar_flare) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature)
 {
  #celestial_alignment,if=(astral_power>90|buff.bloodlust.up&buff.bloodlust.remains<26)&!buff.ca_inc.up
  if { astralpower() > 90 or buffpresent(bloodlust) and buffremaining(bloodlust) < 26 } and not buffpresent(celestial_alignment) spell(celestial_alignment)

  unless { astralpower() > 90 or buffpresent(bloodlust) and buffremaining(bloodlust) < 36 } and not buffpresent(celestial_alignment) and spell(incarnation) or buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and save_for_ca_inc() and spell(fury_of_elune) or buffremaining(starlord_buff) < 6 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and astralpower() > 90 and buffpresent(starlord_buff) and texture(starlord text=cancel) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and { buffpresent(celestial_alignment) or astralpower() > 90 and buffpresent(eclipse_any) } and spell(starsurge) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and spellcooldown(celestial_alignment) > 7 and spell(starsurge) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { azeritetraitrank(streaking_stars_trait) and buffremaining(celestial_alignment) > executetime(starfire) and prev_wrath() or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starfire) or not prev_starfire() } and { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } or azeritetraitrank(dawning_sun_trait) > 2 and buffremaining(eclipse_solar) > 5 and not buffremaining(dawning_sun_buff) > executetime(wrath) } and spell(starfire) or spell(wrath)
  {
   #run_action_list,name=fallthru
   balancefallthrucdactions()
  }
 }
}

AddFunction balanceprepatch_stcdpostconditions
{
 target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 or not buffpresent(celestial_alignment) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } and spell(stellar_flare) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or { astralpower() > 90 or buffpresent(bloodlust) and buffremaining(bloodlust) < 36 } and not buffpresent(celestial_alignment) and spell(incarnation) or buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and save_for_ca_inc() and spell(fury_of_elune) or buffremaining(starlord_buff) < 6 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and astralpower() > 90 and buffpresent(starlord_buff) and texture(starlord text=cancel) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and { buffpresent(celestial_alignment) or astralpower() > 90 and buffpresent(eclipse_any) } and spell(starsurge) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and hastalent(starlord_talent) and { buffpresent(starlord_buff) or astralpower() > 90 } and buffstacks(starlord_buff) < 3 and { buffpresent(eclipse_solar) or buffpresent(eclipse_lunar) } and spellcooldown(celestial_alignment) > 7 and spell(starsurge) or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starsurge) or not prev_starsurge() } and buffremaining(eclipse_solar) > 7 and buffpresent(eclipse_solar) and not hastalent(starlord_talent) and spellcooldown(celestial_alignment) > 7 and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { azeritetraitrank(streaking_stars_trait) and buffremaining(celestial_alignment) > executetime(starfire) and prev_wrath() or { not azeritetraitrank(streaking_stars_trait) or buffremaining(celestial_alignment) < executetime(starfire) or not prev_starfire() } and { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } or azeritetraitrank(dawning_sun_trait) > 2 and buffremaining(eclipse_solar) > 5 and not buffremaining(dawning_sun_buff) > executetime(wrath) } and spell(starfire) or spell(wrath) or balancefallthrucdpostconditions()
}

### actions.precombat

AddFunction balanceprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #moonkin_form
 spell(moonkin_form)
 #wrath
 spell(wrath)
 #wrath
 spell(wrath)
 #starfire
 spell(starfire)
}

AddFunction balanceprecombatmainpostconditions
{
}

AddFunction balanceprecombatshortcdactions
{
}

AddFunction balanceprecombatshortcdpostconditions
{
 spell(moonkin_form) or spell(wrath) or spell(wrath) or spell(starfire)
}

AddFunction balanceprecombatcdactions
{
}

AddFunction balanceprecombatcdpostconditions
{
 spell(moonkin_form) or spell(wrath) or spell(wrath) or spell(starfire)
}

### actions.fallthru

AddFunction balancefallthrumainactions
{
 #starsurge,if=!runeforge.balance_of_all_things.equipped
 if not equippedruneforge(balance_of_all_things_runeforge) spell(starsurge)
 #sunfire,target_if=dot.moonfire.remains>remains
 if target.debuffremaining(moonfire_debuff) > buffremaining(sunfire) spell(sunfire)
 #moonfire
 spell(moonfire)
}

AddFunction balancefallthrumainpostconditions
{
}

AddFunction balancefallthrushortcdactions
{
}

AddFunction balancefallthrushortcdpostconditions
{
 not equippedruneforge(balance_of_all_things_runeforge) and spell(starsurge) or target.debuffremaining(moonfire_debuff) > buffremaining(sunfire) and spell(sunfire) or spell(moonfire)
}

AddFunction balancefallthrucdactions
{
}

AddFunction balancefallthrucdpostconditions
{
 not equippedruneforge(balance_of_all_things_runeforge) and spell(starsurge) or target.debuffremaining(moonfire_debuff) > buffremaining(sunfire) and spell(sunfire) or spell(moonfire)
}

### actions.dreambinder

AddFunction balancedreambindermainactions
{
 #variable,name=safe_to_use_spell,value=(buff.timeworn_dreambinder.remains>gcd.max+0.1&(eclipse.in_both|eclipse.in_solar|eclipse.lunar_next)|buff.timeworn_dreambinder.remains>action.starfire.execute_time+0.1&(eclipse.in_lunar|eclipse.solar_next|eclipse.any_next))|!buff.timeworn_dreambinder.up
 #starsurge,if=(!variable.safe_to_use_spell|(buff.ravenous_frenzy.remains<gcd.max*ceil(astral_power%30)&buff.ravenous_frenzy.up))|astral_power>90
 if not safe_to_use_spell() or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or astralpower() > 90 spell(starsurge)
 #adaptive_swarm,target_if=!dot.adaptive_swarm_damage.ticking&!action.adaptive_swarm_damage.in_flight&(!dot.adaptive_swarm_heal.ticking|dot.adaptive_swarm_heal.remains>5)|dot.adaptive_swarm_damage.stack<3&dot.adaptive_swarm_damage.remains<3&dot.adaptive_swarm_damage.ticking
 if not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) spell(adaptive_swarm)
 #moonfire,target_if=refreshable&target.time_to_die>12,if=(buff.ca_inc.remains>5&(buff.ravenous_frenzy.remains>5|!buff.ravenous_frenzy.up)|!buff.ca_inc.up|astral_power<30)&(!buff.kindred_empowerment_energize.up|astral_power<30)&ap_check
 if target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } spell(moonfire)
 #sunfire,target_if=refreshable&target.time_to_die>12,if=(buff.ca_inc.remains>5&(buff.ravenous_frenzy.remains>5|!buff.ravenous_frenzy.up)|!buff.ca_inc.up|astral_power<30)&(!buff.kindred_empowerment_energize.up|astral_power<30)&ap_check
 if target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } spell(sunfire)
 #stellar_flare,target_if=refreshable&target.time_to_die>16,if=(buff.ca_inc.remains>5&(buff.ravenous_frenzy.remains>5|!buff.ravenous_frenzy.up)|!buff.ca_inc.up|astral_power<30)&(!buff.kindred_empowerment_energize.up|astral_power<30)&ap_check
 if target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } spell(stellar_flare)
 #kindred_spirits,if=((buff.eclipse_solar.remains>10|buff.eclipse_lunar.remains>10)&cooldown.ca_inc.remains>30)|cooldown.ca_inc.ready
 if { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 spell(kindred_spirits)
 #incarnation,if=(buff.kindred_empowerment_energize.up|!covenant.kyrian)|covenant.night_fae|variable.is_aoe|buff.bloodlust.up&buff.bloodlust.remains<30+(4*conduit.precise_alignment.enabled)&!buff.ca_inc.up&(interpolated_fight_remains<cooldown.convoke_the_spirits.remains+7|interpolated_fight_remains<32|interpolated_fight_remains%%180<32|cooldown.convoke_the_spirits.up|!covenant.night_fae)
 if buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } spell(incarnation)
 #starsurge,if=covenant.night_fae&variable.convoke_condition&astral_power>=40&cooldown.convoke_the_spirits.remains<gcd.max*ceil(astral_power%30)
 if iscovenant(night_fae) and convoke_condition() and astralpower() >= 40 and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } spell(starsurge)
 #new_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } spell(new_moon)
 #half_moon,if=(buff.eclipse_lunar.up&!covenant.kyrian|(buff.kindred_empowerment_energize.up&covenant.kyrian)|(charges=2&recharge_time<5)|charges=3|buff.ca_inc.up)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) spell(half_moon)
 #full_moon,if=(buff.eclipse_lunar.up&!covenant.kyrian|(buff.kindred_empowerment_energize.up&covenant.kyrian)|(charges=2&recharge_time<5)|charges=3|buff.ca_inc.up)&ap_check&variable.save_for_ca_inc
 if { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) spell(full_moon)
 #starfire,if=eclipse.in_lunar|eclipse.solar_next|eclipse.any_next|buff.warrior_of_elune.up&buff.eclipse_lunar.up|(buff.ca_inc.remains<action.wrath.execute_time&buff.ca_inc.up)
 if buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) spell(starfire)
 #wrath
 spell(wrath)
 #run_action_list,name=fallthru
 balancefallthrumainactions()
}

AddFunction balancedreambindermainpostconditions
{
 balancefallthrumainpostconditions()
}

AddFunction balancedreambindershortcdactions
{
 unless { not safe_to_use_spell() or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or astralpower() > 90 } and spell(starsurge) or { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } and spell(stellar_flare)
 {
  #force_of_nature,if=ap_check
  if astralpower() >= astralpowercost(force_of_nature) spell(force_of_nature)

  unless { { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } and spell(kindred_spirits) or { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } } and spell(incarnation)
  {
   #fury_of_elune,if=eclipse.in_any&ap_check&(dot.adaptive_swarm_damage.ticking|!covenant.necrolord)&variable.save_for_ca_inc
   if buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) } and save_for_ca_inc() spell(fury_of_elune)

   unless iscovenant(night_fae) and convoke_condition() and astralpower() >= 40 and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon)
   {
    #warrior_of_elune
    spell(warrior_of_elune)

    unless { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath)
    {
     #run_action_list,name=fallthru
     balancefallthrushortcdactions()
    }
   }
  }
 }
}

AddFunction balancedreambindershortcdpostconditions
{
 { not safe_to_use_spell() or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or astralpower() > 90 } and spell(starsurge) or { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } and spell(stellar_flare) or { { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } and spell(kindred_spirits) or { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } } and spell(incarnation) or iscovenant(night_fae) and convoke_condition() and astralpower() >= 40 and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath) or balancefallthrushortcdpostconditions()
}

AddFunction balancedreambindercdactions
{
 unless { not safe_to_use_spell() or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or astralpower() > 90 } and spell(starsurge) or { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } and spell(stellar_flare) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature)
 {
  #ravenous_frenzy,if=buff.ca_inc.up
  if buffpresent(celestial_alignment) spell(ravenous_frenzy)

  unless { { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } and spell(kindred_spirits)
  {
   #celestial_alignment,if=(buff.kindred_empowerment_energize.up|!covenant.kyrian)|covenant.night_fae|variable.is_aoe|buff.bloodlust.up&buff.bloodlust.remains<20+(4*conduit.precise_alignment.enabled)&!buff.ca_inc.up&(interpolated_fight_remains<cooldown.convoke_the_spirits.remains+7|interpolated_fight_remains<22|interpolated_fight_remains%%180<22|cooldown.convoke_the_spirits.up|!covenant.night_fae)
   if buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 20 + 4 * conduit(precise_alignment_conduit) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 22 or fightremains() % 180 < 22 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } spell(celestial_alignment)

   unless { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } } and spell(incarnation)
   {
    #variable,name=convoke_condition,value=covenant.night_fae&(buff.primordial_arcanic_pulsar.value<240&(cooldown.ca_inc.remains+10>interpolated_fight_remains|cooldown.ca_inc.remains+30<interpolated_fight_remains&interpolated_fight_remains>130|buff.ca_inc.remains>7)&buff.eclipse_solar.remains>10|interpolated_fight_remains%%120<15)
    #variable,name=save_for_ca_inc,value=(!cooldown.ca_inc.ready|!variable.convoke_condition&covenant.night_fae)
    #convoke_the_spirits,if=variable.convoke_condition&astral_power<40
    if convoke_condition() and astralpower() < 40 spell(convoke_the_spirits)

    unless buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) } and save_for_ca_inc() and spell(fury_of_elune) or iscovenant(night_fae) and convoke_condition() and astralpower() >= 40 and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath)
    {
     #run_action_list,name=fallthru
     balancefallthrucdactions()
    }
   }
  }
 }
}

AddFunction balancedreambindercdpostconditions
{
 { not safe_to_use_spell() or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or astralpower() > 90 } and spell(starsurge) or { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or target.refreshable(sunfire) and target.timetodie() > 12 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(sunfire) } and spell(sunfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 and { { buffremaining(celestial_alignment) > 5 and { buffremaining(ravenous_frenzy) > 5 or not buffpresent(ravenous_frenzy) } or not buffpresent(celestial_alignment) or astralpower() < 30 } and { not buffpresent(kindred_empowerment_energize) or astralpower() < 30 } and astralpower() >= astralpowercost(stellar_flare) } and spell(stellar_flare) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or { { buffremaining(eclipse_solar) > 10 or buffremaining(eclipse_lunar) > 10 } and spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } and spell(kindred_spirits) or { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) or iscovenant(night_fae) or is_aoe() or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() < 32 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } } and spell(incarnation) or buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) } and save_for_ca_inc() and spell(fury_of_elune) or iscovenant(night_fae) and convoke_condition() and astralpower() >= 40 and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and save_for_ca_inc() and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(half_moon) and save_for_ca_inc() and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) and not iscovenant(kyrian) or buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 or buffpresent(celestial_alignment) } and astralpower() >= astralpowercost(full_moon) and save_for_ca_inc() and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath) or balancefallthrucdpostconditions()
}

### actions.boat

AddFunction balanceboatmainactions
{
 #variable,name=critnotup,value=!buff.balance_of_all_things_nature.up&!buff.balance_of_all_things_arcane.up
 #cancel_buff,name=starlord,if=(buff.balance_of_all_things_nature.remains>4.5|buff.balance_of_all_things_arcane.remains>4.5)&astral_power>=90&(cooldown.ca_inc.remains>7|(cooldown.empower_bond.remains>7&!buff.kindred_empowerment_energize.up&covenant.kyrian))
 if { buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 } and astralpower() >= 90 and { spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } and buffpresent(starlord_buff) texture(starlord text=cancel)
 #starsurge,if=!variable.critnotup&((!cooldown.convoke_the_spirits.up|!variable.convoke_condition|!covenant.night_fae)&(covenant.night_fae|(cooldown.ca_inc.remains>7|(cooldown.empower_bond.remains>7&!buff.kindred_empowerment_energize.up&covenant.kyrian))))|(cooldown.convoke_the_spirits.up&cooldown.ca_inc.ready&covenant.night_fae)
 if not critnotup() and { not { not spellcooldown(convoke_the_spirits) > 0 } or not convoke_condition() or not iscovenant(night_fae) } and { iscovenant(night_fae) or spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } or not spellcooldown(convoke_the_spirits) > 0 and spellcooldown(celestial_alignment) == 0 and iscovenant(night_fae) spell(starsurge)
 #adaptive_swarm,target_if=!dot.adaptive_swarm_damage.ticking&!action.adaptive_swarm_damage.in_flight&(!dot.adaptive_swarm_heal.ticking|dot.adaptive_swarm_heal.remains>5)|dot.adaptive_swarm_damage.stack<3&dot.adaptive_swarm_damage.remains<3&dot.adaptive_swarm_damage.ticking
 if not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) spell(adaptive_swarm)
 #sunfire,target_if=refreshable&target.time_to_die>16,if=ap_check&(variable.critnotup|(astral_power<30&!buff.ca_inc.up)|cooldown.ca_inc.ready)
 if target.refreshable(sunfire) and target.timetodie() > 16 and { astralpower() >= astralpowercost(sunfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } } spell(sunfire)
 #moonfire,target_if=refreshable&target.time_to_die>13.5,if=ap_check&(variable.critnotup|(astral_power<30&!buff.ca_inc.up)|cooldown.ca_inc.ready)&!buff.kindred_empowerment_energize.up
 if target.refreshable(moonfire_debuff) and target.timetodie() > 13.5 and { astralpower() >= astralpowercost(moonfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } and not buffpresent(kindred_empowerment_energize) } spell(moonfire)
 #stellar_flare,target_if=refreshable&target.time_to_die>16+remains,if=ap_check&(variable.critnotup|astral_power<30|cooldown.ca_inc.ready)
 if target.refreshable(stellar_flare) and target.timetodie() > 16 + buffremaining(stellar_flare) and { astralpower() >= astralpowercost(stellar_flare) and { critnotup() or astralpower() < 30 or spellcooldown(celestial_alignment) == 0 } } spell(stellar_flare)
 #kindred_spirits,if=(eclipse.lunar_next|eclipse.solar_next|eclipse.any_next|buff.balance_of_all_things_nature.remains>4.5|buff.balance_of_all_things_arcane.remains>4.5|astral_power>90&cooldown.ca_inc.ready)&(cooldown.ca_inc.remains>30|cooldown.ca_inc.ready)|interpolated_fight_remains<10
 if { counter(lunar) == 1 or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 or astralpower() > 90 and spellcooldown(celestial_alignment) == 0 } and { spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } or fightremains() < 10 spell(kindred_spirits)
 #incarnation,if=(astral_power>90&(buff.kindred_empowerment_energize.up|!covenant.kyrian)|covenant.night_fae|buff.bloodlust.up&buff.bloodlust.remains<30+(4*conduit.precise_alignment.enabled))&(!covenant.night_fae|cooldown.convoke_the_spirits.up|variable.convoke_desync&interpolated_fight_remains>180+20+(4*conduit.precise_alignment.enabled)|interpolated_fight_remains<cooldown.convoke_the_spirits.remains+6|interpolated_fight_remains<30+(4*conduit.precise_alignment.enabled))
 if { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) } and { not iscovenant(night_fae) or not spellcooldown(convoke_the_spirits) > 0 or convoke_desync() and fightremains() > 180 + 20 + 4 * conduit(precise_alignment_conduit) or fightremains() < spellcooldown(convoke_the_spirits) + 6 or fightremains() < 30 + 4 * conduit(precise_alignment_conduit) } spell(incarnation)
 #starsurge,if=covenant.night_fae&(variable.convoke_desync|cooldown.ca_inc.remains<10)&astral_power>50&cooldown.convoke_the_spirits.remains<10
 if iscovenant(night_fae) and { convoke_desync() or spellcooldown(celestial_alignment) < 10 } and astralpower() > 50 and spellcooldown(convoke_the_spirits) < 10 spell(starsurge)
 #variable,name=aspPerSec,value=eclipse.in_lunar*8%action.starfire.execute_time+!eclipse.in_lunar*6%action.wrath.execute_time+0.2%spell_haste
 #starsurge,if=(interpolated_fight_remains<4|(buff.ravenous_frenzy.remains<gcd.max*ceil(astral_power%30)&buff.ravenous_frenzy.up))|(astral_power+variable.aspPerSec*buff.eclipse_solar.remains+dot.fury_of_elune.ticks_remain*2.5>120|astral_power+variable.aspPerSec*buff.eclipse_lunar.remains+dot.fury_of_elune.ticks_remain*2.5>120)&eclipse.in_any&((!cooldown.ca_inc.up|covenant.kyrian&!cooldown.empower_bond.up)|covenant.night_fae)&(!covenant.venthyr|!buff.ca_inc.up|astral_power>90)|buff.ca_inc.remains>8&!buff.ravenous_frenzy.up
 if fightremains() < 4 or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or { astralpower() + aspPerSec() * buffremaining(eclipse_solar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 or astralpower() + aspPerSec() * buffremaining(eclipse_lunar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 } and buffpresent(eclipse_any) and { not { not spellcooldown(celestial_alignment) > 0 } or iscovenant(kyrian) and not { not spellcooldown(empower_bond) > 0 } or iscovenant(night_fae) } and { not iscovenant(venthyr) or not buffpresent(celestial_alignment) or astralpower() > 90 } or buffremaining(celestial_alignment) > 8 and not buffpresent(ravenous_frenzy) spell(starsurge)
 #new_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } spell(new_moon)
 #half_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) spell(half_moon)
 #full_moon,if=(buff.eclipse_lunar.up|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) spell(full_moon)
 #starfire,if=eclipse.in_lunar|eclipse.solar_next|eclipse.any_next|buff.warrior_of_elune.up&eclipse.in_lunar|(buff.ca_inc.remains<action.wrath.execute_time&buff.ca_inc.up)
 if buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) spell(starfire)
 #wrath
 spell(wrath)
 #run_action_list,name=fallthru
 balancefallthrumainactions()
}

AddFunction balanceboatmainpostconditions
{
 balancefallthrumainpostconditions()
}

AddFunction balanceboatshortcdactions
{
 unless { buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 } and astralpower() >= 90 and { spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } and buffpresent(starlord_buff) and texture(starlord text=cancel) or { not critnotup() and { not { not spellcooldown(convoke_the_spirits) > 0 } or not convoke_condition() or not iscovenant(night_fae) } and { iscovenant(night_fae) or spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } or not spellcooldown(convoke_the_spirits) > 0 and spellcooldown(celestial_alignment) == 0 and iscovenant(night_fae) } and spell(starsurge) or { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(sunfire) and target.timetodie() > 16 and { astralpower() >= astralpowercost(sunfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } } and spell(sunfire) or target.refreshable(moonfire_debuff) and target.timetodie() > 13.5 and { astralpower() >= astralpowercost(moonfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } and not buffpresent(kindred_empowerment_energize) } and spell(moonfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 + buffremaining(stellar_flare) and { astralpower() >= astralpowercost(stellar_flare) and { critnotup() or astralpower() < 30 or spellcooldown(celestial_alignment) == 0 } } and spell(stellar_flare)
 {
  #force_of_nature,if=ap_check
  if astralpower() >= astralpowercost(force_of_nature) spell(force_of_nature)
  #fury_of_elune,if=(eclipse.in_any|eclipse.solar_in_1|eclipse.lunar_in_1)&(!covenant.night_fae|(astral_power<95&(variable.critnotup|astral_power<30|variable.is_aoe)&(variable.convoke_desync&!cooldown.convoke_the_spirits.up|!variable.convoke_desync&!cooldown.ca_inc.up)))&(cooldown.ca_inc.remains>30|astral_power>90&cooldown.ca_inc.up&(cooldown.empower_bond.remains<action.starfire.execute_time|!covenant.kyrian)|interpolated_fight_remains<10)&(dot.adaptive_swarm_damage.remains>4|!covenant.necrolord)
  if { buffpresent(eclipse_any) or counter(solar) == 1 or counter(lunar) == 1 } and { not iscovenant(night_fae) or astralpower() < 95 and { critnotup() or astralpower() < 30 or is_aoe() } and { convoke_desync() and not { not spellcooldown(convoke_the_spirits) > 0 } or not convoke_desync() and not { not spellcooldown(celestial_alignment) > 0 } } } and { spellcooldown(celestial_alignment) > 30 or astralpower() > 90 and not spellcooldown(celestial_alignment) > 0 and { spellcooldown(empower_bond) < executetime(starfire) or not iscovenant(kyrian) } or fightremains() < 10 } and { target.debuffremaining(adaptive_swarm_damage) > 4 or not iscovenant(necrolord) } spell(fury_of_elune)

  unless { { counter(lunar) == 1 or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 or astralpower() > 90 and spellcooldown(celestial_alignment) == 0 } and { spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } or fightremains() < 10 } and spell(kindred_spirits) or { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) } and { not iscovenant(night_fae) or not spellcooldown(convoke_the_spirits) > 0 or convoke_desync() and fightremains() > 180 + 20 + 4 * conduit(precise_alignment_conduit) or fightremains() < spellcooldown(convoke_the_spirits) + 6 or fightremains() < 30 + 4 * conduit(precise_alignment_conduit) } and spell(incarnation) or iscovenant(night_fae) and { convoke_desync() or spellcooldown(celestial_alignment) < 10 } and astralpower() > 50 and spellcooldown(convoke_the_spirits) < 10 and spell(starsurge) or { fightremains() < 4 or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or { astralpower() + aspPerSec() * buffremaining(eclipse_solar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 or astralpower() + aspPerSec() * buffremaining(eclipse_lunar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 } and buffpresent(eclipse_any) and { not { not spellcooldown(celestial_alignment) > 0 } or iscovenant(kyrian) and not { not spellcooldown(empower_bond) > 0 } or iscovenant(night_fae) } and { not iscovenant(venthyr) or not buffpresent(celestial_alignment) or astralpower() > 90 } or buffremaining(celestial_alignment) > 8 and not buffpresent(ravenous_frenzy) } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon)
  {
   #warrior_of_elune
   spell(warrior_of_elune)

   unless { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath)
   {
    #run_action_list,name=fallthru
    balancefallthrushortcdactions()
   }
  }
 }
}

AddFunction balanceboatshortcdpostconditions
{
 { buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 } and astralpower() >= 90 and { spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } and buffpresent(starlord_buff) and texture(starlord text=cancel) or { not critnotup() and { not { not spellcooldown(convoke_the_spirits) > 0 } or not convoke_condition() or not iscovenant(night_fae) } and { iscovenant(night_fae) or spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } or not spellcooldown(convoke_the_spirits) > 0 and spellcooldown(celestial_alignment) == 0 and iscovenant(night_fae) } and spell(starsurge) or { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(sunfire) and target.timetodie() > 16 and { astralpower() >= astralpowercost(sunfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } } and spell(sunfire) or target.refreshable(moonfire_debuff) and target.timetodie() > 13.5 and { astralpower() >= astralpowercost(moonfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } and not buffpresent(kindred_empowerment_energize) } and spell(moonfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 + buffremaining(stellar_flare) and { astralpower() >= astralpowercost(stellar_flare) and { critnotup() or astralpower() < 30 or spellcooldown(celestial_alignment) == 0 } } and spell(stellar_flare) or { { counter(lunar) == 1 or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 or astralpower() > 90 and spellcooldown(celestial_alignment) == 0 } and { spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } or fightremains() < 10 } and spell(kindred_spirits) or { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) } and { not iscovenant(night_fae) or not spellcooldown(convoke_the_spirits) > 0 or convoke_desync() and fightremains() > 180 + 20 + 4 * conduit(precise_alignment_conduit) or fightremains() < spellcooldown(convoke_the_spirits) + 6 or fightremains() < 30 + 4 * conduit(precise_alignment_conduit) } and spell(incarnation) or iscovenant(night_fae) and { convoke_desync() or spellcooldown(celestial_alignment) < 10 } and astralpower() > 50 and spellcooldown(convoke_the_spirits) < 10 and spell(starsurge) or { fightremains() < 4 or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or { astralpower() + aspPerSec() * buffremaining(eclipse_solar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 or astralpower() + aspPerSec() * buffremaining(eclipse_lunar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 } and buffpresent(eclipse_any) and { not { not spellcooldown(celestial_alignment) > 0 } or iscovenant(kyrian) and not { not spellcooldown(empower_bond) > 0 } or iscovenant(night_fae) } and { not iscovenant(venthyr) or not buffpresent(celestial_alignment) or astralpower() > 90 } or buffremaining(celestial_alignment) > 8 and not buffpresent(ravenous_frenzy) } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath) or balancefallthrushortcdpostconditions()
}

AddFunction balanceboatcdactions
{
 #ravenous_frenzy,if=buff.ca_inc.up
 if buffpresent(celestial_alignment) spell(ravenous_frenzy)

 unless { buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 } and astralpower() >= 90 and { spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } and buffpresent(starlord_buff) and texture(starlord text=cancel) or { not critnotup() and { not { not spellcooldown(convoke_the_spirits) > 0 } or not convoke_condition() or not iscovenant(night_fae) } and { iscovenant(night_fae) or spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } or not spellcooldown(convoke_the_spirits) > 0 and spellcooldown(celestial_alignment) == 0 and iscovenant(night_fae) } and spell(starsurge) or { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(sunfire) and target.timetodie() > 16 and { astralpower() >= astralpowercost(sunfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } } and spell(sunfire) or target.refreshable(moonfire_debuff) and target.timetodie() > 13.5 and { astralpower() >= astralpowercost(moonfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } and not buffpresent(kindred_empowerment_energize) } and spell(moonfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 + buffremaining(stellar_flare) and { astralpower() >= astralpowercost(stellar_flare) and { critnotup() or astralpower() < 30 or spellcooldown(celestial_alignment) == 0 } } and spell(stellar_flare) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or { buffpresent(eclipse_any) or counter(solar) == 1 or counter(lunar) == 1 } and { not iscovenant(night_fae) or astralpower() < 95 and { critnotup() or astralpower() < 30 or is_aoe() } and { convoke_desync() and not { not spellcooldown(convoke_the_spirits) > 0 } or not convoke_desync() and not { not spellcooldown(celestial_alignment) > 0 } } } and { spellcooldown(celestial_alignment) > 30 or astralpower() > 90 and not spellcooldown(celestial_alignment) > 0 and { spellcooldown(empower_bond) < executetime(starfire) or not iscovenant(kyrian) } or fightremains() < 10 } and { target.debuffremaining(adaptive_swarm_damage) > 4 or not iscovenant(necrolord) } and spell(fury_of_elune) or { { counter(lunar) == 1 or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 or astralpower() > 90 and spellcooldown(celestial_alignment) == 0 } and { spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } or fightremains() < 10 } and spell(kindred_spirits)
 {
  #celestial_alignment,if=(astral_power>90&(buff.kindred_empowerment_energize.up|!covenant.kyrian)|covenant.night_fae|buff.bloodlust.up&buff.bloodlust.remains<20+(4*conduit.precise_alignment.enabled))&(!covenant.night_fae|cooldown.convoke_the_spirits.up|interpolated_fight_remains<cooldown.convoke_the_spirits.remains+6|interpolated_fight_remains%%180<20+(4*conduit.precise_alignment.enabled))
  if { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or buffpresent(bloodlust) and buffremaining(bloodlust) < 20 + 4 * conduit(precise_alignment_conduit) } and { not iscovenant(night_fae) or not spellcooldown(convoke_the_spirits) > 0 or fightremains() < spellcooldown(convoke_the_spirits) + 6 or fightremains() % 180 < 20 + 4 * conduit(precise_alignment_conduit) } spell(celestial_alignment)

  unless { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) } and { not iscovenant(night_fae) or not spellcooldown(convoke_the_spirits) > 0 or convoke_desync() and fightremains() > 180 + 20 + 4 * conduit(precise_alignment_conduit) or fightremains() < spellcooldown(convoke_the_spirits) + 6 or fightremains() < 30 + 4 * conduit(precise_alignment_conduit) } and spell(incarnation)
  {
   #convoke_the_spirits,if=(variable.convoke_desync&interpolated_fight_remains>130|buff.ca_inc.up)&(buff.balance_of_all_things_nature.stack_value>30|buff.balance_of_all_things_arcane.stack_value>30)|interpolated_fight_remains<10
   if { convoke_desync() and fightremains() > 130 or buffpresent(celestial_alignment) } and { buffstacks(balance_of_all_things_nature_buff) > 30 or buffstacks(balance_of_all_things_arcane_buff) > 30 } or fightremains() < 10 spell(convoke_the_spirits)

   unless iscovenant(night_fae) and { convoke_desync() or spellcooldown(celestial_alignment) < 10 } and astralpower() > 50 and spellcooldown(convoke_the_spirits) < 10 and spell(starsurge) or { fightremains() < 4 or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or { astralpower() + aspPerSec() * buffremaining(eclipse_solar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 or astralpower() + aspPerSec() * buffremaining(eclipse_lunar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 } and buffpresent(eclipse_any) and { not { not spellcooldown(celestial_alignment) > 0 } or iscovenant(kyrian) and not { not spellcooldown(empower_bond) > 0 } or iscovenant(night_fae) } and { not iscovenant(venthyr) or not buffpresent(celestial_alignment) or astralpower() > 90 } or buffremaining(celestial_alignment) > 8 and not buffpresent(ravenous_frenzy) } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath)
   {
    #run_action_list,name=fallthru
    balancefallthrucdactions()
   }
  }
 }
}

AddFunction balanceboatcdpostconditions
{
 { buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 } and astralpower() >= 90 and { spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } and buffpresent(starlord_buff) and texture(starlord text=cancel) or { not critnotup() and { not { not spellcooldown(convoke_the_spirits) > 0 } or not convoke_condition() or not iscovenant(night_fae) } and { iscovenant(night_fae) or spellcooldown(celestial_alignment) > 7 or spellcooldown(empower_bond) > 7 and not buffpresent(kindred_empowerment_energize) and iscovenant(kyrian) } or not spellcooldown(convoke_the_spirits) > 0 and spellcooldown(celestial_alignment) == 0 and iscovenant(night_fae) } and spell(starsurge) or { not target.debuffpresent(adaptive_swarm_damage) and not inflighttotarget(adaptive_swarm_damage) and { not target.debuffpresent(adaptive_swarm) or target.debuffremaining(adaptive_swarm) > 5 } or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 and target.debuffpresent(adaptive_swarm_damage) } and spell(adaptive_swarm) or target.refreshable(sunfire) and target.timetodie() > 16 and { astralpower() >= astralpowercost(sunfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } } and spell(sunfire) or target.refreshable(moonfire_debuff) and target.timetodie() > 13.5 and { astralpower() >= astralpowercost(moonfire) and { critnotup() or astralpower() < 30 and not buffpresent(celestial_alignment) or spellcooldown(celestial_alignment) == 0 } and not buffpresent(kindred_empowerment_energize) } and spell(moonfire) or target.refreshable(stellar_flare) and target.timetodie() > 16 + buffremaining(stellar_flare) and { astralpower() >= astralpowercost(stellar_flare) and { critnotup() or astralpower() < 30 or spellcooldown(celestial_alignment) == 0 } } and spell(stellar_flare) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or { buffpresent(eclipse_any) or counter(solar) == 1 or counter(lunar) == 1 } and { not iscovenant(night_fae) or astralpower() < 95 and { critnotup() or astralpower() < 30 or is_aoe() } and { convoke_desync() and not { not spellcooldown(convoke_the_spirits) > 0 } or not convoke_desync() and not { not spellcooldown(celestial_alignment) > 0 } } } and { spellcooldown(celestial_alignment) > 30 or astralpower() > 90 and not spellcooldown(celestial_alignment) > 0 and { spellcooldown(empower_bond) < executetime(starfire) or not iscovenant(kyrian) } or fightremains() < 10 } and { target.debuffremaining(adaptive_swarm_damage) > 4 or not iscovenant(necrolord) } and spell(fury_of_elune) or { { counter(lunar) == 1 or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffremaining(balance_of_all_things_nature_buff) > 4.5 or buffremaining(balance_of_all_things_arcane_buff) > 4.5 or astralpower() > 90 and spellcooldown(celestial_alignment) == 0 } and { spellcooldown(celestial_alignment) > 30 or spellcooldown(celestial_alignment) == 0 } or fightremains() < 10 } and spell(kindred_spirits) or { astralpower() > 90 and { buffpresent(kindred_empowerment_energize) or not iscovenant(kyrian) } or iscovenant(night_fae) or buffpresent(bloodlust) and buffremaining(bloodlust) < 30 + 4 * conduit(precise_alignment_conduit) } and { not iscovenant(night_fae) or not spellcooldown(convoke_the_spirits) > 0 or convoke_desync() and fightremains() > 180 + 20 + 4 * conduit(precise_alignment_conduit) or fightremains() < spellcooldown(convoke_the_spirits) + 6 or fightremains() < 30 + 4 * conduit(precise_alignment_conduit) } and spell(incarnation) or iscovenant(night_fae) and { convoke_desync() or spellcooldown(celestial_alignment) < 10 } and astralpower() > 50 and spellcooldown(convoke_the_spirits) < 10 and spell(starsurge) or { fightremains() < 4 or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) or { astralpower() + aspPerSec() * buffremaining(eclipse_solar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 or astralpower() + aspPerSec() * buffremaining(eclipse_lunar) + target.ticksremaining(fury_of_elune) * 2.5 > 120 } and buffpresent(eclipse_any) and { not { not spellcooldown(celestial_alignment) > 0 } or iscovenant(kyrian) and not { not spellcooldown(empower_bond) > 0 } or iscovenant(night_fae) } and { not iscovenant(venthyr) or not buffpresent(celestial_alignment) or astralpower() > 90 } or buffremaining(celestial_alignment) > 8 and not buffpresent(ravenous_frenzy) } and spell(starsurge) or { buffpresent(eclipse_lunar) or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_lunar) or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_lunar) or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or counter(lunar) + counter(solar) == 1 or buffpresent(warrior_of_elune) and buffpresent(eclipse_lunar) or buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) } and spell(starfire) or spell(wrath) or balancefallthrucdpostconditions()
}

### actions.aoe

AddFunction balanceaoemainactions
{
 #variable,name=dream_will_fall_off,value=(buff.timeworn_dreambinder.remains<gcd.max+0.1|buff.timeworn_dreambinder.remains<action.starfire.execute_time+0.1&(eclipse.in_lunar|eclipse.solar_next|eclipse.any_next))&buff.timeworn_dreambinder.up&runeforge.timeworn_dreambinder.equipped
 #starfall,if=buff.starfall.refreshable&(spell_targets.starfall<3|!runeforge.timeworn_dreambinder.equipped)&(!runeforge.lycaras_fleeting_glimpse.equipped|time%%45>buff.starfall.remains+2)
 if buffrefreshable(starfall) and { enemies() < 3 or not equippedruneforge(timeworn_dreambinder_runeforge) } and { not equippedruneforge(lycaras_fleeting_glimpse_runeforge) or timeincombat() % 45 > buffremaining(starfall) + 2 } spell(starfall)
 #starfall,if=runeforge.timeworn_dreambinder.equipped&spell_targets.starfall>=3&(!buff.timeworn_dreambinder.up&buff.starfall.refreshable|(variable.dream_will_fall_off&(buff.starfall.remains<3|spell_targets.starfall>2&talent.stellar_drift.enabled&buff.starfall.remains<5)))
 if equippedruneforge(timeworn_dreambinder_runeforge) and enemies() >= 3 and { not buffpresent(timeworn_dreambinder_buff) and buffrefreshable(starfall) or dream_will_fall_off() and { buffremaining(starfall) < 3 or enemies() > 2 and hastalent(stellar_drift_talent) and buffremaining(starfall) < 5 } } spell(starfall)
 #variable,name=starfall_wont_fall_off,value=astral_power>80-(10*buff.timeworn_dreambinder.stack)-(buff.starfall.remains*3%spell_haste)-(dot.fury_of_elune.remains*5)&buff.starfall.up
 #starsurge,if=variable.dream_will_fall_off&variable.starfall_wont_fall_off
 if dream_will_fall_off() and starfall_wont_fall_off() spell(starsurge)
 #sunfire,target_if=refreshable&target.time_to_die>14-spell_targets+remains,if=ap_check&eclipse.in_any
 if target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and { astralpower() >= astralpowercost(sunfire) and buffpresent(eclipse_any) } spell(sunfire)
 #adaptive_swarm,target_if=!ticking&!action.adaptive_swarm_damage.in_flight|dot.adaptive_swarm_damage.stack<3&dot.adaptive_swarm_damage.remains<3
 if not buffpresent(adaptive_swarm) and not inflighttotarget(adaptive_swarm_damage) or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 spell(adaptive_swarm)
 #moonfire,target_if=refreshable&target.time_to_die>(14+(spell_targets.starfire*1.5))%spell_targets+remains,if=(cooldown.ca_inc.ready|spell_targets.starfire<3|(eclipse.in_solar|eclipse.in_both|eclipse.in_lunar&!talent.soul_of_the_forest.enabled|buff.primordial_arcanic_pulsar.value>=250)&(spell_targets.starfire<10*(1+talent.twin_moons.enabled))&astral_power>50-buff.starfall.remains*6)&!buff.kindred_empowerment_energize.up&ap_check
 if target.refreshable(moonfire_debuff) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + target.debuffremaining(moonfire_debuff) and { { spellcooldown(celestial_alignment) == 0 or enemies() < 3 or { buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and buffpresent(eclipse_lunar) or buffpresent(eclipse_lunar) and not hastalent(soul_of_the_forest_talent) or buffamount(primordial_arcanic_pulsar) >= 250 } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize) and astralpower() >= astralpowercost(moonfire) } spell(moonfire)
 #incarnation,if=(buff.starfall.up|astral_power>50)&!buff.solstice.up&!buff.ca_inc.up&(interpolated_fight_remains<cooldown.convoke_the_spirits.remains+7|interpolated_fight_remains%%180<32|cooldown.convoke_the_spirits.up|!covenant.night_fae)
 if { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } spell(incarnation)
 #kindred_spirits,if=interpolated_fight_remains<15|(buff.primordial_arcanic_pulsar.value<250|buff.primordial_arcanic_pulsar.value>=250)&buff.starfall.up&cooldown.ca_inc.remains>50
 if fightremains() < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(celestial_alignment) > 50 spell(kindred_spirits)
 #stellar_flare,target_if=refreshable&time_to_die>15,if=spell_targets.starfire<4&ap_check&(buff.ca_inc.remains>10|!buff.ca_inc.up)
 if target.refreshable(stellar_flare) and target.timetodie() > 15 and { enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(celestial_alignment) > 10 or not buffpresent(celestial_alignment) } } spell(stellar_flare)
 #starfall,if=buff.oneths_perception.up&(buff.starfall.refreshable|astral_power>90)
 if buffpresent(oneths_perception) and { buffrefreshable(starfall) or astralpower() > 90 } spell(starfall)
 #starfall,if=covenant.night_fae&variable.convoke_condition&cooldown.convoke_the_spirits.remains<gcd.max*ceil(astral_power%50)&buff.starfall.refreshable
 if iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and buffrefreshable(starfall) spell(starfall)
 #starsurge,if=covenant.night_fae&variable.convoke_condition&cooldown.convoke_the_spirits.remains<gcd.max*ceil(astral_power%30)&buff.starfall.up
 if iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) spell(starsurge)
 #starsurge,if=buff.oneths_clear_vision.up|(!starfire.ap_check|(buff.ca_inc.remains<5&buff.ca_inc.up|(buff.ravenous_frenzy.remains<gcd.max*ceil(astral_power%30)&buff.ravenous_frenzy.up))&variable.starfall_wont_fall_off&spell_targets.starfall<3)&(!runeforge.timeworn_dreambinder.equipped|spell_targets.starfall<3)
 if buffpresent(oneths_clear_vision) or { not astralpower() >= astralpowercost(starfire) or { buffremaining(celestial_alignment) < 5 and buffpresent(celestial_alignment) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and { not equippedruneforge(timeworn_dreambinder_runeforge) or enemies() < 3 } spell(starsurge)
 #new_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } spell(new_moon)
 #half_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) spell(half_moon)
 #full_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) spell(full_moon)
 #variable,name=starfire_in_solar,value=spell_targets.starfire>4+floor(mastery_value%20)+floor(buff.starsurge_empowerment.stack%4)
 #wrath,if=eclipse.lunar_next|eclipse.any_next&variable.is_cleave|buff.eclipse_solar.remains<action.starfire.execute_time&buff.eclipse_solar.up|eclipse.in_solar&!variable.starfire_in_solar|buff.ca_inc.remains<action.starfire.execute_time&!variable.is_cleave&buff.ca_inc.remains<execute_time&buff.ca_inc.up|buff.ravenous_frenzy.up&spell_haste>0.6&(spell_targets<=3|!talent.soul_of_the_forest.enabled)|!variable.is_cleave&buff.ca_inc.remains>execute_time
 if counter(lunar) == 1 or counter(lunar) + counter(solar) == 1 and is_cleave() or buffremaining(eclipse_solar) < executetime(starfire) and buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and not starfire_in_solar() or buffremaining(celestial_alignment) < executetime(starfire) and not is_cleave() and buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 and { enemies() <= 3 or not hastalent(soul_of_the_forest_talent) } or not is_cleave() and buffremaining(celestial_alignment) > executetime(wrath) spell(wrath)
 #starfire
 spell(starfire)
 #run_action_list,name=fallthru
 balancefallthrumainactions()
}

AddFunction balanceaoemainpostconditions
{
 balancefallthrumainpostconditions()
}

AddFunction balanceaoeshortcdactions
{
 unless buffrefreshable(starfall) and { enemies() < 3 or not equippedruneforge(timeworn_dreambinder_runeforge) } and { not equippedruneforge(lycaras_fleeting_glimpse_runeforge) or timeincombat() % 45 > buffremaining(starfall) + 2 } and spell(starfall) or equippedruneforge(timeworn_dreambinder_runeforge) and enemies() >= 3 and { not buffpresent(timeworn_dreambinder_buff) and buffrefreshable(starfall) or dream_will_fall_off() and { buffremaining(starfall) < 3 or enemies() > 2 and hastalent(stellar_drift_talent) and buffremaining(starfall) < 5 } } and spell(starfall) or dream_will_fall_off() and starfall_wont_fall_off() and spell(starsurge) or target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and { astralpower() >= astralpowercost(sunfire) and buffpresent(eclipse_any) } and spell(sunfire) or { not buffpresent(adaptive_swarm) and not inflighttotarget(adaptive_swarm_damage) or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + target.debuffremaining(moonfire_debuff) and { { spellcooldown(celestial_alignment) == 0 or enemies() < 3 or { buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and buffpresent(eclipse_lunar) or buffpresent(eclipse_lunar) and not hastalent(soul_of_the_forest_talent) or buffamount(primordial_arcanic_pulsar) >= 250 } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize) and astralpower() >= astralpowercost(moonfire) } and spell(moonfire)
 {
  #force_of_nature,if=ap_check
  if astralpower() >= astralpowercost(force_of_nature) spell(force_of_nature)

  unless { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } and spell(incarnation) or { fightremains() < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(celestial_alignment) > 50 } and spell(kindred_spirits) or target.refreshable(stellar_flare) and target.timetodie() > 15 and { enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(celestial_alignment) > 10 or not buffpresent(celestial_alignment) } } and spell(stellar_flare)
  {
   #fury_of_elune,if=eclipse.in_any&ap_check&buff.primordial_arcanic_pulsar.value<250&(dot.adaptive_swarm_damage.ticking|!covenant.necrolord|spell_targets>2)
   if buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 250 and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) or enemies() > 2 } spell(fury_of_elune)

   unless buffpresent(oneths_perception) and { buffrefreshable(starfall) or astralpower() > 90 } and spell(starfall) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and buffrefreshable(starfall) and spell(starfall) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) and spell(starsurge) or { buffpresent(oneths_clear_vision) or { not astralpower() >= astralpowercost(starfire) or { buffremaining(celestial_alignment) < 5 and buffpresent(celestial_alignment) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and { not equippedruneforge(timeworn_dreambinder_runeforge) or enemies() < 3 } } and spell(starsurge) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon)
   {
    #warrior_of_elune
    spell(warrior_of_elune)

    unless { counter(lunar) == 1 or counter(lunar) + counter(solar) == 1 and is_cleave() or buffremaining(eclipse_solar) < executetime(starfire) and buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and not starfire_in_solar() or buffremaining(celestial_alignment) < executetime(starfire) and not is_cleave() and buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 and { enemies() <= 3 or not hastalent(soul_of_the_forest_talent) } or not is_cleave() and buffremaining(celestial_alignment) > executetime(wrath) } and spell(wrath) or spell(starfire)
    {
     #run_action_list,name=fallthru
     balancefallthrushortcdactions()
    }
   }
  }
 }
}

AddFunction balanceaoeshortcdpostconditions
{
 buffrefreshable(starfall) and { enemies() < 3 or not equippedruneforge(timeworn_dreambinder_runeforge) } and { not equippedruneforge(lycaras_fleeting_glimpse_runeforge) or timeincombat() % 45 > buffremaining(starfall) + 2 } and spell(starfall) or equippedruneforge(timeworn_dreambinder_runeforge) and enemies() >= 3 and { not buffpresent(timeworn_dreambinder_buff) and buffrefreshable(starfall) or dream_will_fall_off() and { buffremaining(starfall) < 3 or enemies() > 2 and hastalent(stellar_drift_talent) and buffremaining(starfall) < 5 } } and spell(starfall) or dream_will_fall_off() and starfall_wont_fall_off() and spell(starsurge) or target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and { astralpower() >= astralpowercost(sunfire) and buffpresent(eclipse_any) } and spell(sunfire) or { not buffpresent(adaptive_swarm) and not inflighttotarget(adaptive_swarm_damage) or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + target.debuffremaining(moonfire_debuff) and { { spellcooldown(celestial_alignment) == 0 or enemies() < 3 or { buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and buffpresent(eclipse_lunar) or buffpresent(eclipse_lunar) and not hastalent(soul_of_the_forest_talent) or buffamount(primordial_arcanic_pulsar) >= 250 } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize) and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } and spell(incarnation) or { fightremains() < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(celestial_alignment) > 50 } and spell(kindred_spirits) or target.refreshable(stellar_flare) and target.timetodie() > 15 and { enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(celestial_alignment) > 10 or not buffpresent(celestial_alignment) } } and spell(stellar_flare) or buffpresent(oneths_perception) and { buffrefreshable(starfall) or astralpower() > 90 } and spell(starfall) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and buffrefreshable(starfall) and spell(starfall) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) and spell(starsurge) or { buffpresent(oneths_clear_vision) or { not astralpower() >= astralpowercost(starfire) or { buffremaining(celestial_alignment) < 5 and buffpresent(celestial_alignment) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and { not equippedruneforge(timeworn_dreambinder_runeforge) or enemies() < 3 } } and spell(starsurge) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or { counter(lunar) == 1 or counter(lunar) + counter(solar) == 1 and is_cleave() or buffremaining(eclipse_solar) < executetime(starfire) and buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and not starfire_in_solar() or buffremaining(celestial_alignment) < executetime(starfire) and not is_cleave() and buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 and { enemies() <= 3 or not hastalent(soul_of_the_forest_talent) } or not is_cleave() and buffremaining(celestial_alignment) > executetime(wrath) } and spell(wrath) or spell(starfire) or balancefallthrushortcdpostconditions()
}

AddFunction balanceaoecdactions
{
 unless buffrefreshable(starfall) and { enemies() < 3 or not equippedruneforge(timeworn_dreambinder_runeforge) } and { not equippedruneforge(lycaras_fleeting_glimpse_runeforge) or timeincombat() % 45 > buffremaining(starfall) + 2 } and spell(starfall) or equippedruneforge(timeworn_dreambinder_runeforge) and enemies() >= 3 and { not buffpresent(timeworn_dreambinder_buff) and buffrefreshable(starfall) or dream_will_fall_off() and { buffremaining(starfall) < 3 or enemies() > 2 and hastalent(stellar_drift_talent) and buffremaining(starfall) < 5 } } and spell(starfall) or dream_will_fall_off() and starfall_wont_fall_off() and spell(starsurge) or target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and { astralpower() >= astralpowercost(sunfire) and buffpresent(eclipse_any) } and spell(sunfire) or { not buffpresent(adaptive_swarm) and not inflighttotarget(adaptive_swarm_damage) or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + target.debuffremaining(moonfire_debuff) and { { spellcooldown(celestial_alignment) == 0 or enemies() < 3 or { buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and buffpresent(eclipse_lunar) or buffpresent(eclipse_lunar) and not hastalent(soul_of_the_forest_talent) or buffamount(primordial_arcanic_pulsar) >= 250 } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize) and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature)
 {
  #ravenous_frenzy,if=buff.ca_inc.up
  if buffpresent(celestial_alignment) spell(ravenous_frenzy)
  #celestial_alignment,if=(buff.starfall.up|astral_power>50)&!buff.solstice.up&!buff.ca_inc.up&(interpolated_fight_remains<cooldown.convoke_the_spirits.remains+7|interpolated_fight_remains%%180<22|cooldown.convoke_the_spirits.up|!covenant.night_fae)
  if { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() % 180 < 22 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } spell(celestial_alignment)

  unless { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } and spell(incarnation) or { fightremains() < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(celestial_alignment) > 50 } and spell(kindred_spirits) or target.refreshable(stellar_flare) and target.timetodie() > 15 and { enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(celestial_alignment) > 10 or not buffpresent(celestial_alignment) } } and spell(stellar_flare)
  {
   #variable,name=convoke_condition,value=buff.primordial_arcanic_pulsar.value<250-astral_power&(cooldown.ca_inc.remains+10>interpolated_fight_remains|cooldown.ca_inc.remains+30<interpolated_fight_remains&interpolated_fight_remains>130|buff.ca_inc.remains>7)&eclipse.in_any|interpolated_fight_remains%%120<15
   #convoke_the_spirits,if=variable.convoke_condition&astral_power<50
   if convoke_condition() and astralpower() < 50 spell(convoke_the_spirits)

   unless buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 250 and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) or enemies() > 2 } and spell(fury_of_elune) or buffpresent(oneths_perception) and { buffrefreshable(starfall) or astralpower() > 90 } and spell(starfall) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and buffrefreshable(starfall) and spell(starfall) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) and spell(starsurge) or { buffpresent(oneths_clear_vision) or { not astralpower() >= astralpowercost(starfire) or { buffremaining(celestial_alignment) < 5 and buffpresent(celestial_alignment) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and { not equippedruneforge(timeworn_dreambinder_runeforge) or enemies() < 3 } } and spell(starsurge) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { counter(lunar) == 1 or counter(lunar) + counter(solar) == 1 and is_cleave() or buffremaining(eclipse_solar) < executetime(starfire) and buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and not starfire_in_solar() or buffremaining(celestial_alignment) < executetime(starfire) and not is_cleave() and buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 and { enemies() <= 3 or not hastalent(soul_of_the_forest_talent) } or not is_cleave() and buffremaining(celestial_alignment) > executetime(wrath) } and spell(wrath) or spell(starfire)
   {
    #run_action_list,name=fallthru
    balancefallthrucdactions()
   }
  }
 }
}

AddFunction balanceaoecdpostconditions
{
 buffrefreshable(starfall) and { enemies() < 3 or not equippedruneforge(timeworn_dreambinder_runeforge) } and { not equippedruneforge(lycaras_fleeting_glimpse_runeforge) or timeincombat() % 45 > buffremaining(starfall) + 2 } and spell(starfall) or equippedruneforge(timeworn_dreambinder_runeforge) and enemies() >= 3 and { not buffpresent(timeworn_dreambinder_buff) and buffrefreshable(starfall) or dream_will_fall_off() and { buffremaining(starfall) < 3 or enemies() > 2 and hastalent(stellar_drift_talent) and buffremaining(starfall) < 5 } } and spell(starfall) or dream_will_fall_off() and starfall_wont_fall_off() and spell(starsurge) or target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and { astralpower() >= astralpowercost(sunfire) and buffpresent(eclipse_any) } and spell(sunfire) or { not buffpresent(adaptive_swarm) and not inflighttotarget(adaptive_swarm_damage) or target.debuffstacks(adaptive_swarm_damage) < 3 and target.debuffremaining(adaptive_swarm_damage) < 3 } and spell(adaptive_swarm) or target.refreshable(moonfire_debuff) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + target.debuffremaining(moonfire_debuff) and { { spellcooldown(celestial_alignment) == 0 or enemies() < 3 or { buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and buffpresent(eclipse_lunar) or buffpresent(eclipse_lunar) and not hastalent(soul_of_the_forest_talent) or buffamount(primordial_arcanic_pulsar) >= 250 } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize) and astralpower() >= astralpowercost(moonfire) } and spell(moonfire) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(celestial_alignment) and { fightremains() < spellcooldown(convoke_the_spirits) + 7 or fightremains() % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not iscovenant(night_fae) } and spell(incarnation) or { fightremains() < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(celestial_alignment) > 50 } and spell(kindred_spirits) or target.refreshable(stellar_flare) and target.timetodie() > 15 and { enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(celestial_alignment) > 10 or not buffpresent(celestial_alignment) } } and spell(stellar_flare) or buffpresent(eclipse_any) and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 250 and { target.debuffpresent(adaptive_swarm_damage) or not iscovenant(necrolord) or enemies() > 2 } and spell(fury_of_elune) or buffpresent(oneths_perception) and { buffrefreshable(starfall) or astralpower() > 90 } and spell(starfall) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and buffrefreshable(starfall) and spell(starfall) or iscovenant(night_fae) and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) and spell(starsurge) or { buffpresent(oneths_clear_vision) or { not astralpower() >= astralpowercost(starfire) or { buffremaining(celestial_alignment) < 5 and buffpresent(celestial_alignment) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and { not equippedruneforge(timeworn_dreambinder_runeforge) or enemies() < 3 } } and spell(starsurge) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and { not spellknown(half_moon) and not spellknown(full_moon) } and spell(new_moon) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { buffpresent(eclipse_any) and spellcooldown(celestial_alignment) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { counter(lunar) == 1 or counter(lunar) + counter(solar) == 1 and is_cleave() or buffremaining(eclipse_solar) < executetime(starfire) and buffpresent(eclipse_solar) or buffpresent(eclipse_solar) and not starfire_in_solar() or buffremaining(celestial_alignment) < executetime(starfire) and not is_cleave() and buffremaining(celestial_alignment) < executetime(wrath) and buffpresent(celestial_alignment) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 and { enemies() <= 3 or not hastalent(soul_of_the_forest_talent) } or not is_cleave() and buffremaining(celestial_alignment) > executetime(wrath) } and spell(wrath) or spell(starfire) or balancefallthrucdpostconditions()
}

### actions.default

AddFunction balance_defaultmainactions
{
 #variable,name=is_aoe,value=spell_targets.starfall>1&(!talent.starlord.enabled|talent.stellar_drift.enabled)|spell_targets.starfall>2
 #variable,name=is_cleave,value=spell_targets.starfire>1
 #berserking,if=(!covenant.night_fae|!cooldown.convoke_the_spirits.up)&buff.ca_inc.up
 if { not iscovenant(night_fae) or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(celestial_alignment) spell(berserking)
 #heart_essence,if=level=50
 if level() == 50 spell(296208)
 #run_action_list,name=aoe,if=variable.is_aoe
 if is_aoe() balanceaoemainactions()

 unless is_aoe() and balanceaoemainpostconditions()
 {
  #run_action_list,name=dreambinder,if=runeforge.timeworn_dreambinder.equipped
  if equippedruneforge(timeworn_dreambinder_runeforge) balancedreambindermainactions()

  unless equippedruneforge(timeworn_dreambinder_runeforge) and balancedreambindermainpostconditions()
  {
   #run_action_list,name=boat,if=runeforge.balance_of_all_things.equipped
   if equippedruneforge(balance_of_all_things_runeforge) balanceboatmainactions()

   unless equippedruneforge(balance_of_all_things_runeforge) and balanceboatmainpostconditions()
   {
    #run_action_list,name=st,if=level>50
    if level() > 50 balancestmainactions()

    unless level() > 50 and balancestmainpostconditions()
    {
     #variable,name=prev_wrath,value=prev.wrath
     #variable,name=prev_starfire,value=prev.starfire
     #variable,name=prev_starsurge,value=prev.starsurge
     #run_action_list,name=prepatch_st
     balanceprepatch_stmainactions()
    }
   }
  }
 }
}

AddFunction balance_defaultmainpostconditions
{
 is_aoe() and balanceaoemainpostconditions() or equippedruneforge(timeworn_dreambinder_runeforge) and balancedreambindermainpostconditions() or equippedruneforge(balance_of_all_things_runeforge) and balanceboatmainpostconditions() or level() > 50 and balancestmainpostconditions() or balanceprepatch_stmainpostconditions()
}

AddFunction balance_defaultshortcdactions
{
 unless { not iscovenant(night_fae) or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(celestial_alignment) and spell(berserking) or level() == 50 and spell(296208)
 {
  #run_action_list,name=aoe,if=variable.is_aoe
  if is_aoe() balanceaoeshortcdactions()

  unless is_aoe() and balanceaoeshortcdpostconditions()
  {
   #run_action_list,name=dreambinder,if=runeforge.timeworn_dreambinder.equipped
   if equippedruneforge(timeworn_dreambinder_runeforge) balancedreambindershortcdactions()

   unless equippedruneforge(timeworn_dreambinder_runeforge) and balancedreambindershortcdpostconditions()
   {
    #run_action_list,name=boat,if=runeforge.balance_of_all_things.equipped
    if equippedruneforge(balance_of_all_things_runeforge) balanceboatshortcdactions()

    unless equippedruneforge(balance_of_all_things_runeforge) and balanceboatshortcdpostconditions()
    {
     #run_action_list,name=st,if=level>50
     if level() > 50 balancestshortcdactions()

     unless level() > 50 and balancestshortcdpostconditions()
     {
      #variable,name=prev_wrath,value=prev.wrath
      #variable,name=prev_starfire,value=prev.starfire
      #variable,name=prev_starsurge,value=prev.starsurge
      #run_action_list,name=prepatch_st
      balanceprepatch_stshortcdactions()
     }
    }
   }
  }
 }
}

AddFunction balance_defaultshortcdpostconditions
{
 { not iscovenant(night_fae) or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(celestial_alignment) and spell(berserking) or level() == 50 and spell(296208) or is_aoe() and balanceaoeshortcdpostconditions() or equippedruneforge(timeworn_dreambinder_runeforge) and balancedreambindershortcdpostconditions() or equippedruneforge(balance_of_all_things_runeforge) and balanceboatshortcdpostconditions() or level() > 50 and balancestshortcdpostconditions() or balanceprepatch_stshortcdpostconditions()
}

AddFunction balance_defaultcdactions
{
 balanceinterruptactions()

 unless { not iscovenant(night_fae) or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(celestial_alignment) and spell(berserking)
 {
  #potion,if=buff.ca_inc.up
  if buffpresent(celestial_alignment) and { checkboxon(opt_use_consumables) and target.classification(worldboss) } item(superior_battle_potion_of_intellect_item usable=1)
  #use_items
  balanceuseitemactions()

  unless level() == 50 and spell(296208)
  {
   #run_action_list,name=aoe,if=variable.is_aoe
   if is_aoe() balanceaoecdactions()

   unless is_aoe() and balanceaoecdpostconditions()
   {
    #run_action_list,name=dreambinder,if=runeforge.timeworn_dreambinder.equipped
    if equippedruneforge(timeworn_dreambinder_runeforge) balancedreambindercdactions()

    unless equippedruneforge(timeworn_dreambinder_runeforge) and balancedreambindercdpostconditions()
    {
     #run_action_list,name=boat,if=runeforge.balance_of_all_things.equipped
     if equippedruneforge(balance_of_all_things_runeforge) balanceboatcdactions()

     unless equippedruneforge(balance_of_all_things_runeforge) and balanceboatcdpostconditions()
     {
      #run_action_list,name=st,if=level>50
      if level() > 50 balancestcdactions()

      unless level() > 50 and balancestcdpostconditions()
      {
       #variable,name=prev_wrath,value=prev.wrath
       #variable,name=prev_starfire,value=prev.starfire
       #variable,name=prev_starsurge,value=prev.starsurge
       #run_action_list,name=prepatch_st
       balanceprepatch_stcdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction balance_defaultcdpostconditions
{
 { not iscovenant(night_fae) or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(celestial_alignment) and spell(berserking) or level() == 50 and spell(296208) or is_aoe() and balanceaoecdpostconditions() or equippedruneforge(timeworn_dreambinder_runeforge) and balancedreambindercdpostconditions() or equippedruneforge(balance_of_all_things_runeforge) and balanceboatcdpostconditions() or level() > 50 and balancestcdpostconditions() or balanceprepatch_stcdpostconditions()
}

### Balance icons.

AddCheckBox(opt_druid_balance_aoe l(aoe) default enabled=(specialization(balance)))

AddIcon enabled=(not checkboxon(opt_druid_balance_aoe) and specialization(balance)) enemies=1 help=shortcd
{
 if not incombat() balanceprecombatshortcdactions()
 balance_defaultshortcdactions()
}

AddIcon enabled=(checkboxon(opt_druid_balance_aoe) and specialization(balance)) help=shortcd
{
 if not incombat() balanceprecombatshortcdactions()
 balance_defaultshortcdactions()
}

AddIcon enabled=(specialization(balance)) enemies=1 help=main
{
 if not incombat() balanceprecombatmainactions()
 balance_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_druid_balance_aoe) and specialization(balance)) help=aoe
{
 if not incombat() balanceprecombatmainactions()
 balance_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_druid_balance_aoe) and not specialization(balance)) enemies=1 help=cd
{
 if not incombat() balanceprecombatcdactions()
 balance_defaultcdactions()
}

AddIcon enabled=(checkboxon(opt_druid_balance_aoe) and specialization(balance)) help=cd
{
 if not incombat() balanceprecombatcdactions()
 balance_defaultcdactions()
}

### Required symbols
# adaptive_swarm
# adaptive_swarm_damage
# balance_of_all_things_arcane_buff
# balance_of_all_things_nature_buff
# balance_of_all_things_runeforge
# berserking
# bloodlust
# celestial_alignment
# convoke_the_spirits
# dawning_sun_buff
# dawning_sun_trait
# eclipse_any
# eclipse_lunar
# eclipse_solar
# empower_bond
# force_of_nature
# full_moon
# fury_of_elune
# half_moon
# incarnation
# incarnation_chosen_of_elune_talent
# kindred_empowerment_energize
# kindred_spirits
# kyrian
# lycaras_fleeting_glimpse_runeforge
# mighty_bash
# moonfire
# moonfire_debuff
# moonkin_form
# necrolord
# new_moon
# night_fae
# oneths_clear_vision
# oneths_perception
# precise_alignment_conduit
# primordial_arcanic_pulsar
# primordial_arcanic_pulsar_runeforge
# ravenous_frenzy
# solar_beam
# solstice_buff
# soul_of_the_forest_talent
# starfall
# starfire
# starlord
# starlord_buff
# starlord_talent
# starsurge
# starsurge_empowerment_buff
# stellar_drift_talent
# stellar_flare
# streaking_stars_trait
# sunfire
# superior_battle_potion_of_intellect_item
# timeworn_dreambinder_buff
# timeworn_dreambinder_runeforge
# twin_moons_talent
# typhoon
# venthyr
# war_stomp
# warrior_of_elune
# wrath
]]
        OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
    end
    do
        local name = "sc_t25_druid_feral"
        local desc = "[9.0] Simulationcraft: T25_Druid_Feral"
        local code = [[
# Based on SimulationCraft profile "T25_Druid_Feral".
#	class=druid
#	spec=feral
#	talents=2331122

Include(ovale_common)
Include(ovale_druid_spells)


AddFunction reaping_delay
{
 if 0 == 0 target.timetodie()
}

AddFunction best_rip
{
 if hastalent(primal_wrath_talent) 0
}

AddFunction thrash_ticks
{
 if hasazeritetrait(wild_fleshrending_trait) 0
 8
}

AddFunction rip_ticks
{
 7
}

AddFunction filler
{
 if hasazeritetrait(wild_fleshrending_trait) 0
 1
}

AddFunction _4cp_bite
{
 0
}

AddCheckBox(opt_interrupt l(interrupt) default enabled=(specialization(feral)))
AddCheckBox(opt_melee_range l(not_in_melee_range) enabled=(specialization(feral)))
AddCheckBox(opt_use_consumables l(opt_use_consumables) default enabled=(specialization(feral)))

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
  texture(misc_arrowlup help=(l(not_in_melee_range)))
 }
}

### actions.stealth

AddFunction feralstealthmainactions
{
 #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&buff.bloodtalons.down
 if hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) feralbloodtalonsmainactions()

 unless hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and feralbloodtalonsmainpostconditions()
 {
  #rake,target_if=dot.rake.pmultiplier<1.6&druid.rake.ticks_gained_on_refresh>2
  if target.debuffpersistentmultiplier(rake_debuff) < 1.6 and ticksgainedonrefresh(rake) > 2 spell(rake)
  #shred
  spell(shred)
 }
}

AddFunction feralstealthmainpostconditions
{
 hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and feralbloodtalonsmainpostconditions()
}

AddFunction feralstealthshortcdactions
{
 #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&buff.bloodtalons.down
 if hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) feralbloodtalonsshortcdactions()
}

AddFunction feralstealthshortcdpostconditions
{
 hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and feralbloodtalonsshortcdpostconditions() or target.debuffpersistentmultiplier(rake_debuff) < 1.6 and ticksgainedonrefresh(rake) > 2 and spell(rake) or spell(shred)
}

AddFunction feralstealthcdactions
{
 #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&buff.bloodtalons.down
 if hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) feralbloodtalonscdactions()
}

AddFunction feralstealthcdpostconditions
{
 hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and feralbloodtalonscdpostconditions() or target.debuffpersistentmultiplier(rake_debuff) < 1.6 and ticksgainedonrefresh(rake) > 2 and spell(rake) or spell(shred)
}

### actions.precombat

AddFunction feralprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #flask
 #food
 #augmentation
 #variable,name=4cp_bite,value=0
 #variable,name=filler,value=1
 #variable,name=filler,value=0,if=azerite.wild_fleshrending.enabled
 #variable,name=rip_ticks,value=7
 #variable,name=thrash_ticks,value=8
 #variable,name=thrash_ticks,value=0,if=azerite.wild_fleshrending.enabled
 #snapshot_stats
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
 spell(cat_form) or spell(prowl)
}

AddFunction feralprecombatcdactions
{
}

AddFunction feralprecombatcdpostconditions
{
 spell(cat_form) or spell(prowl)
}

### actions.finisher

AddFunction feralfinishermainactions
{
 #savage_roar,if=buff.savage_roar.down|buff.savage_roar.remains<(combo_points*5+1)*0.3
 if buffexpires(savage_roar) or buffremaining(savage_roar) < { combopoints() * 5 + 1 } * 0.3 spell(savage_roar)
 #variable,name=best_rip,value=0,if=talent.primal_wrath.enabled
 #cycling_variable,name=best_rip,op=max,value=druid.rip.ticks_gained_on_refresh,if=talent.primal_wrath.enabled
 #primal_wrath,if=druid.primal_wrath.ticks_gained_on_refresh>(variable.rip_ticks>?variable.best_rip)|spell_targets.primal_wrath>(3+1*talent.sabertooth.enabled)
 if ticksgainedonrefresh(primal_wrath) > rip_ticks() >? best_rip() or enemies() > 3 + 1 * talentpoints(sabertooth_talent) spell(primal_wrath)
 #rip,target_if=(!ticking|(remains+combo_points*talent.sabertooth.enabled)<duration*0.3|dot.rip.pmultiplier<persistent_multiplier)&druid.rip.ticks_gained_on_refresh>variable.rip_ticks
 if { not buffpresent(rip) or buffremaining(rip) + combopoints() * talentpoints(sabertooth_talent) < baseduration(rip) * 0.3 or target.debuffpersistentmultiplier(rip) < persistentmultiplier(rip) } and ticksgainedonrefresh(rip) > rip_ticks() spell(rip)
 #maim,if=buff.iron_jaws.up
 if buffpresent(iron_jaws) spell(maim)
 #ferocious_bite,max_energy=1,target_if=max:time_to_die
 if energy() >= energycost(ferocious_bite max=1) spell(ferocious_bite)
}

AddFunction feralfinishermainpostconditions
{
}

AddFunction feralfinishershortcdactions
{
}

AddFunction feralfinishershortcdpostconditions
{
 { buffexpires(savage_roar) or buffremaining(savage_roar) < { combopoints() * 5 + 1 } * 0.3 } and spell(savage_roar) or { ticksgainedonrefresh(primal_wrath) > rip_ticks() >? best_rip() or enemies() > 3 + 1 * talentpoints(sabertooth_talent) } and spell(primal_wrath) or { not buffpresent(rip) or buffremaining(rip) + combopoints() * talentpoints(sabertooth_talent) < baseduration(rip) * 0.3 or target.debuffpersistentmultiplier(rip) < persistentmultiplier(rip) } and ticksgainedonrefresh(rip) > rip_ticks() and spell(rip) or buffpresent(iron_jaws) and spell(maim) or energy() >= energycost(ferocious_bite max=1) and spell(ferocious_bite)
}

AddFunction feralfinishercdactions
{
}

AddFunction feralfinishercdpostconditions
{
 { buffexpires(savage_roar) or buffremaining(savage_roar) < { combopoints() * 5 + 1 } * 0.3 } and spell(savage_roar) or { ticksgainedonrefresh(primal_wrath) > rip_ticks() >? best_rip() or enemies() > 3 + 1 * talentpoints(sabertooth_talent) } and spell(primal_wrath) or { not buffpresent(rip) or buffremaining(rip) + combopoints() * talentpoints(sabertooth_talent) < baseduration(rip) * 0.3 or target.debuffpersistentmultiplier(rip) < persistentmultiplier(rip) } and ticksgainedonrefresh(rip) > rip_ticks() and spell(rip) or buffpresent(iron_jaws) and spell(maim) or energy() >= energycost(ferocious_bite max=1) and spell(ferocious_bite)
}

### actions.filler

AddFunction feralfillermainactions
{
 #rake,target_if=variable.filler=1&dot.rake.pmultiplier<=persistent_multiplier
 if filler() == 1 and target.debuffpersistentmultiplier(rake_debuff) <= persistentmultiplier(rake_debuff) spell(rake)
 #rake,if=variable.filler=2
 if filler() == 2 spell(rake)
 #lunar_inspiration,if=variable.filler=3
 if filler() == 3 spell(lunar_inspiration)
 #swipe,if=variable.filler=4
 if filler() == 4 spell(swipe)
 #shred
 spell(shred)
}

AddFunction feralfillermainpostconditions
{
}

AddFunction feralfillershortcdactions
{
}

AddFunction feralfillershortcdpostconditions
{
 filler() == 1 and target.debuffpersistentmultiplier(rake_debuff) <= persistentmultiplier(rake_debuff) and spell(rake) or filler() == 2 and spell(rake) or filler() == 3 and spell(lunar_inspiration) or filler() == 4 and spell(swipe) or spell(shred)
}

AddFunction feralfillercdactions
{
}

AddFunction feralfillercdpostconditions
{
 filler() == 1 and target.debuffpersistentmultiplier(rake_debuff) <= persistentmultiplier(rake_debuff) and spell(rake) or filler() == 2 and spell(rake) or filler() == 3 and spell(lunar_inspiration) or filler() == 4 and spell(swipe) or spell(shred)
}

### actions.essence

AddFunction feralessencemainactions
{
 #thorns,if=active_enemies>desired_targets|raid_event.adds.in>45
 if enemies() > enemies(tagged=1) or 600 > 45 spell(thorns)
 #the_unbound_force,if=buff.reckless_force.up|buff.tigers_fury.up
 if buffpresent(reckless_force_buff) or buffpresent(tigers_fury) spell(the_unbound_force)
 #memory_of_lucid_dreams,if=buff.berserk_cat.up|buff.incarnation_king_of_the_jungle.up
 if buffpresent(berserk_cat) or buffpresent(incarnation_king_of_the_jungle) spell(memory_of_lucid_dreams)
 #blood_of_the_enemy,if=buff.tigers_fury.up&combo_points=5
 if buffpresent(tigers_fury) and combopoints() == 5 spell(blood_of_the_enemy)
 #concentrated_flame,if=buff.tigers_fury.up
 if buffpresent(tigers_fury) spell(concentrated_flame)
 #ripple_in_space,if=buff.tigers_fury.up
 if buffpresent(tigers_fury) spell(ripple_in_space)
 #worldvein_resonance,if=buff.tigers_fury.up
 if buffpresent(tigers_fury) spell(worldvein_resonance)
}

AddFunction feralessencemainpostconditions
{
}

AddFunction feralessenceshortcdactions
{
 unless { enemies() > enemies(tagged=1) or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury) } and spell(the_unbound_force) or { buffpresent(berserk_cat) or buffpresent(incarnation_king_of_the_jungle) } and spell(memory_of_lucid_dreams) or buffpresent(tigers_fury) and combopoints() == 5 and spell(blood_of_the_enemy)
 {
  #focused_azerite_beam,if=active_enemies>desired_targets|(raid_event.adds.in>90&energy.deficit>=50)
  if enemies() > enemies(tagged=1) or 600 > 90 and energydeficit() >= 50 spell(focused_azerite_beam)
  #purifying_blast,if=active_enemies>desired_targets|raid_event.adds.in>60
  if enemies() > enemies(tagged=1) or 600 > 60 spell(purifying_blast)

  unless buffpresent(tigers_fury) and spell(concentrated_flame) or buffpresent(tigers_fury) and spell(ripple_in_space) or buffpresent(tigers_fury) and spell(worldvein_resonance)
  {
   #reaping_flames,target_if=target.time_to_die<1.5|((target.health.pct>80|target.health.pct<=20)&variable.reaping_delay>29)|(target.time_to_pct_20>30&variable.reaping_delay>44)
   if target.timetodie() < 1.5 or { target.healthpercent() > 80 or target.healthpercent() <= 20 } and reaping_delay() > 29 or target.timetohealthpercent(20) > 30 and reaping_delay() > 44 spell(reaping_flames)
  }
 }
}

AddFunction feralessenceshortcdpostconditions
{
 { enemies() > enemies(tagged=1) or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury) } and spell(the_unbound_force) or { buffpresent(berserk_cat) or buffpresent(incarnation_king_of_the_jungle) } and spell(memory_of_lucid_dreams) or buffpresent(tigers_fury) and combopoints() == 5 and spell(blood_of_the_enemy) or buffpresent(tigers_fury) and spell(concentrated_flame) or buffpresent(tigers_fury) and spell(ripple_in_space) or buffpresent(tigers_fury) and spell(worldvein_resonance)
}

AddFunction feralessencecdactions
{
 unless { enemies() > enemies(tagged=1) or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury) } and spell(the_unbound_force) or { buffpresent(berserk_cat) or buffpresent(incarnation_king_of_the_jungle) } and spell(memory_of_lucid_dreams) or buffpresent(tigers_fury) and combopoints() == 5 and spell(blood_of_the_enemy) or { enemies() > enemies(tagged=1) or 600 > 90 and energydeficit() >= 50 } and spell(focused_azerite_beam) or { enemies() > enemies(tagged=1) or 600 > 60 } and spell(purifying_blast)
 {
  #guardian_of_azeroth,if=buff.tigers_fury.up
  if buffpresent(tigers_fury) spell(guardian_of_azeroth)
 }
}

AddFunction feralessencecdpostconditions
{
 { enemies() > enemies(tagged=1) or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury) } and spell(the_unbound_force) or { buffpresent(berserk_cat) or buffpresent(incarnation_king_of_the_jungle) } and spell(memory_of_lucid_dreams) or buffpresent(tigers_fury) and combopoints() == 5 and spell(blood_of_the_enemy) or { enemies() > enemies(tagged=1) or 600 > 90 and energydeficit() >= 50 } and spell(focused_azerite_beam) or { enemies() > enemies(tagged=1) or 600 > 60 } and spell(purifying_blast) or buffpresent(tigers_fury) and spell(concentrated_flame) or buffpresent(tigers_fury) and spell(ripple_in_space) or buffpresent(tigers_fury) and spell(worldvein_resonance) or { target.timetodie() < 1.5 or { target.healthpercent() > 80 or target.healthpercent() <= 20 } and reaping_delay() > 29 or target.timetohealthpercent(20) > 30 and reaping_delay() > 44 } and spell(reaping_flames)
}

### actions.cooldown

AddFunction feralcooldownmainactions
{
 #berserk
 spell(berserk)
 #incarnation
 spell(incarnation)
 #berserking,if=buff.tigers_fury.up|buff.bs_inc.up
 if buffpresent(tigers_fury) or buffpresent(bs_inc_buff) spell(berserking)
 #call_action_list,name=essence
 feralessencemainactions()
}

AddFunction feralcooldownmainpostconditions
{
 feralessencemainpostconditions()
}

AddFunction feralcooldownshortcdactions
{
 unless spell(berserk) or spell(incarnation)
 {
  #tigers_fury,if=energy.deficit>55|(buff.bs_inc.up&buff.bs_inc.remains<13)
  if energydeficit() > 55 or buffpresent(bs_inc_buff) and buffremaining(bs_inc_buff) < 13 spell(tigers_fury)

  unless { buffpresent(tigers_fury) or buffpresent(bs_inc_buff) } and spell(berserking)
  {
   #call_action_list,name=essence
   feralessenceshortcdactions()
  }
 }
}

AddFunction feralcooldownshortcdpostconditions
{
 spell(berserk) or spell(incarnation) or { buffpresent(tigers_fury) or buffpresent(bs_inc_buff) } and spell(berserking) or feralessenceshortcdpostconditions()
}

AddFunction feralcooldowncdactions
{
 unless spell(berserk) or spell(incarnation) or { energydeficit() > 55 or buffpresent(bs_inc_buff) and buffremaining(bs_inc_buff) < 13 } and spell(tigers_fury)
 {
  #shadowmeld,if=buff.tigers_fury.up&buff.bs_inc.down&combo_points<4&dot.rake.pmultiplier<1.6&energy>40
  if buffpresent(tigers_fury) and buffexpires(bs_inc_buff) and combopoints() < 4 and target.debuffpersistentmultiplier(rake_debuff) < 1.6 and energy() > 40 spell(shadowmeld)

  unless { buffpresent(tigers_fury) or buffpresent(bs_inc_buff) } and spell(berserking)
  {
   #potion,if=buff.bs_inc.up
   if buffpresent(bs_inc_buff) and { checkboxon(opt_use_consumables) and target.classification(worldboss) } item(superior_battle_potion_of_agility_item usable=1)
   #call_action_list,name=essence
   feralessencecdactions()

   unless feralessencecdpostconditions()
   {
    #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.time_to_pct_30<1.5|!debuff.conductive_ink_debuff.up&(debuff.razor_coral_debuff.stack>=25-10*debuff.blood_of_the_enemy.up|target.time_to_die<40)&buff.tigers_fury.remains>10
    if target.debuffexpires(razor_coral_debuff) or target.debuffpresent(conductive_ink) and target.timetohealthpercent(30) < 1.5 or not target.debuffpresent(conductive_ink) and { target.debuffstacks(razor_coral_debuff) >= 25 - 10 * target.debuffpresent(blood_of_the_enemy_debuff) or target.timetodie() < 40 } and buffremaining(tigers_fury) > 10 feraluseitemactions()
    #use_items,if=buff.tigers_fury.up|target.time_to_die<20
    if buffpresent(tigers_fury) or target.timetodie() < 20 feraluseitemactions()
   }
  }
 }
}

AddFunction feralcooldowncdpostconditions
{
 spell(berserk) or spell(incarnation) or { energydeficit() > 55 or buffpresent(bs_inc_buff) and buffremaining(bs_inc_buff) < 13 } and spell(tigers_fury) or { buffpresent(tigers_fury) or buffpresent(bs_inc_buff) } and spell(berserking) or feralessencecdpostconditions()
}

### actions.bloodtalons

AddFunction feralbloodtalonsmainactions
{
 #rake,target_if=(!ticking|(refreshable&persistent_multiplier>dot.rake.pmultiplier))&buff.bt_rake.down&druid.rake.ticks_gained_on_refresh>=2
 if { not target.debuffpresent(rake_debuff) or target.refreshable(rake_debuff) and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and buffexpires(bt_rake_buff) and ticksgainedonrefresh(rake) >= 2 spell(rake)
 #lunar_inspiration,target_if=refreshable&buff.bt_moonfire.down
 if target.refreshable(lunar_inspiration) and buffexpires(bt_moonfire_buff) spell(lunar_inspiration)
 #thrash_cat,target_if=refreshable&buff.bt_thrash.down&druid.thrash_cat.ticks_gained_on_refresh>8
 if target.refreshable(thrash_cat) and buffexpires(bt_thrash_buff) and ticksgainedonrefresh(thrash_cat) > 8 spell(thrash_cat)
 #brutal_slash,if=buff.bt_brutal_slash.down
 if buffexpires(bt_brutal_slash_buff) spell(brutal_slash)
 #swipe_cat,if=buff.bt_swipe.down&spell_targets.swipe_cat>1
 if buffexpires(bt_swipe_buff) and enemies() > 1 spell(swipe_cat)
 #shred,if=buff.bt_shred.down
 if buffexpires(bt_shred_buff) spell(shred)
 #swipe_cat,if=buff.bt_swipe.down
 if buffexpires(bt_swipe_buff) spell(swipe_cat)
 #thrash_cat,if=buff.bt_thrash.down
 if buffexpires(bt_thrash_buff) spell(thrash_cat)
}

AddFunction feralbloodtalonsmainpostconditions
{
}

AddFunction feralbloodtalonsshortcdactions
{
}

AddFunction feralbloodtalonsshortcdpostconditions
{
 { not target.debuffpresent(rake_debuff) or target.refreshable(rake_debuff) and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and buffexpires(bt_rake_buff) and ticksgainedonrefresh(rake) >= 2 and spell(rake) or target.refreshable(lunar_inspiration) and buffexpires(bt_moonfire_buff) and spell(lunar_inspiration) or target.refreshable(thrash_cat) and buffexpires(bt_thrash_buff) and ticksgainedonrefresh(thrash_cat) > 8 and spell(thrash_cat) or buffexpires(bt_brutal_slash_buff) and spell(brutal_slash) or buffexpires(bt_swipe_buff) and enemies() > 1 and spell(swipe_cat) or buffexpires(bt_shred_buff) and spell(shred) or buffexpires(bt_swipe_buff) and spell(swipe_cat) or buffexpires(bt_thrash_buff) and spell(thrash_cat)
}

AddFunction feralbloodtalonscdactions
{
}

AddFunction feralbloodtalonscdpostconditions
{
 { not target.debuffpresent(rake_debuff) or target.refreshable(rake_debuff) and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and buffexpires(bt_rake_buff) and ticksgainedonrefresh(rake) >= 2 and spell(rake) or target.refreshable(lunar_inspiration) and buffexpires(bt_moonfire_buff) and spell(lunar_inspiration) or target.refreshable(thrash_cat) and buffexpires(bt_thrash_buff) and ticksgainedonrefresh(thrash_cat) > 8 and spell(thrash_cat) or buffexpires(bt_brutal_slash_buff) and spell(brutal_slash) or buffexpires(bt_swipe_buff) and enemies() > 1 and spell(swipe_cat) or buffexpires(bt_shred_buff) and spell(shred) or buffexpires(bt_swipe_buff) and spell(swipe_cat) or buffexpires(bt_thrash_buff) and spell(thrash_cat)
}

### actions.default

AddFunction feral_defaultmainactions
{
 #cat_form,if=buff.cat_form.down
 if buffexpires(cat_form) spell(cat_form)
 #prowl
 spell(prowl)
 #variable,name=reaping_delay,value=target.time_to_die,if=variable.reaping_delay=0
 #cycling_variable,name=reaping_delay,op=min,value=target.time_to_die
 #run_action_list,name=stealth,if=buff.shadowmeld.up|buff.prowl.up
 if buffpresent(shadowmeld) or buffpresent(prowl) feralstealthmainactions()

 unless { buffpresent(shadowmeld) or buffpresent(prowl) } and feralstealthmainpostconditions()
 {
  #call_action_list,name=cooldown
  feralcooldownmainactions()

  unless feralcooldownmainpostconditions()
  {
   #run_action_list,name=finisher,if=combo_points>=(5-variable.4cp_bite)
   if combopoints() >= 5 - _4cp_bite() feralfinishermainactions()

   unless combopoints() >= 5 - _4cp_bite() and feralfinishermainpostconditions()
   {
    #run_action_list,name=stealth,if=buff.bs_inc.up|buff.sudden_ambush.up
    if buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) feralstealthmainactions()

    unless { buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) } and feralstealthmainpostconditions()
    {
     #pool_resource,if=talent.bloodtalons.enabled&buff.bloodtalons.down&(energy+3.5*energy.regen+(40*buff.clearcasting.up))>=(115-23*buff.incarnation_king_of_the_jungle.up)&active_bt_triggers=0
     unless hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and energy() + 3.5 * energyregenrate() + 40 * buffpresent(clearcasting_buff) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and buffcount(bt_buffs) == 0
     {
      #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&(buff.bloodtalons.down|active_bt_triggers=2)
      if hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } feralbloodtalonsmainactions()

      unless hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } and feralbloodtalonsmainpostconditions()
      {
       #rake,target_if=refreshable|persistent_multiplier>dot.rake.pmultiplier
       if target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) spell(rake)
       #moonfire_cat,target_if=refreshable
       if target.refreshable(moonfire_cat) spell(moonfire_cat)
       #thrash_cat,if=refreshable&druid.thrash_cat.ticks_gained_on_refresh>variable.thrash_ticks
       if target.refreshable(thrash_cat) and ticksgainedonrefresh(thrash_cat) > thrash_ticks() spell(thrash_cat)
       #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))&(spell_targets.brutal_slash*action.brutal_slash.damage%action.brutal_slash.cost)>(action.shred.damage%action.shred.cost)
       if buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) spell(brutal_slash)
       #swipe_cat,if=spell_targets.swipe_cat>2
       if enemies() > 2 spell(swipe_cat)
       #shred,if=buff.clearcasting.up
       if buffpresent(clearcasting_buff) spell(shred)
       #call_action_list,name=filler
       feralfillermainactions()
      }
     }
    }
   }
  }
 }
}

AddFunction feral_defaultmainpostconditions
{
 { buffpresent(shadowmeld) or buffpresent(prowl) } and feralstealthmainpostconditions() or feralcooldownmainpostconditions() or combopoints() >= 5 - _4cp_bite() and feralfinishermainpostconditions() or { buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) } and feralstealthmainpostconditions() or not { hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and energy() + 3.5 * energyregenrate() + 40 * buffpresent(clearcasting_buff) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and buffcount(bt_buffs) == 0 } and { hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } and feralbloodtalonsmainpostconditions() or feralfillermainpostconditions() }
}

AddFunction feral_defaultshortcdactions
{
 unless buffexpires(cat_form) and spell(cat_form) or spell(prowl)
 {
  #auto_attack,if=!buff.prowl.up&!buff.shadowmeld.up
  if not buffpresent(prowl) and not buffpresent(shadowmeld) feralgetinmeleerange()
  #variable,name=reaping_delay,value=target.time_to_die,if=variable.reaping_delay=0
  #cycling_variable,name=reaping_delay,op=min,value=target.time_to_die
  #run_action_list,name=stealth,if=buff.shadowmeld.up|buff.prowl.up
  if buffpresent(shadowmeld) or buffpresent(prowl) feralstealthshortcdactions()

  unless { buffpresent(shadowmeld) or buffpresent(prowl) } and feralstealthshortcdpostconditions()
  {
   #call_action_list,name=cooldown
   feralcooldownshortcdactions()

   unless feralcooldownshortcdpostconditions()
   {
    #run_action_list,name=finisher,if=combo_points>=(5-variable.4cp_bite)
    if combopoints() >= 5 - _4cp_bite() feralfinishershortcdactions()

    unless combopoints() >= 5 - _4cp_bite() and feralfinishershortcdpostconditions()
    {
     #run_action_list,name=stealth,if=buff.bs_inc.up|buff.sudden_ambush.up
     if buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) feralstealthshortcdactions()

     unless { buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) } and feralstealthshortcdpostconditions()
     {
      #pool_resource,if=talent.bloodtalons.enabled&buff.bloodtalons.down&(energy+3.5*energy.regen+(40*buff.clearcasting.up))>=(115-23*buff.incarnation_king_of_the_jungle.up)&active_bt_triggers=0
      unless hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and energy() + 3.5 * energyregenrate() + 40 * buffpresent(clearcasting_buff) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and buffcount(bt_buffs) == 0
      {
       #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&(buff.bloodtalons.down|active_bt_triggers=2)
       if hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } feralbloodtalonsshortcdactions()

       unless hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } and feralbloodtalonsshortcdpostconditions() or { target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and spell(rake)
       {
        #feral_frenzy,if=combo_points=0
        if combopoints() == 0 spell(feral_frenzy)

        unless target.refreshable(moonfire_cat) and spell(moonfire_cat) or target.refreshable(thrash_cat) and ticksgainedonrefresh(thrash_cat) > thrash_ticks() and spell(thrash_cat) or buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) and spell(brutal_slash) or enemies() > 2 and spell(swipe_cat) or buffpresent(clearcasting_buff) and spell(shred)
        {
         #call_action_list,name=filler
         feralfillershortcdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction feral_defaultshortcdpostconditions
{
 buffexpires(cat_form) and spell(cat_form) or spell(prowl) or { buffpresent(shadowmeld) or buffpresent(prowl) } and feralstealthshortcdpostconditions() or feralcooldownshortcdpostconditions() or combopoints() >= 5 - _4cp_bite() and feralfinishershortcdpostconditions() or { buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) } and feralstealthshortcdpostconditions() or not { hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and energy() + 3.5 * energyregenrate() + 40 * buffpresent(clearcasting_buff) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and buffcount(bt_buffs) == 0 } and { hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } and feralbloodtalonsshortcdpostconditions() or { target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and spell(rake) or target.refreshable(moonfire_cat) and spell(moonfire_cat) or target.refreshable(thrash_cat) and ticksgainedonrefresh(thrash_cat) > thrash_ticks() and spell(thrash_cat) or buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) and spell(brutal_slash) or enemies() > 2 and spell(swipe_cat) or buffpresent(clearcasting_buff) and spell(shred) or feralfillershortcdpostconditions() }
}

AddFunction feral_defaultcdactions
{
 feralinterruptactions()

 unless buffexpires(cat_form) and spell(cat_form) or spell(prowl)
 {
  #variable,name=reaping_delay,value=target.time_to_die,if=variable.reaping_delay=0
  #cycling_variable,name=reaping_delay,op=min,value=target.time_to_die
  #run_action_list,name=stealth,if=buff.shadowmeld.up|buff.prowl.up
  if buffpresent(shadowmeld) or buffpresent(prowl) feralstealthcdactions()

  unless { buffpresent(shadowmeld) or buffpresent(prowl) } and feralstealthcdpostconditions()
  {
   #call_action_list,name=cooldown
   feralcooldowncdactions()

   unless feralcooldowncdpostconditions()
   {
    #run_action_list,name=finisher,if=combo_points>=(5-variable.4cp_bite)
    if combopoints() >= 5 - _4cp_bite() feralfinishercdactions()

    unless combopoints() >= 5 - _4cp_bite() and feralfinishercdpostconditions()
    {
     #run_action_list,name=stealth,if=buff.bs_inc.up|buff.sudden_ambush.up
     if buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) feralstealthcdactions()

     unless { buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) } and feralstealthcdpostconditions()
     {
      #pool_resource,if=talent.bloodtalons.enabled&buff.bloodtalons.down&(energy+3.5*energy.regen+(40*buff.clearcasting.up))>=(115-23*buff.incarnation_king_of_the_jungle.up)&active_bt_triggers=0
      unless hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and energy() + 3.5 * energyregenrate() + 40 * buffpresent(clearcasting_buff) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and buffcount(bt_buffs) == 0
      {
       #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&(buff.bloodtalons.down|active_bt_triggers=2)
       if hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } feralbloodtalonscdactions()

       unless hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } and feralbloodtalonscdpostconditions() or { target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and spell(rake) or combopoints() == 0 and spell(feral_frenzy) or target.refreshable(moonfire_cat) and spell(moonfire_cat) or target.refreshable(thrash_cat) and ticksgainedonrefresh(thrash_cat) > thrash_ticks() and spell(thrash_cat) or buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) and spell(brutal_slash) or enemies() > 2 and spell(swipe_cat) or buffpresent(clearcasting_buff) and spell(shred)
       {
        #call_action_list,name=filler
        feralfillercdactions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction feral_defaultcdpostconditions
{
 buffexpires(cat_form) and spell(cat_form) or spell(prowl) or { buffpresent(shadowmeld) or buffpresent(prowl) } and feralstealthcdpostconditions() or feralcooldowncdpostconditions() or combopoints() >= 5 - _4cp_bite() and feralfinishercdpostconditions() or { buffpresent(bs_inc_buff) or buffpresent(sudden_ambush_buff) } and feralstealthcdpostconditions() or not { hastalent(bloodtalons_talent) and buffexpires(bloodtalons_buff) and energy() + 3.5 * energyregenrate() + 40 * buffpresent(clearcasting_buff) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and buffcount(bt_buffs) == 0 } and { hastalent(bloodtalons_talent) and { buffexpires(bloodtalons_buff) or buffcount(bt_buffs) == 2 } and feralbloodtalonscdpostconditions() or { target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and spell(rake) or combopoints() == 0 and spell(feral_frenzy) or target.refreshable(moonfire_cat) and spell(moonfire_cat) or target.refreshable(thrash_cat) and ticksgainedonrefresh(thrash_cat) > thrash_ticks() and spell(thrash_cat) or buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) and spell(brutal_slash) or enemies() > 2 and spell(swipe_cat) or buffpresent(clearcasting_buff) and spell(shred) or feralfillercdpostconditions() }
}

### Feral icons.

AddCheckBox(opt_druid_feral_aoe l(aoe) default enabled=(specialization(feral)))

AddIcon enabled=(not checkboxon(opt_druid_feral_aoe) and specialization(feral)) enemies=1 help=shortcd
{
 if not incombat() feralprecombatshortcdactions()
 feral_defaultshortcdactions()
}

AddIcon enabled=(checkboxon(opt_druid_feral_aoe) and specialization(feral)) help=shortcd
{
 if not incombat() feralprecombatshortcdactions()
 feral_defaultshortcdactions()
}

AddIcon enabled=(specialization(feral)) enemies=1 help=main
{
 if not incombat() feralprecombatmainactions()
 feral_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_druid_feral_aoe) and specialization(feral)) help=aoe
{
 if not incombat() feralprecombatmainactions()
 feral_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_druid_feral_aoe) and not specialization(feral)) enemies=1 help=cd
{
 if not incombat() feralprecombatcdactions()
 feral_defaultcdactions()
}

AddIcon enabled=(checkboxon(opt_druid_feral_aoe) and specialization(feral)) help=cd
{
 if not incombat() feralprecombatcdactions()
 feral_defaultcdactions()
}

### Required symbols
# berserk
# berserk_cat
# berserking
# blood_of_the_enemy
# blood_of_the_enemy_debuff
# bloodtalons_buff
# bloodtalons_talent
# brutal_slash
# bs_inc_buff
# bt_brutal_slash_buff
# bt_buffs
# bt_moonfire_buff
# bt_rake_buff
# bt_shred_buff
# bt_swipe_buff
# bt_thrash_buff
# cat_form
# clearcasting_buff
# concentrated_flame
# conductive_ink
# feral_frenzy
# ferocious_bite
# focused_azerite_beam
# guardian_of_azeroth
# incarnation
# incarnation_king_of_the_jungle
# iron_jaws
# lunar_inspiration
# maim
# mangle
# memory_of_lucid_dreams
# mighty_bash
# moonfire_cat
# primal_wrath
# primal_wrath_talent
# prowl
# purifying_blast
# rake
# rake_debuff
# razor_coral_debuff
# reaping_flames
# reckless_force_buff
# rip
# ripple_in_space
# sabertooth_talent
# savage_roar
# shadowmeld
# shred
# skull_bash
# sudden_ambush_buff
# superior_battle_potion_of_agility_item
# swipe
# swipe_cat
# the_unbound_force
# thorns
# thrash_cat
# tigers_fury
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
# wild_fleshrending_trait
# worldvein_resonance
]]
        OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
    end
    do
        local name = "sc_t25_druid_guardian"
        local desc = "[9.0] Simulationcraft: T25_Druid_Guardian"
        local code = [[
# Based on SimulationCraft profile "T25_Druid_Guardian".
#	class=druid
#	spec=guardian
#	talents=1000131

Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt l(interrupt) default enabled=(specialization(guardian)))
AddCheckBox(opt_melee_range l(not_in_melee_range) enabled=(specialization(guardian)))
AddCheckBox(opt_use_consumables l(opt_use_consumables) default enabled=(specialization(guardian)))
AddCheckBox(owlweave_bear l(owlweave_bear) default enabled=(specialization(guardian)))
AddCheckBox(catweave_bear l(catweave_bear) default enabled=(specialization(guardian)))

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
  texture(misc_arrowlup help=(l(not_in_melee_range)))
 }
}

### actions.precombat

AddFunction guardianprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #cat_form,if=druid.catweave_bear&talent.feral_affinity.enabled
 if checkboxon("catweave_bear") and hastalent(feral_affinity_talent_guardian) spell(cat_form)
 #prowl,if=druid.catweave_bear&talent.feral_affinity.enabled
 if checkboxon("catweave_bear") and hastalent(feral_affinity_talent_guardian) spell(prowl)
 #moonkin_form,if=druid.owlweave_bear&talent.balance_affinity.enabled
 if checkboxon("owlweave_bear") and hastalent(balance_affinity_talent) spell(moonkin_form)
 #bear_form,if=!druid.catweave_bear&!druid.owlweave_bear
 if not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") spell(bear_form)
 #wrath,if=druid.owlweave_bear
 if checkboxon("owlweave_bear") spell(wrath)
}

AddFunction guardianprecombatmainpostconditions
{
}

AddFunction guardianprecombatshortcdactions
{
}

AddFunction guardianprecombatshortcdpostconditions
{
 checkboxon("catweave_bear") and hastalent(feral_affinity_talent_guardian) and spell(cat_form) or checkboxon("catweave_bear") and hastalent(feral_affinity_talent_guardian) and spell(prowl) or checkboxon("owlweave_bear") and hastalent(balance_affinity_talent) and spell(moonkin_form) or not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") and spell(bear_form) or checkboxon("owlweave_bear") and spell(wrath)
}

AddFunction guardianprecombatcdactions
{
 unless checkboxon("catweave_bear") and hastalent(feral_affinity_talent_guardian) and spell(cat_form) or checkboxon("catweave_bear") and hastalent(feral_affinity_talent_guardian) and spell(prowl) or checkboxon("owlweave_bear") and hastalent(balance_affinity_talent) and spell(moonkin_form) or not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") and spell(bear_form)
 {
  #heart_of_the_Wild,if=talent.heart_of_the_wild.enabled&druid.owlweave_bear
  if hastalent(heart_of_the_wild_talent) and checkboxon("owlweave_bear") spell(heart_of_the_wild)
 }
}

AddFunction guardianprecombatcdpostconditions
{
 checkboxon("catweave_bear") and hastalent(feral_affinity_talent_guardian) and spell(cat_form) or checkboxon("catweave_bear") and hastalent(feral_affinity_talent_guardian) and spell(prowl) or checkboxon("owlweave_bear") and hastalent(balance_affinity_talent) and spell(moonkin_form) or not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") and spell(bear_form) or checkboxon("owlweave_bear") and spell(wrath)
}

### actions.owlweave

AddFunction guardianowlweavemainactions
{
 #moonkin_form,if=!buff.moonkin_form.up
 if not buffpresent(moonkin_form) spell(moonkin_form)
 #adaptive_swarm,target_if=refreshable
 if target.refreshable(adaptive_swarm) spell(adaptive_swarm)
 #moonfire,target_if=refreshable|buff.galactic_guardian.up
 if target.refreshable(moonfire_debuff) or buffpresent(galactic_guardian_buff) spell(moonfire)
 #sunfire,target_if=refreshable
 if target.refreshable(sunfire) spell(sunfire)
 #starsurge,if=(buff.eclipse_lunar.up|buff.eclipse_solar.up)
 if buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) spell(starsurge)
 #starfire,if=(eclipse.in_lunar|eclipse.solar_next)|(eclipse.in_lunar&buff.starsurge_empowerment.up)
 if buffpresent(eclipse_lunar) or counter(solar) == 1 or buffpresent(eclipse_lunar) and buffpresent(starsurge_empowerment_buff) spell(starfire)
 #wrath
 spell(wrath)
}

AddFunction guardianowlweavemainpostconditions
{
}

AddFunction guardianowlweaveshortcdactions
{
 unless not buffpresent(moonkin_form) and spell(moonkin_form)
 {
  #empower_bond,if=druid.owlweave_bear
  if checkboxon("owlweave_bear") spell(empower_bond)
 }
}

AddFunction guardianowlweaveshortcdpostconditions
{
 not buffpresent(moonkin_form) and spell(moonkin_form) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or { target.refreshable(moonfire_debuff) or buffpresent(galactic_guardian_buff) } and spell(moonfire) or target.refreshable(sunfire) and spell(sunfire) or { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and spell(starsurge) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or buffpresent(eclipse_lunar) and buffpresent(starsurge_empowerment_buff) } and spell(starfire) or spell(wrath)
}

AddFunction guardianowlweavecdactions
{
 unless not buffpresent(moonkin_form) and spell(moonkin_form)
 {
  #heart_of_the_wild,if=talent.heart_of_the_wild.enabled&!buff.heart_of_the_wild.up
  if hastalent(heart_of_the_wild_talent) and not buffpresent(heart_of_the_wild) spell(heart_of_the_wild)

  unless checkboxon("owlweave_bear") and spell(empower_bond)
  {
   #convoke_the_spirits,if=druid.owlweave_bear
   if checkboxon("owlweave_bear") spell(convoke_the_spirits)
  }
 }
}

AddFunction guardianowlweavecdpostconditions
{
 not buffpresent(moonkin_form) and spell(moonkin_form) or checkboxon("owlweave_bear") and spell(empower_bond) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or { target.refreshable(moonfire_debuff) or buffpresent(galactic_guardian_buff) } and spell(moonfire) or target.refreshable(sunfire) and spell(sunfire) or { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and spell(starsurge) or { buffpresent(eclipse_lunar) or counter(solar) == 1 or buffpresent(eclipse_lunar) and buffpresent(starsurge_empowerment_buff) } and spell(starfire) or spell(wrath)
}

### actions.lycarao

AddFunction guardianlycaraomainactions
{
 #moonkin_form
 spell(moonkin_form)
}

AddFunction guardianlycaraomainpostconditions
{
}

AddFunction guardianlycaraoshortcdactions
{
}

AddFunction guardianlycaraoshortcdpostconditions
{
 spell(moonkin_form)
}

AddFunction guardianlycaraocdactions
{
}

AddFunction guardianlycaraocdpostconditions
{
 spell(moonkin_form)
}

### actions.lycarac

AddFunction guardianlycaracmainactions
{
 #cat_form
 spell(cat_form)
}

AddFunction guardianlycaracmainpostconditions
{
}

AddFunction guardianlycaracshortcdactions
{
}

AddFunction guardianlycaracshortcdpostconditions
{
 spell(cat_form)
}

AddFunction guardianlycaraccdactions
{
}

AddFunction guardianlycaraccdpostconditions
{
 spell(cat_form)
}

### actions.catweave

AddFunction guardiancatweavemainactions
{
 #cat_form,if=!buff.cat_form.up
 if not buffpresent(cat_form) spell(cat_form)
 #rake,if=buff.prowl.up
 if buffpresent(prowl) spell(rake)
 #rip,if=dot.rip.refreshable&combo_points>=4
 if target.debuffrefreshable(rip) and combopoints() >= 4 spell(rip)
 #ferocious_bite,if=combo_points>=4
 if combopoints() >= 4 spell(ferocious_bite)
 #adaptive_swarm,target_if=refreshable
 if target.refreshable(adaptive_swarm) spell(adaptive_swarm)
 #rake,if=dot.rake.refreshable&combo_points<4
 if target.debuffrefreshable(rake_debuff) and combopoints() < 4 spell(rake)
 #shred
 spell(shred)
}

AddFunction guardiancatweavemainpostconditions
{
}

AddFunction guardiancatweaveshortcdactions
{
 unless not buffpresent(cat_form) and spell(cat_form) or buffpresent(prowl) and spell(rake)
 {
  #empower_bond,if=druid.catweave_bear
  if checkboxon("catweave_bear") spell(empower_bond)
 }
}

AddFunction guardiancatweaveshortcdpostconditions
{
 not buffpresent(cat_form) and spell(cat_form) or buffpresent(prowl) and spell(rake) or target.debuffrefreshable(rip) and combopoints() >= 4 and spell(rip) or combopoints() >= 4 and spell(ferocious_bite) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or target.debuffrefreshable(rake_debuff) and combopoints() < 4 and spell(rake) or spell(shred)
}

AddFunction guardiancatweavecdactions
{
 unless not buffpresent(cat_form) and spell(cat_form) or buffpresent(prowl) and spell(rake)
 {
  #heart_of_the_wild,if=talent.heart_of_the_wild.enabled&!buff.heart_of_the_wild.up
  if hastalent(heart_of_the_wild_talent) and not buffpresent(heart_of_the_wild) spell(heart_of_the_wild)

  unless checkboxon("catweave_bear") and spell(empower_bond)
  {
   #convoke_the_spirits,if=druid.catweave_bear
   if checkboxon("catweave_bear") spell(convoke_the_spirits)
  }
 }
}

AddFunction guardiancatweavecdpostconditions
{
 not buffpresent(cat_form) and spell(cat_form) or buffpresent(prowl) and spell(rake) or checkboxon("catweave_bear") and spell(empower_bond) or target.debuffrefreshable(rip) and combopoints() >= 4 and spell(rip) or combopoints() >= 4 and spell(ferocious_bite) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or target.debuffrefreshable(rake_debuff) and combopoints() < 4 and spell(rake) or spell(shred)
}

### actions.bear

AddFunction guardianbearmainactions
{
 #bear_form,if=!buff.bear_form.up
 if not buffpresent(bear_form) spell(bear_form)
 #incarnation,if=(buff.ravenous_frenzy.up|!covenant.venthyr)
 if buffpresent(ravenous_frenzy) or not iscovenant(venthyr) spell(incarnation)
 #ironfur,if=buff.ironfur.remains<0.5
 if buffremaining(ironfur) < 0.5 spell(ironfur)
 #adaptive_swarm,target_if=refreshable
 if target.refreshable(adaptive_swarm) spell(adaptive_swarm)
 #moonfire,if=(buff.galactic_guardian.up&druid.owlweave_bear)&active_enemies<=3
 if buffpresent(galactic_guardian_buff) and checkboxon("owlweave_bear") and enemies() <= 3 spell(moonfire)
 #thrash_bear,target_if=refreshable|dot.thrash_bear.stack<3|(dot.thrash_bear.stack<4&runeforge.luffainfused_embrace.equipped)|active_enemies>5
 if target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and equippedruneforge(luffainfused_embrace_runeforge) or enemies() > 5 spell(thrash_bear)
 #swipe,if=buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&active_enemies>=4
 if buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and enemies() >= 4 spell(swipe)
 #maul,if=buff.incarnation.up&active_enemies<2
 if buffpresent(incarnation) and enemies() < 2 spell(maul)
 #maul,if=(buff.savage_combatant.stack>=1)&(buff.tooth_and_claw.up)&buff.incarnation.up&active_enemies=2
 if buffstacks(savage_combatant_buff) >= 1 and buffpresent(tooth_and_claw_buff) and buffpresent(incarnation) and enemies() == 2 spell(maul)
 #mangle,if=buff.incarnation.up&active_enemies<=3
 if buffpresent(incarnation) and enemies() <= 3 spell(mangle)
 #moonfire,target_if=refreshable&active_enemies<=3
 if target.refreshable(moonfire_debuff) and enemies() <= 3 spell(moonfire)
 #maul,if=(buff.tooth_and_claw.stack>=2)|(buff.tooth_and_claw.up&buff.tooth_and_claw.remains<1.5)|(buff.savage_combatant.stack>=3)
 if buffstacks(tooth_and_claw_buff) >= 2 or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 or buffstacks(savage_combatant_buff) >= 3 spell(maul)
 #thrash_bear,if=active_enemies>1
 if enemies() > 1 spell(thrash_bear)
 #moonfire,if=(buff.galactic_guardian.up&druid.catweave_bear)&active_enemies<=3|(buff.galactic_guardian.up&!druid.catweave_bear&!druid.owlweave_bear)&active_enemies<=3
 if buffpresent(galactic_guardian_buff) and checkboxon("catweave_bear") and enemies() <= 3 or buffpresent(galactic_guardian_buff) and not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") and enemies() <= 3 spell(moonfire)
 #mangle,if=(rage<80)&active_enemies<4
 if rage() < 80 and enemies() < 4 spell(mangle)
 #thrash_bear
 spell(thrash_bear)
 #maul
 spell(maul)
 #swipe_bear
 spell(swipe)
}

AddFunction guardianbearmainpostconditions
{
}

AddFunction guardianbearshortcdactions
{
 unless not buffpresent(bear_form) and spell(bear_form) or { buffpresent(ravenous_frenzy) or not iscovenant(venthyr) } and spell(incarnation)
 {
  #empower_bond,if=(!druid.catweave_bear&!druid.owlweave_bear)|active_enemies>=2
  if not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") or enemies() >= 2 spell(empower_bond)
  #barkskin,if=(talent.brambles.enabled)&(buff.bear_form.up)
  if hastalent(brambles_talent) and buffpresent(bear_form) spell(barkskin)

  unless buffremaining(ironfur) < 0.5 and spell(ironfur) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or buffpresent(galactic_guardian_buff) and checkboxon("owlweave_bear") and enemies() <= 3 and spell(moonfire) or { target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and equippedruneforge(luffainfused_embrace_runeforge) or enemies() > 5 } and spell(thrash_bear) or buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and enemies() >= 4 and spell(swipe) or buffpresent(incarnation) and enemies() < 2 and spell(maul) or buffstacks(savage_combatant_buff) >= 1 and buffpresent(tooth_and_claw_buff) and buffpresent(incarnation) and enemies() == 2 and spell(maul) or buffpresent(incarnation) and enemies() <= 3 and spell(mangle) or target.refreshable(moonfire_debuff) and enemies() <= 3 and spell(moonfire) or { buffstacks(tooth_and_claw_buff) >= 2 or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 or buffstacks(savage_combatant_buff) >= 3 } and spell(maul) or enemies() > 1 and spell(thrash_bear) or { buffpresent(galactic_guardian_buff) and checkboxon("catweave_bear") and enemies() <= 3 or buffpresent(galactic_guardian_buff) and not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") and enemies() <= 3 } and spell(moonfire) or rage() < 80 and enemies() < 4 and spell(mangle)
  {
   #pulverize,target_if=dot.thrash_bear.stack>2
   if target.debuffstacks(thrash_bear_debuff) > 2 and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) spell(pulverize)
  }
 }
}

AddFunction guardianbearshortcdpostconditions
{
 not buffpresent(bear_form) and spell(bear_form) or { buffpresent(ravenous_frenzy) or not iscovenant(venthyr) } and spell(incarnation) or buffremaining(ironfur) < 0.5 and spell(ironfur) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or buffpresent(galactic_guardian_buff) and checkboxon("owlweave_bear") and enemies() <= 3 and spell(moonfire) or { target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and equippedruneforge(luffainfused_embrace_runeforge) or enemies() > 5 } and spell(thrash_bear) or buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and enemies() >= 4 and spell(swipe) or buffpresent(incarnation) and enemies() < 2 and spell(maul) or buffstacks(savage_combatant_buff) >= 1 and buffpresent(tooth_and_claw_buff) and buffpresent(incarnation) and enemies() == 2 and spell(maul) or buffpresent(incarnation) and enemies() <= 3 and spell(mangle) or target.refreshable(moonfire_debuff) and enemies() <= 3 and spell(moonfire) or { buffstacks(tooth_and_claw_buff) >= 2 or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 or buffstacks(savage_combatant_buff) >= 3 } and spell(maul) or enemies() > 1 and spell(thrash_bear) or { buffpresent(galactic_guardian_buff) and checkboxon("catweave_bear") and enemies() <= 3 or buffpresent(galactic_guardian_buff) and not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") and enemies() <= 3 } and spell(moonfire) or rage() < 80 and enemies() < 4 and spell(mangle) or spell(thrash_bear) or spell(maul) or spell(swipe)
}

AddFunction guardianbearcdactions
{
 unless not buffpresent(bear_form) and spell(bear_form)
 {
  #potion,if=((buff.berserk_bear.up|buff.incarnation_guardian_of_ursoc.up)&(!druid.catweave_bear&!druid.owlweave_bear))
  if { buffpresent(berserk_bear) or buffpresent(incarnation_guardian_of_ursoc) } and not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") and { checkboxon(opt_use_consumables) and target.classification(worldboss) } item(superior_battle_potion_of_agility_item usable=1)
  #ravenous_frenzy
  spell(ravenous_frenzy)
  #convoke_the_spirits,if=!druid.catweave_bear&!druid.owlweave_bear
  if not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") spell(convoke_the_spirits)
  #berserk_bear,if=(buff.ravenous_frenzy.up|!covenant.venthyr)
  if buffpresent(ravenous_frenzy) or not iscovenant(venthyr) spell(berserk_bear)
 }
}

AddFunction guardianbearcdpostconditions
{
 not buffpresent(bear_form) and spell(bear_form) or { buffpresent(ravenous_frenzy) or not iscovenant(venthyr) } and spell(incarnation) or { not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") or enemies() >= 2 } and spell(empower_bond) or hastalent(brambles_talent) and buffpresent(bear_form) and spell(barkskin) or buffremaining(ironfur) < 0.5 and spell(ironfur) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or buffpresent(galactic_guardian_buff) and checkboxon("owlweave_bear") and enemies() <= 3 and spell(moonfire) or { target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and equippedruneforge(luffainfused_embrace_runeforge) or enemies() > 5 } and spell(thrash_bear) or buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and enemies() >= 4 and spell(swipe) or buffpresent(incarnation) and enemies() < 2 and spell(maul) or buffstacks(savage_combatant_buff) >= 1 and buffpresent(tooth_and_claw_buff) and buffpresent(incarnation) and enemies() == 2 and spell(maul) or buffpresent(incarnation) and enemies() <= 3 and spell(mangle) or target.refreshable(moonfire_debuff) and enemies() <= 3 and spell(moonfire) or { buffstacks(tooth_and_claw_buff) >= 2 or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 or buffstacks(savage_combatant_buff) >= 3 } and spell(maul) or enemies() > 1 and spell(thrash_bear) or { buffpresent(galactic_guardian_buff) and checkboxon("catweave_bear") and enemies() <= 3 or buffpresent(galactic_guardian_buff) and not checkboxon("catweave_bear") and not checkboxon("owlweave_bear") and enemies() <= 3 } and spell(moonfire) or rage() < 80 and enemies() < 4 and spell(mangle) or target.debuffstacks(thrash_bear_debuff) > 2 and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) and spell(pulverize) or spell(thrash_bear) or spell(maul) or spell(swipe)
}

### actions.default

AddFunction guardian_defaultmainactions
{
 #run_action_list,name=catweave,if=druid.catweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&dot.moonfire.remains>=gcd+0.5&rage<40&buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&buff.galactic_guardian.down)|(buff.cat_form.up&energy>25)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up&(buff.cat_form.up&energy>20))|(runeforge.oath_of_the_elder_druid.equipped&buff.heart_of_the_wild.remains<10)&(buff.cat_form.up&energy>20)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
 if checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardiancatweavemainactions()

 unless checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweavemainpostconditions()
 {
  #run_action_list,name=owlweave,if=druid.owlweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&rage<20&buff.incarnation.down&buff.berserk_bear.down)|(buff.moonkin_form.up&dot.sunfire.refreshable)|(buff.moonkin_form.up&buff.heart_of_the_wild.up)|(buff.moonkin_form.up&(buff.eclipse_lunar.up|buff.eclipse_solar.up)&!runeforge.oath_of_the_elder_druid.equipped)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up)|(covenant.night_fae&cooldown.convoke_the_spirits.remains<=1)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
  if checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardianowlweavemainactions()

  unless checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweavemainpostconditions()
  {
   #run_action_list,name=lycarao,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.balance_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
   if equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaraomainactions()

   unless equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraomainpostconditions()
   {
    #run_action_list,name=lycarac,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.feral_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
    if equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaracmainactions()

    unless equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaracmainpostconditions()
    {
     #run_action_list,name=bear
     guardianbearmainactions()
    }
   }
  }
 }
}

AddFunction guardian_defaultmainpostconditions
{
 checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweavemainpostconditions() or checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweavemainpostconditions() or equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraomainpostconditions() or equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaracmainpostconditions() or guardianbearmainpostconditions()
}

AddFunction guardian_defaultshortcdactions
{
 #auto_attack
 guardiangetinmeleerange()
 #run_action_list,name=catweave,if=druid.catweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&dot.moonfire.remains>=gcd+0.5&rage<40&buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&buff.galactic_guardian.down)|(buff.cat_form.up&energy>25)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up&(buff.cat_form.up&energy>20))|(runeforge.oath_of_the_elder_druid.equipped&buff.heart_of_the_wild.remains<10)&(buff.cat_form.up&energy>20)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
 if checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardiancatweaveshortcdactions()

 unless checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweaveshortcdpostconditions()
 {
  #run_action_list,name=owlweave,if=druid.owlweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&rage<20&buff.incarnation.down&buff.berserk_bear.down)|(buff.moonkin_form.up&dot.sunfire.refreshable)|(buff.moonkin_form.up&buff.heart_of_the_wild.up)|(buff.moonkin_form.up&(buff.eclipse_lunar.up|buff.eclipse_solar.up)&!runeforge.oath_of_the_elder_druid.equipped)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up)|(covenant.night_fae&cooldown.convoke_the_spirits.remains<=1)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
  if checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardianowlweaveshortcdactions()

  unless checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweaveshortcdpostconditions()
  {
   #run_action_list,name=lycarao,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.balance_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
   if equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaraoshortcdactions()

   unless equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraoshortcdpostconditions()
   {
    #run_action_list,name=lycarac,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.feral_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
    if equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaracshortcdactions()

    unless equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaracshortcdpostconditions()
    {
     #run_action_list,name=bear
     guardianbearshortcdactions()
    }
   }
  }
 }
}

AddFunction guardian_defaultshortcdpostconditions
{
 checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweaveshortcdpostconditions() or checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweaveshortcdpostconditions() or equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraoshortcdpostconditions() or equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaracshortcdpostconditions() or guardianbearshortcdpostconditions()
}

AddFunction guardian_defaultcdactions
{
 guardianinterruptactions()
 #use_items
 guardianuseitemactions()
 #potion,if=((talent.heart_of_the_wild.enabled&buff.heart_of_the_wild.up)&(druid.catweave_bear|druid.owlweave_bear))
 if hastalent(heart_of_the_wild_talent) and buffpresent(heart_of_the_wild) and { checkboxon("catweave_bear") or checkboxon("owlweave_bear") } and { checkboxon(opt_use_consumables) and target.classification(worldboss) } item(superior_battle_potion_of_agility_item usable=1)
 #run_action_list,name=catweave,if=druid.catweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&dot.moonfire.remains>=gcd+0.5&rage<40&buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&buff.galactic_guardian.down)|(buff.cat_form.up&energy>25)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up&(buff.cat_form.up&energy>20))|(runeforge.oath_of_the_elder_druid.equipped&buff.heart_of_the_wild.remains<10)&(buff.cat_form.up&energy>20)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
 if checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardiancatweavecdactions()

 unless checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweavecdpostconditions()
 {
  #run_action_list,name=owlweave,if=druid.owlweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&rage<20&buff.incarnation.down&buff.berserk_bear.down)|(buff.moonkin_form.up&dot.sunfire.refreshable)|(buff.moonkin_form.up&buff.heart_of_the_wild.up)|(buff.moonkin_form.up&(buff.eclipse_lunar.up|buff.eclipse_solar.up)&!runeforge.oath_of_the_elder_druid.equipped)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up)|(covenant.night_fae&cooldown.convoke_the_spirits.remains<=1)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
  if checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardianowlweavecdactions()

  unless checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweavecdpostconditions()
  {
   #run_action_list,name=lycarao,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.balance_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
   if equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaraocdactions()

   unless equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraocdpostconditions()
   {
    #run_action_list,name=lycarac,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.feral_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
    if equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaraccdactions()

    unless equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraccdpostconditions()
    {
     #run_action_list,name=bear
     guardianbearcdactions()
    }
   }
  }
 }
}

AddFunction guardian_defaultcdpostconditions
{
 checkboxon("catweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire_debuff) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear) and buffexpires(galactic_guardian_buff) or buffpresent(cat_form) and energy() > 25 or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or equippedruneforge(oath_of_the_elder_druid_runeforge) and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweavecdpostconditions() or checkboxon("owlweave_bear") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not equippedruneforge(oath_of_the_elder_druid_runeforge) or equippedruneforge(oath_of_the_elder_druid_runeforge) and not buffpresent(oath_of_the_elder_druid) or iscovenant(night_fae) and spellcooldown(convoke_the_spirits) <= 1 or iscovenant(kyrian) and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweavecdpostconditions() or equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraocdpostconditions() or equippedruneforge(lycaras_fleeting_glimpse_runeforge) and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraccdpostconditions() or guardianbearcdpostconditions()
}

### Guardian icons.

AddCheckBox(opt_druid_guardian_aoe l(aoe) default enabled=(specialization(guardian)))

AddIcon enabled=(not checkboxon(opt_druid_guardian_aoe) and specialization(guardian)) enemies=1 help=shortcd
{
 if not incombat() guardianprecombatshortcdactions()
 guardian_defaultshortcdactions()
}

AddIcon enabled=(checkboxon(opt_druid_guardian_aoe) and specialization(guardian)) help=shortcd
{
 if not incombat() guardianprecombatshortcdactions()
 guardian_defaultshortcdactions()
}

AddIcon enabled=(specialization(guardian)) enemies=1 help=main
{
 if not incombat() guardianprecombatmainactions()
 guardian_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_druid_guardian_aoe) and specialization(guardian)) help=aoe
{
 if not incombat() guardianprecombatmainactions()
 guardian_defaultmainactions()
}

AddIcon enabled=(checkboxon(opt_druid_guardian_aoe) and not specialization(guardian)) enemies=1 help=cd
{
 if not incombat() guardianprecombatcdactions()
 guardian_defaultcdactions()
}

AddIcon enabled=(checkboxon(opt_druid_guardian_aoe) and specialization(guardian)) help=cd
{
 if not incombat() guardianprecombatcdactions()
 guardian_defaultcdactions()
}

### Required symbols
# adaptive_swarm
# balance_affinity_talent
# barkskin
# bear_form
# berserk_bear
# brambles_talent
# cat_form
# convoke_the_spirits
# eclipse_lunar
# eclipse_solar
# empower_bond
# feral_affinity_talent_guardian
# ferocious_bite
# galactic_guardian_buff
# heart_of_the_wild
# heart_of_the_wild_talent
# incapacitating_roar
# incarnation
# incarnation_guardian_of_ursoc
# ironfur
# kyrian
# luffainfused_embrace_runeforge
# lycaras_fleeting_glimpse
# lycaras_fleeting_glimpse_runeforge
# mangle
# maul
# mighty_bash
# moonfire
# moonfire_debuff
# moonkin_form
# night_fae
# oath_of_the_elder_druid
# oath_of_the_elder_druid_runeforge
# prowl
# pulverize
# rake
# rake_debuff
# ravenous_frenzy
# rip
# savage_combatant_buff
# shred
# skull_bash
# starfire
# starsurge
# starsurge_empowerment_buff
# sunfire
# superior_battle_potion_of_agility_item
# swipe
# thrash_bear
# thrash_bear_debuff
# tooth_and_claw_buff
# typhoon
# venthyr
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
# wrath
]]
        OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
    end
end
