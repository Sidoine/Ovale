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
 enemies() > 8 + masteryeffect() / 100 / 20 + buffstacks(starsurge_empowerment_buff) / 4
}

AddFunction starfall_wont_fall_off
{
 astralpower() > 80 - buffremaining(starfall) * 3 / { 100 / { 100 + spellcastspeedpercent() } } - target.debuffremaining(fury_of_elune) * 5 and buffpresent(starfall)
}

AddFunction convoke_condition
{
 buffamount(primordial_arcanic_pulsar) < 250 - astralpower() and { spellcooldown(ca_inc) + 10 > message("interpolated_fight_remains is not implemented") or spellcooldown(ca_inc) + 30 < message("interpolated_fight_remains is not implemented") and message("interpolated_fight_remains is not implemented") > 130 or buffremaining(ca_inc_buff) > 7 } and message("eclipse.in_any is not implemented") or message("interpolated_fight_remains is not implemented") % 120 < 15
}

AddFunction convoke_desync
{
 { message("interpolated_fight_remains is not implemented") - 20 } / 120 > { message("interpolated_fight_remains is not implemented") - 25 - 10 * talentpoints(incarnation_talent) - 4 * message("conduit.precise_alignment.enabled is not implemented") } / 180
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=balance)

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

AddFunction balanceuseheartessence
{
 spell(concentrated_flame_essence)
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
 #moonkin_form
 spell(moonkin_form)
 #wrath
 spell(wrath)
 #wrath
 spell(wrath)
 #starsurge,if=spell_targets.starfall<4
 if enemies() < 4 spell(starsurge)
}

AddFunction balanceprecombatmainpostconditions
{
}

AddFunction balanceprecombatshortcdactions
{
}

AddFunction balanceprecombatshortcdpostconditions
{
 spell(moonkin_form) or spell(wrath) or spell(wrath) or enemies() < 4 and spell(starsurge)
}

AddFunction balanceprecombatcdactions
{
}

AddFunction balanceprecombatcdpostconditions
{
 spell(moonkin_form) or spell(wrath) or spell(wrath) or enemies() < 4 and spell(starsurge)
}

### actions.aoe

AddFunction balanceaoemainactions
{
 #starfall,if=buff.starfall.refreshable&(!runeforge.lycaras_fleeting_glimpse.equipped|time%%45>buff.starfall.remains+2)
 if message("buff.starfall.refreshable is not implemented") and { not message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") or timeincombat() % 45 > buffremaining(starfall) + 2 } spell(starfall)
 #sunfire,target_if=refreshable&target.time_to_die>14-spell_targets+remains,if=ap_check&eclipse.in_any
 if target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and astralpower() >= astralpowercost(sunfire) and message("eclipse.in_any is not implemented") spell(sunfire)
 #moonfire,target_if=refreshable&target.time_to_die>(14+(spell_targets.starfire*1.5))%spell_targets+remains,if=(cooldown.ca_inc.ready|spell_targets.starfire<3|(eclipse.in_solar|eclipse.in_both|eclipse.in_lunar&!talent.soul_of_the_forest.enabled)&(spell_targets.starfire<10*(1+talent.twin_moons.enabled))&astral_power>50-buff.starfall.remains*6)&!buff.kindred_empowerment_energize.up&ap_check
 if target.refreshable(moonfire) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + buffremaining(moonfire) and { spellcooldown(ca_inc) == 0 or enemies() < 3 or { message("eclipse.in_solar is not implemented") or message("eclipse.in_both is not implemented") or message("eclipse.in_lunar is not implemented") and not hastalent(soul_of_the_forest_talent) } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize_buff) and astralpower() >= astralpowercost(moonfire) spell(moonfire)
 #incarnation,if=(buff.starfall.up|astral_power>50)&!buff.solstice.up&!buff.ca_inc.up&(interpolated_fight_remains<cooldown.convoke_the_spirits.remains+7|interpolated_fight_remains%%180<32|cooldown.convoke_the_spirits.up|!covenant.night_fae)
 if { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(ca_inc_buff) and { message("interpolated_fight_remains is not implemented") < spellcooldown(convoke_the_spirits) + 7 or message("interpolated_fight_remains is not implemented") % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not message("covenant.night_fae is not implemented") } spell(incarnation)
 #kindred_spirits,if=interpolated_fight_remains<15|(buff.primordial_arcanic_pulsar.value<250|buff.primordial_arcanic_pulsar.value>=250)&buff.starfall.up&cooldown.ca_inc.remains>50
 if message("interpolated_fight_remains is not implemented") < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(ca_inc) > 50 spell(kindred_spirits)
 #stellar_flare,target_if=refreshable&time_to_die>15,if=spell_targets.starfire<4&ap_check&(buff.ca_inc.remains>10|!buff.ca_inc.up)
 if target.refreshable(stellar_flare) and target.timetodie() > 15 and enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(ca_inc_buff) > 10 or not buffpresent(ca_inc_buff) } spell(stellar_flare)
 #adaptive_swarm,target_if=!ticking,if=spell_targets.starfall<9
 if not buffpresent(adaptive_swarm) and enemies() < 9 spell(adaptive_swarm)
 #starfall,if=buff.oneths_perception.up&(buff.starfall.refreshable|astral_power>90)
 if buffpresent(oneths_perception) and { message("buff.starfall.refreshable is not implemented") or astralpower() > 90 } spell(starfall)
 #starfall,if=covenant.night_fae&variable.convoke_condition&cooldown.convoke_the_spirits.remains<gcd.max*ceil(astral_power%50)&buff.starfall.refreshable
 if message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and message("buff.starfall.refreshable is not implemented") spell(starfall)
 #starsurge,if=covenant.night_fae&variable.convoke_condition&cooldown.convoke_the_spirits.remains<gcd.max*ceil(astral_power%30)&buff.starfall.up
 if message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) spell(starsurge)
 #variable,name=starfall_wont_fall_off,value=astral_power>80-(buff.starfall.remains*3%spell_haste)-(dot.fury_of_elune.remains*5)&buff.starfall.up
 #starsurge,if=buff.oneths_clear_vision.up|!starfire.ap_check|(buff.ca_inc.remains<5&buff.ca_inc.up|(buff.ravenous_frenzy.remains<gcd.max*ceil(astral_power%30)&buff.ravenous_frenzy.up))&variable.starfall_wont_fall_off&spell_targets.starfall<3
 if buffpresent(oneths_clear_vision) or not message("starfire.ap_check is not implemented") or { buffremaining(ca_inc_buff) < 5 and buffpresent(ca_inc_buff) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 spell(starsurge)
 #new_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and not spellknown(half_moon) and not spellknown(full_moon) spell(new_moon)
 #half_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) spell(half_moon)
 #full_moon,if=(eclipse.in_any&cooldown.ca_inc.remains>50|(charges=2&recharge_time<5)|charges=3)&ap_check
 if { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) spell(full_moon)
 #variable,name=starfire_in_solar,value=spell_targets.starfire>8+floor(mastery_value%20)+floor(buff.starsurge_empowerment.stack%4)
 #wrath,if=eclipse.lunar_next|eclipse.any_next&variable.is_cleave|eclipse.in_solar&!variable.starfire_in_solar|buff.ca_inc.remains<action.starfire.execute_time&!variable.is_cleave&buff.ca_inc.remains<execute_time&buff.ca_inc.up|buff.ravenous_frenzy.up&spell_haste>0.6|!variable.is_cleave&buff.ca_inc.remains>execute_time
 if message("eclipse.lunar_next is not implemented") or message("eclipse.any_next is not implemented") and is_cleave() or message("eclipse.in_solar is not implemented") and not starfire_in_solar() or buffremaining(ca_inc_buff) < executetime(starfire) and not is_cleave() and buffremaining(ca_inc_buff) < executetime(wrath) and buffpresent(ca_inc_buff) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 or not is_cleave() and buffremaining(ca_inc_buff) > executetime(wrath) spell(wrath)
 #starfire
 spell(starfire)
 #run_action_list,name=fallthru
 balancefallthruactions()
}

AddFunction balanceaoemainpostconditions
{
}

AddFunction balanceaoeshortcdactions
{
 unless message("buff.starfall.refreshable is not implemented") and { not message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") or timeincombat() % 45 > buffremaining(starfall) + 2 } and spell(starfall) or target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and astralpower() >= astralpowercost(sunfire) and message("eclipse.in_any is not implemented") and spell(sunfire) or target.refreshable(moonfire) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + buffremaining(moonfire) and { spellcooldown(ca_inc) == 0 or enemies() < 3 or { message("eclipse.in_solar is not implemented") or message("eclipse.in_both is not implemented") or message("eclipse.in_lunar is not implemented") and not hastalent(soul_of_the_forest_talent) } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize_buff) and astralpower() >= astralpowercost(moonfire) and spell(moonfire)
 {
  #force_of_nature,if=ap_check
  if astralpower() >= astralpowercost(force_of_nature) spell(force_of_nature)

  unless { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(ca_inc_buff) and { message("interpolated_fight_remains is not implemented") < spellcooldown(convoke_the_spirits) + 7 or message("interpolated_fight_remains is not implemented") % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not message("covenant.night_fae is not implemented") } and spell(incarnation) or { message("interpolated_fight_remains is not implemented") < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(ca_inc) > 50 } and spell(kindred_spirits) or target.refreshable(stellar_flare) and target.timetodie() > 15 and enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(ca_inc_buff) > 10 or not buffpresent(ca_inc_buff) } and spell(stellar_flare)
  {
   #fury_of_elune,if=eclipse.in_any&ap_check&buff.primordial_arcanic_pulsar.value<250&(dot.adaptive_swarm_damage.ticking|!covenant.necrolord|spell_targets>2)
   if message("eclipse.in_any is not implemented") and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 250 and { target.debuffpresent(adaptive_swarm_damage_debuff) or not message("covenant.necrolord is not implemented") or enemies() > 2 } spell(fury_of_elune)

   unless not buffpresent(adaptive_swarm) and enemies() < 9 and spell(adaptive_swarm) or buffpresent(oneths_perception) and { message("buff.starfall.refreshable is not implemented") or astralpower() > 90 } and spell(starfall) or message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and message("buff.starfall.refreshable is not implemented") and spell(starfall) or message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) and spell(starsurge) or { buffpresent(oneths_clear_vision) or not message("starfire.ap_check is not implemented") or { buffremaining(ca_inc_buff) < 5 and buffpresent(ca_inc_buff) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and spell(starsurge) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and not spellknown(half_moon) and not spellknown(full_moon) and spell(new_moon) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon)
   {
    #warrior_of_elune
    spell(warrior_of_elune)

    unless { message("eclipse.lunar_next is not implemented") or message("eclipse.any_next is not implemented") and is_cleave() or message("eclipse.in_solar is not implemented") and not starfire_in_solar() or buffremaining(ca_inc_buff) < executetime(starfire) and not is_cleave() and buffremaining(ca_inc_buff) < executetime(wrath) and buffpresent(ca_inc_buff) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 or not is_cleave() and buffremaining(ca_inc_buff) > executetime(wrath) } and spell(wrath) or spell(starfire)
    {
     #run_action_list,name=fallthru
     balancefallthruactions()
    }
   }
  }
 }
}

AddFunction balanceaoeshortcdpostconditions
{
 message("buff.starfall.refreshable is not implemented") and { not message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") or timeincombat() % 45 > buffremaining(starfall) + 2 } and spell(starfall) or target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and astralpower() >= astralpowercost(sunfire) and message("eclipse.in_any is not implemented") and spell(sunfire) or target.refreshable(moonfire) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + buffremaining(moonfire) and { spellcooldown(ca_inc) == 0 or enemies() < 3 or { message("eclipse.in_solar is not implemented") or message("eclipse.in_both is not implemented") or message("eclipse.in_lunar is not implemented") and not hastalent(soul_of_the_forest_talent) } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize_buff) and astralpower() >= astralpowercost(moonfire) and spell(moonfire) or { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(ca_inc_buff) and { message("interpolated_fight_remains is not implemented") < spellcooldown(convoke_the_spirits) + 7 or message("interpolated_fight_remains is not implemented") % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not message("covenant.night_fae is not implemented") } and spell(incarnation) or { message("interpolated_fight_remains is not implemented") < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(ca_inc) > 50 } and spell(kindred_spirits) or target.refreshable(stellar_flare) and target.timetodie() > 15 and enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(ca_inc_buff) > 10 or not buffpresent(ca_inc_buff) } and spell(stellar_flare) or not buffpresent(adaptive_swarm) and enemies() < 9 and spell(adaptive_swarm) or buffpresent(oneths_perception) and { message("buff.starfall.refreshable is not implemented") or astralpower() > 90 } and spell(starfall) or message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and message("buff.starfall.refreshable is not implemented") and spell(starfall) or message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) and spell(starsurge) or { buffpresent(oneths_clear_vision) or not message("starfire.ap_check is not implemented") or { buffremaining(ca_inc_buff) < 5 and buffpresent(ca_inc_buff) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and spell(starsurge) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and not spellknown(half_moon) and not spellknown(full_moon) and spell(new_moon) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or { message("eclipse.lunar_next is not implemented") or message("eclipse.any_next is not implemented") and is_cleave() or message("eclipse.in_solar is not implemented") and not starfire_in_solar() or buffremaining(ca_inc_buff) < executetime(starfire) and not is_cleave() and buffremaining(ca_inc_buff) < executetime(wrath) and buffpresent(ca_inc_buff) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 or not is_cleave() and buffremaining(ca_inc_buff) > executetime(wrath) } and spell(wrath) or spell(starfire)
}

AddFunction balanceaoecdactions
{
 unless message("buff.starfall.refreshable is not implemented") and { not message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") or timeincombat() % 45 > buffremaining(starfall) + 2 } and spell(starfall) or target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and astralpower() >= astralpowercost(sunfire) and message("eclipse.in_any is not implemented") and spell(sunfire) or target.refreshable(moonfire) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + buffremaining(moonfire) and { spellcooldown(ca_inc) == 0 or enemies() < 3 or { message("eclipse.in_solar is not implemented") or message("eclipse.in_both is not implemented") or message("eclipse.in_lunar is not implemented") and not hastalent(soul_of_the_forest_talent) } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize_buff) and astralpower() >= astralpowercost(moonfire) and spell(moonfire) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature)
 {
  #ravenous_frenzy,if=buff.ca_inc.up
  if buffpresent(ca_inc_buff) spell(ravenous_frenzy)
  #celestial_alignment,if=(buff.starfall.up|astral_power>50)&!buff.solstice.up&!buff.ca_inc.up&(interpolated_fight_remains<cooldown.convoke_the_spirits.remains+7|interpolated_fight_remains%%180<22|cooldown.convoke_the_spirits.up|!covenant.night_fae)
  if { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(ca_inc_buff) and { message("interpolated_fight_remains is not implemented") < spellcooldown(convoke_the_spirits) + 7 or message("interpolated_fight_remains is not implemented") % 180 < 22 or not spellcooldown(convoke_the_spirits) > 0 or not message("covenant.night_fae is not implemented") } spell(celestial_alignment)

  unless { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(ca_inc_buff) and { message("interpolated_fight_remains is not implemented") < spellcooldown(convoke_the_spirits) + 7 or message("interpolated_fight_remains is not implemented") % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not message("covenant.night_fae is not implemented") } and spell(incarnation) or { message("interpolated_fight_remains is not implemented") < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(ca_inc) > 50 } and spell(kindred_spirits) or target.refreshable(stellar_flare) and target.timetodie() > 15 and enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(ca_inc_buff) > 10 or not buffpresent(ca_inc_buff) } and spell(stellar_flare)
  {
   #variable,name=convoke_condition,value=buff.primordial_arcanic_pulsar.value<250-astral_power&(cooldown.ca_inc.remains+10>interpolated_fight_remains|cooldown.ca_inc.remains+30<interpolated_fight_remains&interpolated_fight_remains>130|buff.ca_inc.remains>7)&eclipse.in_any|interpolated_fight_remains%%120<15
   #convoke_the_spirits,if=variable.convoke_condition&astral_power<50
   if convoke_condition() and astralpower() < 50 spell(convoke_the_spirits)

   unless message("eclipse.in_any is not implemented") and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 250 and { target.debuffpresent(adaptive_swarm_damage_debuff) or not message("covenant.necrolord is not implemented") or enemies() > 2 } and spell(fury_of_elune) or not buffpresent(adaptive_swarm) and enemies() < 9 and spell(adaptive_swarm) or buffpresent(oneths_perception) and { message("buff.starfall.refreshable is not implemented") or astralpower() > 90 } and spell(starfall) or message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and message("buff.starfall.refreshable is not implemented") and spell(starfall) or message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) and spell(starsurge) or { buffpresent(oneths_clear_vision) or not message("starfire.ap_check is not implemented") or { buffremaining(ca_inc_buff) < 5 and buffpresent(ca_inc_buff) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and spell(starsurge) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and not spellknown(half_moon) and not spellknown(full_moon) and spell(new_moon) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { message("eclipse.lunar_next is not implemented") or message("eclipse.any_next is not implemented") and is_cleave() or message("eclipse.in_solar is not implemented") and not starfire_in_solar() or buffremaining(ca_inc_buff) < executetime(starfire) and not is_cleave() and buffremaining(ca_inc_buff) < executetime(wrath) and buffpresent(ca_inc_buff) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 or not is_cleave() and buffremaining(ca_inc_buff) > executetime(wrath) } and spell(wrath) or spell(starfire)
   {
    #run_action_list,name=fallthru
    balancefallthruactions()
   }
  }
 }
}

AddFunction balanceaoecdpostconditions
{
 message("buff.starfall.refreshable is not implemented") and { not message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") or timeincombat() % 45 > buffremaining(starfall) + 2 } and spell(starfall) or target.refreshable(sunfire) and target.timetodie() > 14 - enemies() + buffremaining(sunfire) and astralpower() >= astralpowercost(sunfire) and message("eclipse.in_any is not implemented") and spell(sunfire) or target.refreshable(moonfire) and target.timetodie() > { 14 + enemies() * 1.5 } / enemies() + buffremaining(moonfire) and { spellcooldown(ca_inc) == 0 or enemies() < 3 or { message("eclipse.in_solar is not implemented") or message("eclipse.in_both is not implemented") or message("eclipse.in_lunar is not implemented") and not hastalent(soul_of_the_forest_talent) } and enemies() < 10 * { 1 + talentpoints(twin_moons_talent) } and astralpower() > 50 - buffremaining(starfall) * 6 } and not buffpresent(kindred_empowerment_energize_buff) and astralpower() >= astralpowercost(moonfire) and spell(moonfire) or astralpower() >= astralpowercost(force_of_nature) and spell(force_of_nature) or { buffpresent(starfall) or astralpower() > 50 } and not buffpresent(solstice_buff) and not buffpresent(ca_inc_buff) and { message("interpolated_fight_remains is not implemented") < spellcooldown(convoke_the_spirits) + 7 or message("interpolated_fight_remains is not implemented") % 180 < 32 or not spellcooldown(convoke_the_spirits) > 0 or not message("covenant.night_fae is not implemented") } and spell(incarnation) or { message("interpolated_fight_remains is not implemented") < 15 or { buffamount(primordial_arcanic_pulsar) < 250 or buffamount(primordial_arcanic_pulsar) >= 250 } and buffpresent(starfall) and spellcooldown(ca_inc) > 50 } and spell(kindred_spirits) or target.refreshable(stellar_flare) and target.timetodie() > 15 and enemies() < 4 and astralpower() >= astralpowercost(stellar_flare) and { buffremaining(ca_inc_buff) > 10 or not buffpresent(ca_inc_buff) } and spell(stellar_flare) or message("eclipse.in_any is not implemented") and astralpower() >= astralpowercost(fury_of_elune) and buffamount(primordial_arcanic_pulsar) < 250 and { target.debuffpresent(adaptive_swarm_damage_debuff) or not message("covenant.necrolord is not implemented") or enemies() > 2 } and spell(fury_of_elune) or not buffpresent(adaptive_swarm) and enemies() < 9 and spell(adaptive_swarm) or buffpresent(oneths_perception) and { message("buff.starfall.refreshable is not implemented") or astralpower() > 90 } and spell(starfall) or message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 50 } and message("buff.starfall.refreshable is not implemented") and spell(starfall) or message("covenant.night_fae is not implemented") and convoke_condition() and spellcooldown(convoke_the_spirits) < gcd() * { astralpower() / 30 } and buffpresent(starfall) and spell(starsurge) or { buffpresent(oneths_clear_vision) or not message("starfire.ap_check is not implemented") or { buffremaining(ca_inc_buff) < 5 and buffpresent(ca_inc_buff) or buffremaining(ravenous_frenzy) < gcd() * { astralpower() / 30 } and buffpresent(ravenous_frenzy) } and starfall_wont_fall_off() and enemies() < 3 } and spell(starsurge) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(new_moon) == 2 and spellchargecooldown(new_moon) < 5 or charges(new_moon) == 3 } and astralpower() >= astralpowercost(new_moon) and not spellknown(half_moon) and not spellknown(full_moon) and spell(new_moon) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(half_moon) == 2 and spellchargecooldown(half_moon) < 5 or charges(half_moon) == 3 } and astralpower() >= astralpowercost(half_moon) and spellknown(half_moon) and spell(half_moon) or { message("eclipse.in_any is not implemented") and spellcooldown(ca_inc) > 50 or charges(full_moon) == 2 and spellchargecooldown(full_moon) < 5 or charges(full_moon) == 3 } and astralpower() >= astralpowercost(full_moon) and spellknown(full_moon) and spell(full_moon) or spell(warrior_of_elune) or { message("eclipse.lunar_next is not implemented") or message("eclipse.any_next is not implemented") and is_cleave() or message("eclipse.in_solar is not implemented") and not starfire_in_solar() or buffremaining(ca_inc_buff) < executetime(starfire) and not is_cleave() and buffremaining(ca_inc_buff) < executetime(wrath) and buffpresent(ca_inc_buff) or buffpresent(ravenous_frenzy) and 100 / { 100 + spellcastspeedpercent() } > 0.6 or not is_cleave() and buffremaining(ca_inc_buff) > executetime(wrath) } and spell(wrath) or spell(starfire)
}

### actions.default

AddFunction balance_defaultmainactions
{
 #variable,name=is_aoe,value=spell_targets.starfall>1&(!talent.starlord.enabled|talent.stellar_drift.enabled)|spell_targets.starfall>2
 #variable,name=is_cleave,value=spell_targets.starfire>1
 #berserking,if=(!covenant.night_fae|!cooldown.convoke_the_spirits.up)&buff.ca_inc.up
 if { not message("covenant.night_fae is not implemented") or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(ca_inc_buff) spell(berserking)
 #run_action_list,name=aoe,if=variable.is_aoe
 if is_aoe() balanceaoemainactions()

 unless is_aoe() and balanceaoemainpostconditions()
 {
  #run_action_list,name=dreambinder,if=runeforge.timeworn_dreambinder.equipped
  if message("runeforge.timeworn_dreambinder.equipped is not implemented") balancedreambinderactions()
  #run_action_list,name=boat,if=runeforge.balance_of_all_things.equipped
  if message("runeforge.balance_of_all_things.equipped is not implemented") balanceboatactions()
  #run_action_list,name=st
  balancestactions()
 }
}

AddFunction balance_defaultmainpostconditions
{
 is_aoe() and balanceaoemainpostconditions()
}

AddFunction balance_defaultshortcdactions
{
 unless { not message("covenant.night_fae is not implemented") or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(ca_inc_buff) and spell(berserking)
 {
  #run_action_list,name=aoe,if=variable.is_aoe
  if is_aoe() balanceaoeshortcdactions()

  unless is_aoe() and balanceaoeshortcdpostconditions()
  {
   #run_action_list,name=dreambinder,if=runeforge.timeworn_dreambinder.equipped
   if message("runeforge.timeworn_dreambinder.equipped is not implemented") balancedreambinderactions()
   #run_action_list,name=boat,if=runeforge.balance_of_all_things.equipped
   if message("runeforge.balance_of_all_things.equipped is not implemented") balanceboatactions()
   #run_action_list,name=st
   balancestactions()
  }
 }
}

AddFunction balance_defaultshortcdpostconditions
{
 { not message("covenant.night_fae is not implemented") or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(ca_inc_buff) and spell(berserking) or is_aoe() and balanceaoeshortcdpostconditions()
}

AddFunction balance_defaultcdactions
{
 balanceinterruptactions()

 unless { not message("covenant.night_fae is not implemented") or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(ca_inc_buff) and spell(berserking)
 {
  #potion,if=buff.ca_inc.up
  #use_items
  balanceuseitemactions()
  #heart_essence,if=level=50
  if level() == 50 balanceuseheartessence()
  #run_action_list,name=aoe,if=variable.is_aoe
  if is_aoe() balanceaoecdactions()

  unless is_aoe() and balanceaoecdpostconditions()
  {
   #run_action_list,name=dreambinder,if=runeforge.timeworn_dreambinder.equipped
   if message("runeforge.timeworn_dreambinder.equipped is not implemented") balancedreambinderactions()
   #run_action_list,name=boat,if=runeforge.balance_of_all_things.equipped
   if message("runeforge.balance_of_all_things.equipped is not implemented") balanceboatactions()
   #run_action_list,name=st
   balancestactions()
  }
 }
}

AddFunction balance_defaultcdpostconditions
{
 { not message("covenant.night_fae is not implemented") or not { not spellcooldown(convoke_the_spirits) > 0 } } and buffpresent(ca_inc_buff) and spell(berserking) or is_aoe() and balanceaoecdpostconditions()
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
# adaptive_swarm
# adaptive_swarm_damage_debuff
# berserking
# ca_inc
# ca_inc_buff
# celestial_alignment
# concentrated_flame_essence
# convoke_the_spirits
# force_of_nature
# full_moon
# fury_of_elune
# half_moon
# incarnation
# incarnation_talent
# kindred_empowerment_energize_buff
# kindred_spirits
# mighty_bash
# moonfire
# moonkin_form
# new_moon
# oneths_clear_vision
# oneths_perception
# primordial_arcanic_pulsar
# ravenous_frenzy
# solar_beam
# solstice_buff
# soul_of_the_forest_talent
# starfall
# starfire
# starlord_talent
# starsurge
# starsurge_empowerment_buff
# stellar_drift_talent
# stellar_flare
# sunfire
# twin_moons_talent
# typhoon
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

AddCheckBox(opt_interrupt l(interrupt) default specialization=feral)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=feral)

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
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.stealth

AddFunction feralstealthmainactions
{
 #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&buff.bloodtalons.down
 if hastalent(bloodtalons_talent) and buffexpires(bloodtalons) feralbloodtalonsmainactions()

 unless hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and feralbloodtalonsmainpostconditions()
 {
  #rake,target_if=dot.rake.pmultiplier<1.6&druid.rake.ticks_gained_on_refresh>2
  if target.debuffpersistentmultiplier(rake_debuff) < 1.6 and message("druid.rake.ticks_gained_on_refresh is not implemented") > 2 spell(rake)
  #shred
  spell(shred)
 }
}

AddFunction feralstealthmainpostconditions
{
 hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and feralbloodtalonsmainpostconditions()
}

AddFunction feralstealthshortcdactions
{
 #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&buff.bloodtalons.down
 if hastalent(bloodtalons_talent) and buffexpires(bloodtalons) feralbloodtalonsshortcdactions()
}

AddFunction feralstealthshortcdpostconditions
{
 hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and feralbloodtalonsshortcdpostconditions() or target.debuffpersistentmultiplier(rake_debuff) < 1.6 and message("druid.rake.ticks_gained_on_refresh is not implemented") > 2 and spell(rake) or spell(shred)
}

AddFunction feralstealthcdactions
{
 #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&buff.bloodtalons.down
 if hastalent(bloodtalons_talent) and buffexpires(bloodtalons) feralbloodtalonscdactions()
}

AddFunction feralstealthcdpostconditions
{
 hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and feralbloodtalonscdpostconditions() or target.debuffpersistentmultiplier(rake_debuff) < 1.6 and message("druid.rake.ticks_gained_on_refresh is not implemented") > 2 and spell(rake) or spell(shred)
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
 #savage_roar,if=refreshable
 if target.refreshable(savage_roar) spell(savage_roar)
 #variable,name=best_rip,value=0,if=talent.primal_wrath.enabled
 #cycling_variable,name=best_rip,op=max,value=druid.rip.ticks_gained_on_refresh,if=talent.primal_wrath.enabled
 #primal_wrath,if=druid.primal_wrath.ticks_gained_on_refresh>(variable.rip_ticks>?variable.best_rip)|spell_targets.primal_wrath>(3+1*talent.sabertooth.enabled)
 if message("druid.primal_wrath.ticks_gained_on_refresh is not implemented") > rip_ticks() >? best_rip() or enemies() > 3 + 1 * talentpoints(sabertooth_talent) spell(primal_wrath)
 #rip,target_if=(!ticking|(remains+combo_points*talent.sabertooth.enabled)<duration*0.3|dot.rip.pmultiplier<persistent_multiplier)&druid.rip.ticks_gained_on_refresh>variable.rip_ticks
 if { not buffpresent(rip) or buffremaining(rip) + combopoints() * talentpoints(sabertooth_talent) < baseduration(rip) * 0.3 or target.debuffpersistentmultiplier(rip) < persistentmultiplier(rip) } and message("druid.rip.ticks_gained_on_refresh is not implemented") > rip_ticks() spell(rip)
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
 target.refreshable(savage_roar) and spell(savage_roar) or { message("druid.primal_wrath.ticks_gained_on_refresh is not implemented") > rip_ticks() >? best_rip() or enemies() > 3 + 1 * talentpoints(sabertooth_talent) } and spell(primal_wrath) or { not buffpresent(rip) or buffremaining(rip) + combopoints() * talentpoints(sabertooth_talent) < baseduration(rip) * 0.3 or target.debuffpersistentmultiplier(rip) < persistentmultiplier(rip) } and message("druid.rip.ticks_gained_on_refresh is not implemented") > rip_ticks() and spell(rip) or buffpresent(iron_jaws) and spell(maim) or energy() >= energycost(ferocious_bite max=1) and spell(ferocious_bite)
}

AddFunction feralfinishercdactions
{
}

AddFunction feralfinishercdpostconditions
{
 target.refreshable(savage_roar) and spell(savage_roar) or { message("druid.primal_wrath.ticks_gained_on_refresh is not implemented") > rip_ticks() >? best_rip() or enemies() > 3 + 1 * talentpoints(sabertooth_talent) } and spell(primal_wrath) or { not buffpresent(rip) or buffremaining(rip) + combopoints() * talentpoints(sabertooth_talent) < baseduration(rip) * 0.3 or target.debuffpersistentmultiplier(rip) < persistentmultiplier(rip) } and message("druid.rip.ticks_gained_on_refresh is not implemented") > rip_ticks() and spell(rip) or buffpresent(iron_jaws) and spell(maim) or energy() >= energycost(ferocious_bite max=1) and spell(ferocious_bite)
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
 if enemies() > message("desired_targets is not implemented") or 600 > 45 spell(thorns)
 #the_unbound_force,if=buff.reckless_force.up|buff.tigers_fury.up
 if buffpresent(reckless_force_buff) or buffpresent(tigers_fury) spell(the_unbound_force)
 #memory_of_lucid_dreams,if=buff.berserk_cat.up|buff.incarnation_king_of_the_jungle.up
 if buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) spell(memory_of_lucid_dreams)
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
 unless { enemies() > message("desired_targets is not implemented") or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury) } and spell(the_unbound_force) or { buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) } and spell(memory_of_lucid_dreams) or buffpresent(tigers_fury) and combopoints() == 5 and spell(blood_of_the_enemy)
 {
  #focused_azerite_beam,if=active_enemies>desired_targets|(raid_event.adds.in>90&energy.deficit>=50)
  if enemies() > message("desired_targets is not implemented") or 600 > 90 and energydeficit() >= 50 spell(focused_azerite_beam)
  #purifying_blast,if=active_enemies>desired_targets|raid_event.adds.in>60
  if enemies() > message("desired_targets is not implemented") or 600 > 60 spell(purifying_blast)

  unless buffpresent(tigers_fury) and spell(concentrated_flame) or buffpresent(tigers_fury) and spell(ripple_in_space) or buffpresent(tigers_fury) and spell(worldvein_resonance)
  {
   #reaping_flames,target_if=target.time_to_die<1.5|((target.health.pct>80|target.health.pct<=20)&variable.reaping_delay>29)|(target.time_to_pct_20>30&variable.reaping_delay>44)
   if target.timetodie() < 1.5 or { target.healthpercent() > 80 or target.healthpercent() <= 20 } and reaping_delay() > 29 or target.timetohealthpercent(20) > 30 and reaping_delay() > 44 spell(reaping_flames)
  }
 }
}

AddFunction feralessenceshortcdpostconditions
{
 { enemies() > message("desired_targets is not implemented") or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury) } and spell(the_unbound_force) or { buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) } and spell(memory_of_lucid_dreams) or buffpresent(tigers_fury) and combopoints() == 5 and spell(blood_of_the_enemy) or buffpresent(tigers_fury) and spell(concentrated_flame) or buffpresent(tigers_fury) and spell(ripple_in_space) or buffpresent(tigers_fury) and spell(worldvein_resonance)
}

AddFunction feralessencecdactions
{
 unless { enemies() > message("desired_targets is not implemented") or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury) } and spell(the_unbound_force) or { buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) } and spell(memory_of_lucid_dreams) or buffpresent(tigers_fury) and combopoints() == 5 and spell(blood_of_the_enemy) or { enemies() > message("desired_targets is not implemented") or 600 > 90 and energydeficit() >= 50 } and spell(focused_azerite_beam) or { enemies() > message("desired_targets is not implemented") or 600 > 60 } and spell(purifying_blast)
 {
  #guardian_of_azeroth,if=buff.tigers_fury.up
  if buffpresent(tigers_fury) spell(guardian_of_azeroth)
 }
}

AddFunction feralessencecdpostconditions
{
 { enemies() > message("desired_targets is not implemented") or 600 > 45 } and spell(thorns) or { buffpresent(reckless_force_buff) or buffpresent(tigers_fury) } and spell(the_unbound_force) or { buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) } and spell(memory_of_lucid_dreams) or buffpresent(tigers_fury) and combopoints() == 5 and spell(blood_of_the_enemy) or { enemies() > message("desired_targets is not implemented") or 600 > 90 and energydeficit() >= 50 } and spell(focused_azerite_beam) or { enemies() > message("desired_targets is not implemented") or 600 > 60 } and spell(purifying_blast) or buffpresent(tigers_fury) and spell(concentrated_flame) or buffpresent(tigers_fury) and spell(ripple_in_space) or buffpresent(tigers_fury) and spell(worldvein_resonance) or { target.timetodie() < 1.5 or { target.healthpercent() > 80 or target.healthpercent() <= 20 } and reaping_delay() > 29 or target.timetohealthpercent(20) > 30 and reaping_delay() > 44 } and spell(reaping_flames)
}

### actions.cooldown

AddFunction feralcooldownmainactions
{
 #incarnation,if=buff.prowl.down
 if buffexpires(prowl) spell(incarnation)
 #berserking,if=buff.tigers_fury.up|buff.berserk_cat.up|buff.incarnation_king_of_the_jungle.up
 if buffpresent(tigers_fury) or buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) spell(berserking)
 #potion,if=buff.berserk_cat.up|buff.incarnation_king_of_the_jungle.up
 #call_action_list,name=essence
 feralessencemainactions()
}

AddFunction feralcooldownmainpostconditions
{
 feralessencemainpostconditions()
}

AddFunction feralcooldownshortcdactions
{
 unless buffexpires(prowl) and spell(incarnation)
 {
  #tigers_fury,if=energy.deficit>55|buff.berserk_cat.remains<13|buff.incarnation_king_of_the_jungle.remains<13
  if energydeficit() > 55 or buffremaining(berserk_cat_buff) < 13 or buffremaining(incarnation_king_of_the_jungle) < 13 spell(tigers_fury)

  unless { buffpresent(tigers_fury) or buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) } and spell(berserking)
  {
   #potion,if=buff.berserk_cat.up|buff.incarnation_king_of_the_jungle.up
   #call_action_list,name=essence
   feralessenceshortcdactions()
  }
 }
}

AddFunction feralcooldownshortcdpostconditions
{
 buffexpires(prowl) and spell(incarnation) or { buffpresent(tigers_fury) or buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) } and spell(berserking) or feralessenceshortcdpostconditions()
}

AddFunction feralcooldowncdactions
{
 #berserk,if=buff.prowl.down
 if buffexpires(prowl) spell(berserk)

 unless buffexpires(prowl) and spell(incarnation) or { energydeficit() > 55 or buffremaining(berserk_cat_buff) < 13 or buffremaining(incarnation_king_of_the_jungle) < 13 } and spell(tigers_fury)
 {
  #shadowmeld,if=buff.tigers_fury.up&buff.berserk_cat.down&buff.incarnation_king_of_the_jungle.down&buff.prowl.down&combo_points<4&dot.rake.pmultiplier<1.6&energy>40
  if buffpresent(tigers_fury) and buffexpires(berserk_cat_buff) and buffexpires(incarnation_king_of_the_jungle) and buffexpires(prowl) and combopoints() < 4 and target.debuffpersistentmultiplier(rake_debuff) < 1.6 and energy() > 40 spell(shadowmeld)

  unless { buffpresent(tigers_fury) or buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) } and spell(berserking)
  {
   #potion,if=buff.berserk_cat.up|buff.incarnation_king_of_the_jungle.up
   #call_action_list,name=essence
   feralessencecdactions()

   unless feralessencecdpostconditions()
   {
    #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.time_to_pct_30<1.5|!debuff.conductive_ink_debuff.up&(debuff.razor_coral_debuff.stack>=25-10*debuff.blood_of_the_enemy.up|target.time_to_die<40)&buff.tigers_fury.remains>10
    if target.debuffexpires(razor_coral) or target.debuffpresent(conductive_ink_debuff) and target.timetohealthpercent(30) < 1.5 or not target.debuffpresent(conductive_ink_debuff) and { target.debuffstacks(razor_coral) >= 25 - 10 * target.debuffpresent(blood_of_the_enemy) or target.timetodie() < 40 } and buffremaining(tigers_fury) > 10 feraluseitemactions()
    #use_items,if=buff.tigers_fury.up|target.time_to_die<20
    if buffpresent(tigers_fury) or target.timetodie() < 20 feraluseitemactions()
   }
  }
 }
}

AddFunction feralcooldowncdpostconditions
{
 buffexpires(prowl) and spell(incarnation) or { energydeficit() > 55 or buffremaining(berserk_cat_buff) < 13 or buffremaining(incarnation_king_of_the_jungle) < 13 } and spell(tigers_fury) or { buffpresent(tigers_fury) or buffpresent(berserk_cat_buff) or buffpresent(incarnation_king_of_the_jungle) } and spell(berserking) or feralessencecdpostconditions()
}

### actions.bloodtalons

AddFunction feralbloodtalonsmainactions
{
 #rake,target_if=(!ticking|(refreshable&persistent_multiplier>dot.rake.pmultiplier))&buff.bt_rake.down&druid.rake.ticks_gained_on_refresh>=2
 if { not target.debuffpresent(rake_debuff) or target.refreshable(rake_debuff) and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and buffexpires(bt_rake_buff) and message("druid.rake.ticks_gained_on_refresh is not implemented") >= 2 spell(rake)
 #lunar_inspiration,target_if=refreshable&buff.bt_moonfire.down
 if target.refreshable(lunar_inspiration) and buffexpires(bt_moonfire_buff) spell(lunar_inspiration)
 #thrash_cat,target_if=refreshable&buff.bt_thrash.down&druid.thrash_cat.ticks_gained_on_refresh>8
 if target.refreshable(thrash_cat_debuff) and buffexpires(bt_thrash_buff) and message("druid.thrash_cat.ticks_gained_on_refresh is not implemented") > 8 spell(thrash_cat)
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
 { not target.debuffpresent(rake_debuff) or target.refreshable(rake_debuff) and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and buffexpires(bt_rake_buff) and message("druid.rake.ticks_gained_on_refresh is not implemented") >= 2 and spell(rake) or target.refreshable(lunar_inspiration) and buffexpires(bt_moonfire_buff) and spell(lunar_inspiration) or target.refreshable(thrash_cat_debuff) and buffexpires(bt_thrash_buff) and message("druid.thrash_cat.ticks_gained_on_refresh is not implemented") > 8 and spell(thrash_cat) or buffexpires(bt_brutal_slash_buff) and spell(brutal_slash) or buffexpires(bt_swipe_buff) and enemies() > 1 and spell(swipe_cat) or buffexpires(bt_shred_buff) and spell(shred) or buffexpires(bt_swipe_buff) and spell(swipe_cat) or buffexpires(bt_thrash_buff) and spell(thrash_cat)
}

AddFunction feralbloodtalonscdactions
{
}

AddFunction feralbloodtalonscdpostconditions
{
 { not target.debuffpresent(rake_debuff) or target.refreshable(rake_debuff) and persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and buffexpires(bt_rake_buff) and message("druid.rake.ticks_gained_on_refresh is not implemented") >= 2 and spell(rake) or target.refreshable(lunar_inspiration) and buffexpires(bt_moonfire_buff) and spell(lunar_inspiration) or target.refreshable(thrash_cat_debuff) and buffexpires(bt_thrash_buff) and message("druid.thrash_cat.ticks_gained_on_refresh is not implemented") > 8 and spell(thrash_cat) or buffexpires(bt_brutal_slash_buff) and spell(brutal_slash) or buffexpires(bt_swipe_buff) and enemies() > 1 and spell(swipe_cat) or buffexpires(bt_shred_buff) and spell(shred) or buffexpires(bt_swipe_buff) and spell(swipe_cat) or buffexpires(bt_thrash_buff) and spell(thrash_cat)
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
 #call_action_list,name=cooldown
 feralcooldownmainactions()

 unless feralcooldownmainpostconditions()
 {
  #run_action_list,name=finisher,if=combo_points>=(5-variable.4cp_bite)
  if combopoints() >= 5 - 4cp_bite() feralfinishermainactions()

  unless combopoints() >= 5 - 4cp_bite() and feralfinishermainpostconditions()
  {
   #run_action_list,name=stealth,if=buff.berserk_cat.up|buff.incarnation.up|buff.shadowmeld.up|buff.sudden_ambush.up|buff.prowl.up
   if buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) feralstealthmainactions()

   unless { buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) } and feralstealthmainpostconditions()
   {
    #pool_resource,if=talent.bloodtalons.enabled&buff.bloodtalons.down&(energy+3.5*energy.regen+(40*buff.clearcasting.up))>=(115-23*buff.incarnation_king_of_the_jungle.up)&active_bt_triggers=0
    unless hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and energy() + 3.5 * energy() + 40 * buffpresent(clearcasting) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and message("active_bt_triggers is not implemented") == 0
    {
     #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&(buff.bloodtalons.down|active_bt_triggers=2)
     if hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } feralbloodtalonsmainactions()

     unless hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } and feralbloodtalonsmainpostconditions()
     {
      #rake,target_if=refreshable|persistent_multiplier>dot.rake.pmultiplier
      if target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) spell(rake)
      #moonfire_cat,target_if=refreshable
      if target.refreshable(moonfire_cat_debuff) spell(moonfire_cat)
      #thrash_cat,if=refreshable&druid.thrash_cat.ticks_gained_on_refresh>variable.thrash_ticks
      if target.refreshable(thrash_cat_debuff) and message("druid.thrash_cat.ticks_gained_on_refresh is not implemented") > thrash_ticks() spell(thrash_cat)
      #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))&(spell_targets.brutal_slash*action.brutal_slash.damage%action.brutal_slash.cost)>(action.shred.damage%action.shred.cost)
      if buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) spell(brutal_slash)
      #swipe_cat,if=spell_targets.swipe_cat>2
      if enemies() > 2 spell(swipe_cat)
      #shred,if=buff.clearcasting.up
      if buffpresent(clearcasting) spell(shred)
      #call_action_list,name=filler,if=energy.time_to_max<1
      if energy() < 1 feralfillermainactions()
     }
    }
   }
  }
 }
}

AddFunction feral_defaultmainpostconditions
{
 feralcooldownmainpostconditions() or combopoints() >= 5 - 4cp_bite() and feralfinishermainpostconditions() or { buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) } and feralstealthmainpostconditions() or not { hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and energy() + 3.5 * energy() + 40 * buffpresent(clearcasting) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and message("active_bt_triggers is not implemented") == 0 } and { hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } and feralbloodtalonsmainpostconditions() or energy() < 1 and feralfillermainpostconditions() }
}

AddFunction feral_defaultshortcdactions
{
 unless buffexpires(cat_form) and spell(cat_form) or spell(prowl)
 {
  #auto_attack,if=!buff.prowl.up&!buff.shadowmeld.up
  if not buffpresent(prowl) and not buffpresent(shadowmeld) feralgetinmeleerange()
  #variable,name=reaping_delay,value=target.time_to_die,if=variable.reaping_delay=0
  #cycling_variable,name=reaping_delay,op=min,value=target.time_to_die
  #call_action_list,name=cooldown
  feralcooldownshortcdactions()

  unless feralcooldownshortcdpostconditions()
  {
   #run_action_list,name=finisher,if=combo_points>=(5-variable.4cp_bite)
   if combopoints() >= 5 - 4cp_bite() feralfinishershortcdactions()

   unless combopoints() >= 5 - 4cp_bite() and feralfinishershortcdpostconditions()
   {
    #run_action_list,name=stealth,if=buff.berserk_cat.up|buff.incarnation.up|buff.shadowmeld.up|buff.sudden_ambush.up|buff.prowl.up
    if buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) feralstealthshortcdactions()

    unless { buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) } and feralstealthshortcdpostconditions()
    {
     #pool_resource,if=talent.bloodtalons.enabled&buff.bloodtalons.down&(energy+3.5*energy.regen+(40*buff.clearcasting.up))>=(115-23*buff.incarnation_king_of_the_jungle.up)&active_bt_triggers=0
     unless hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and energy() + 3.5 * energy() + 40 * buffpresent(clearcasting) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and message("active_bt_triggers is not implemented") == 0
     {
      #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&(buff.bloodtalons.down|active_bt_triggers=2)
      if hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } feralbloodtalonsshortcdactions()

      unless hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } and feralbloodtalonsshortcdpostconditions() or { target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and spell(rake)
      {
       #feral_frenzy,if=combo_points=0
       if combopoints() == 0 spell(feral_frenzy)

       unless target.refreshable(moonfire_cat_debuff) and spell(moonfire_cat) or target.refreshable(thrash_cat_debuff) and message("druid.thrash_cat.ticks_gained_on_refresh is not implemented") > thrash_ticks() and spell(thrash_cat) or buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) and spell(brutal_slash) or enemies() > 2 and spell(swipe_cat) or buffpresent(clearcasting) and spell(shred)
       {
        #call_action_list,name=filler,if=energy.time_to_max<1
        if energy() < 1 feralfillershortcdactions()
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
 buffexpires(cat_form) and spell(cat_form) or spell(prowl) or feralcooldownshortcdpostconditions() or combopoints() >= 5 - 4cp_bite() and feralfinishershortcdpostconditions() or { buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) } and feralstealthshortcdpostconditions() or not { hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and energy() + 3.5 * energy() + 40 * buffpresent(clearcasting) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and message("active_bt_triggers is not implemented") == 0 } and { hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } and feralbloodtalonsshortcdpostconditions() or { target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and spell(rake) or target.refreshable(moonfire_cat_debuff) and spell(moonfire_cat) or target.refreshable(thrash_cat_debuff) and message("druid.thrash_cat.ticks_gained_on_refresh is not implemented") > thrash_ticks() and spell(thrash_cat) or buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) and spell(brutal_slash) or enemies() > 2 and spell(swipe_cat) or buffpresent(clearcasting) and spell(shred) or energy() < 1 and feralfillershortcdpostconditions() }
}

AddFunction feral_defaultcdactions
{
 feralinterruptactions()

 unless buffexpires(cat_form) and spell(cat_form) or spell(prowl)
 {
  #variable,name=reaping_delay,value=target.time_to_die,if=variable.reaping_delay=0
  #cycling_variable,name=reaping_delay,op=min,value=target.time_to_die
  #call_action_list,name=cooldown
  feralcooldowncdactions()

  unless feralcooldowncdpostconditions()
  {
   #run_action_list,name=finisher,if=combo_points>=(5-variable.4cp_bite)
   if combopoints() >= 5 - 4cp_bite() feralfinishercdactions()

   unless combopoints() >= 5 - 4cp_bite() and feralfinishercdpostconditions()
   {
    #run_action_list,name=stealth,if=buff.berserk_cat.up|buff.incarnation.up|buff.shadowmeld.up|buff.sudden_ambush.up|buff.prowl.up
    if buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) feralstealthcdactions()

    unless { buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) } and feralstealthcdpostconditions()
    {
     #pool_resource,if=talent.bloodtalons.enabled&buff.bloodtalons.down&(energy+3.5*energy.regen+(40*buff.clearcasting.up))>=(115-23*buff.incarnation_king_of_the_jungle.up)&active_bt_triggers=0
     unless hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and energy() + 3.5 * energy() + 40 * buffpresent(clearcasting) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and message("active_bt_triggers is not implemented") == 0
     {
      #run_action_list,name=bloodtalons,if=talent.bloodtalons.enabled&(buff.bloodtalons.down|active_bt_triggers=2)
      if hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } feralbloodtalonscdactions()

      unless hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } and feralbloodtalonscdpostconditions() or { target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and spell(rake) or combopoints() == 0 and spell(feral_frenzy) or target.refreshable(moonfire_cat_debuff) and spell(moonfire_cat) or target.refreshable(thrash_cat_debuff) and message("druid.thrash_cat.ticks_gained_on_refresh is not implemented") > thrash_ticks() and spell(thrash_cat) or buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) and spell(brutal_slash) or enemies() > 2 and spell(swipe_cat) or buffpresent(clearcasting) and spell(shred)
      {
       #call_action_list,name=filler,if=energy.time_to_max<1
       if energy() < 1 feralfillercdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction feral_defaultcdpostconditions
{
 buffexpires(cat_form) and spell(cat_form) or spell(prowl) or feralcooldowncdpostconditions() or combopoints() >= 5 - 4cp_bite() and feralfinishercdpostconditions() or { buffpresent(berserk_cat_buff) or buffpresent(incarnation) or buffpresent(shadowmeld) or buffpresent(sudden_ambush_buff) or buffpresent(prowl) } and feralstealthcdpostconditions() or not { hastalent(bloodtalons_talent) and buffexpires(bloodtalons) and energy() + 3.5 * energy() + 40 * buffpresent(clearcasting) >= 115 - 23 * buffpresent(incarnation_king_of_the_jungle) and message("active_bt_triggers is not implemented") == 0 } and { hastalent(bloodtalons_talent) and { buffexpires(bloodtalons) or message("active_bt_triggers is not implemented") == 2 } and feralbloodtalonscdpostconditions() or { target.refreshable(rake_debuff) or persistentmultiplier(rake_debuff) > target.debuffpersistentmultiplier(rake_debuff) } and spell(rake) or combopoints() == 0 and spell(feral_frenzy) or target.refreshable(moonfire_cat_debuff) and spell(moonfire_cat) or target.refreshable(thrash_cat_debuff) and message("druid.thrash_cat.ticks_gained_on_refresh is not implemented") > thrash_ticks() and spell(thrash_cat) or buffpresent(tigers_fury) and 600 > { 1 + spellmaxcharges(brutal_slash) - charges(brutal_slash count=0) } * spellchargecooldown(brutal_slash) and enemies() * damage(brutal_slash) / powercost(brutal_slash) > damage(shred) / powercost(shred) and spell(brutal_slash) or enemies() > 2 and spell(swipe_cat) or buffpresent(clearcasting) and spell(shred) or energy() < 1 and feralfillercdpostconditions() }
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
# berserk_cat_buff
# berserking
# blood_of_the_enemy
# bloodtalons
# bloodtalons_talent
# brutal_slash
# bt_brutal_slash_buff
# bt_moonfire_buff
# bt_rake_buff
# bt_shred_buff
# bt_swipe_buff
# bt_thrash_buff
# cat_form
# clearcasting
# concentrated_flame
# conductive_ink_debuff
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
# moonfire_cat_debuff
# primal_wrath
# primal_wrath_talent
# prowl
# purifying_blast
# rake
# rake_debuff
# razor_coral
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
# swipe
# swipe_cat
# the_unbound_force
# thorns
# thrash_cat
# thrash_cat_debuff
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

AddCheckBox(opt_interrupt l(interrupt) default specialization=guardian)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=guardian)

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
 #flask
 #food
 #augmentation
 #snapshot_stats
 #cat_form,if=druid.catweave_bear&talent.feral_affinity.enabled
 if message("druid.catweave_bear is not implemented") and hastalent(feral_affinity_talent_guardian) spell(cat_form)
 #prowl,if=druid.catweave_bear&talent.feral_affinity.enabled
 if message("druid.catweave_bear is not implemented") and hastalent(feral_affinity_talent_guardian) spell(prowl)
 #moonkin_form,if=druid.owlweave_bear&talent.balance_affinity.enabled
 if message("druid.owlweave_bear is not implemented") and hastalent(balance_affinity_talent) spell(moonkin_form)
 #bear_form,if=!druid.catweave_bear&!druid.owlweave_bear
 if not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") spell(bear_form)
 #wrath,if=druid.owlweave_bear
 if message("druid.owlweave_bear is not implemented") spell(wrath)
}

AddFunction guardianprecombatmainpostconditions
{
}

AddFunction guardianprecombatshortcdactions
{
}

AddFunction guardianprecombatshortcdpostconditions
{
 message("druid.catweave_bear is not implemented") and hastalent(feral_affinity_talent_guardian) and spell(cat_form) or message("druid.catweave_bear is not implemented") and hastalent(feral_affinity_talent_guardian) and spell(prowl) or message("druid.owlweave_bear is not implemented") and hastalent(balance_affinity_talent) and spell(moonkin_form) or not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") and spell(bear_form) or message("druid.owlweave_bear is not implemented") and spell(wrath)
}

AddFunction guardianprecombatcdactions
{
 unless message("druid.catweave_bear is not implemented") and hastalent(feral_affinity_talent_guardian) and spell(cat_form) or message("druid.catweave_bear is not implemented") and hastalent(feral_affinity_talent_guardian) and spell(prowl) or message("druid.owlweave_bear is not implemented") and hastalent(balance_affinity_talent) and spell(moonkin_form) or not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") and spell(bear_form)
 {
  #heart_of_the_Wild,if=talent.heart_of_the_wild.enabled&druid.owlweave_bear
  if hastalent(heart_of_the_wild_talent) and message("druid.owlweave_bear is not implemented") spell(heart_of_the_wild)
 }
}

AddFunction guardianprecombatcdpostconditions
{
 message("druid.catweave_bear is not implemented") and hastalent(feral_affinity_talent_guardian) and spell(cat_form) or message("druid.catweave_bear is not implemented") and hastalent(feral_affinity_talent_guardian) and spell(prowl) or message("druid.owlweave_bear is not implemented") and hastalent(balance_affinity_talent) and spell(moonkin_form) or not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") and spell(bear_form) or message("druid.owlweave_bear is not implemented") and spell(wrath)
}

### actions.owlweave

AddFunction guardianowlweavemainactions
{
 #moonkin_form,if=!buff.moonkin_form.up
 if not buffpresent(moonkin_form) spell(moonkin_form)
 #adaptive_swarm,target_if=refreshable
 if target.refreshable(adaptive_swarm) spell(adaptive_swarm)
 #moonfire,target_if=refreshable|buff.galactic_guardian.up
 if target.refreshable(moonfire) or buffpresent(galactic_guardian) spell(moonfire)
 #sunfire,target_if=refreshable
 if target.refreshable(sunfire) spell(sunfire)
 #starsurge,if=(buff.eclipse_lunar.up|buff.eclipse_solar.up)
 if buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) spell(starsurge)
 #starfire,if=(eclipse.in_lunar|eclipse.solar_next)|(eclipse.in_lunar&buff.starsurge_empowerment.up)
 if message("eclipse.in_lunar is not implemented") or message("eclipse.solar_next is not implemented") or message("eclipse.in_lunar is not implemented") and buffpresent(starsurge_empowerment_buff) spell(starfire)
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
  if message("druid.owlweave_bear is not implemented") spell(empower_bond)
 }
}

AddFunction guardianowlweaveshortcdpostconditions
{
 not buffpresent(moonkin_form) and spell(moonkin_form) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or { target.refreshable(moonfire) or buffpresent(galactic_guardian) } and spell(moonfire) or target.refreshable(sunfire) and spell(sunfire) or { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and spell(starsurge) or { message("eclipse.in_lunar is not implemented") or message("eclipse.solar_next is not implemented") or message("eclipse.in_lunar is not implemented") and buffpresent(starsurge_empowerment_buff) } and spell(starfire) or spell(wrath)
}

AddFunction guardianowlweavecdactions
{
 unless not buffpresent(moonkin_form) and spell(moonkin_form)
 {
  #heart_of_the_wild,if=talent.heart_of_the_wild.enabled&!buff.heart_of_the_wild.up
  if hastalent(heart_of_the_wild_talent) and not buffpresent(heart_of_the_wild) spell(heart_of_the_wild)

  unless message("druid.owlweave_bear is not implemented") and spell(empower_bond)
  {
   #convoke_the_spirits,if=druid.owlweave_bear
   if message("druid.owlweave_bear is not implemented") spell(convoke_the_spirits)
  }
 }
}

AddFunction guardianowlweavecdpostconditions
{
 not buffpresent(moonkin_form) and spell(moonkin_form) or message("druid.owlweave_bear is not implemented") and spell(empower_bond) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or { target.refreshable(moonfire) or buffpresent(galactic_guardian) } and spell(moonfire) or target.refreshable(sunfire) and spell(sunfire) or { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and spell(starsurge) or { message("eclipse.in_lunar is not implemented") or message("eclipse.solar_next is not implemented") or message("eclipse.in_lunar is not implemented") and buffpresent(starsurge_empowerment_buff) } and spell(starfire) or spell(wrath)
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
  if message("druid.catweave_bear is not implemented") spell(empower_bond)
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

  unless message("druid.catweave_bear is not implemented") and spell(empower_bond)
  {
   #convoke_the_spirits,if=druid.catweave_bear
   if message("druid.catweave_bear is not implemented") spell(convoke_the_spirits)
  }
 }
}

AddFunction guardiancatweavecdpostconditions
{
 not buffpresent(cat_form) and spell(cat_form) or buffpresent(prowl) and spell(rake) or message("druid.catweave_bear is not implemented") and spell(empower_bond) or target.debuffrefreshable(rip) and combopoints() >= 4 and spell(rip) or combopoints() >= 4 and spell(ferocious_bite) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or target.debuffrefreshable(rake_debuff) and combopoints() < 4 and spell(rake) or spell(shred)
}

### actions.bear

AddFunction guardianbearmainactions
{
 #bear_form,if=!buff.bear_form.up
 if not buffpresent(bear_form) spell(bear_form)
 #berserk_bear,if=(buff.ravenous_frenzy.up|!covenant.venthyr)
 if buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") spell(berserk_bear)
 #incarnation,if=(buff.ravenous_frenzy.up|!covenant.venthyr)
 if buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") spell(incarnation)
 #ironfur,if=buff.ironfur.remains<0.5
 if buffremaining(ironfur) < 0.5 spell(ironfur)
 #adaptive_swarm,target_if=refreshable
 if target.refreshable(adaptive_swarm) spell(adaptive_swarm)
 #moonfire,if=(buff.galactic_guardian.up&druid.owlweave_bear)&active_enemies<=3
 if buffpresent(galactic_guardian) and message("druid.owlweave_bear is not implemented") and enemies() <= 3 spell(moonfire)
 #thrash_bear,target_if=refreshable|dot.thrash_bear.stack<3|(dot.thrash_bear.stack<4&runeforge.luffainfused_embrace.equipped)|active_enemies>5
 if target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and message("runeforge.luffainfused_embrace.equipped is not implemented") or enemies() > 5 spell(thrash_bear)
 #swipe,if=buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&active_enemies>=4
 if buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and enemies() >= 4 spell(swipe)
 #maul,if=buff.incarnation.up&active_enemies<2
 if buffpresent(incarnation) and enemies() < 2 spell(maul)
 #maul,if=(buff.savage_combatant.stack>=1)&(buff.tooth_and_claw.up)&buff.incarnation.up&active_enemies=2
 if buffstacks(savage_combatant_buff) >= 1 and buffpresent(tooth_and_claw_buff) and buffpresent(incarnation) and enemies() == 2 spell(maul)
 #mangle,if=buff.incarnation.up&active_enemies<=3
 if buffpresent(incarnation) and enemies() <= 3 spell(mangle)
 #moonfire,target_if=refreshable&active_enemies<=3
 if target.refreshable(moonfire) and enemies() <= 3 spell(moonfire)
 #maul,if=(buff.tooth_and_claw.stack>=2)|(buff.tooth_and_claw.up&buff.tooth_and_claw.remains<1.5)|(buff.savage_combatant.stack>=3)
 if buffstacks(tooth_and_claw_buff) >= 2 or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 or buffstacks(savage_combatant_buff) >= 3 spell(maul)
 #thrash_bear,if=active_enemies>1
 if enemies() > 1 spell(thrash_bear)
 #moonfire,if=(buff.galactic_guardian.up&druid.catweave_bear)&active_enemies<=3|(buff.galactic_guardian.up&!druid.catweave_bear&!druid.owlweave_bear)&active_enemies<=3
 if buffpresent(galactic_guardian) and message("druid.catweave_bear is not implemented") and enemies() <= 3 or buffpresent(galactic_guardian) and not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") and enemies() <= 3 spell(moonfire)
 #mangle,if=(rage<80)&active_enemies<4
 if rage() < 80 and enemies() < 4 spell(mangle)
 #thrash_bear
 spell(thrash_bear)
 #maul
 spell(maul)
 #swipe_bear
 spell(swipe_bear)
}

AddFunction guardianbearmainpostconditions
{
}

AddFunction guardianbearshortcdactions
{
 unless not buffpresent(bear_form) and spell(bear_form) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(berserk_bear) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(incarnation)
 {
  #empower_bond,if=(!druid.catweave_bear&!druid.owlweave_bear)|active_enemies>=2
  if not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") or enemies() >= 2 spell(empower_bond)
  #barkskin,if=(talent.brambles.enabled)&(buff.bear_form.up)
  if hastalent(brambles_talent) and buffpresent(bear_form) spell(barkskin)

  unless buffremaining(ironfur) < 0.5 and spell(ironfur) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or buffpresent(galactic_guardian) and message("druid.owlweave_bear is not implemented") and enemies() <= 3 and spell(moonfire) or { target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and message("runeforge.luffainfused_embrace.equipped is not implemented") or enemies() > 5 } and spell(thrash_bear) or buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and enemies() >= 4 and spell(swipe) or buffpresent(incarnation) and enemies() < 2 and spell(maul) or buffstacks(savage_combatant_buff) >= 1 and buffpresent(tooth_and_claw_buff) and buffpresent(incarnation) and enemies() == 2 and spell(maul) or buffpresent(incarnation) and enemies() <= 3 and spell(mangle) or target.refreshable(moonfire) and enemies() <= 3 and spell(moonfire) or { buffstacks(tooth_and_claw_buff) >= 2 or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 or buffstacks(savage_combatant_buff) >= 3 } and spell(maul) or enemies() > 1 and spell(thrash_bear) or { buffpresent(galactic_guardian) and message("druid.catweave_bear is not implemented") and enemies() <= 3 or buffpresent(galactic_guardian) and not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") and enemies() <= 3 } and spell(moonfire) or rage() < 80 and enemies() < 4 and spell(mangle)
  {
   #pulverize,target_if=dot.thrash_bear.stack>2
   if target.debuffstacks(thrash_bear_debuff) > 2 and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) spell(pulverize)
  }
 }
}

AddFunction guardianbearshortcdpostconditions
{
 not buffpresent(bear_form) and spell(bear_form) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(berserk_bear) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(incarnation) or buffremaining(ironfur) < 0.5 and spell(ironfur) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or buffpresent(galactic_guardian) and message("druid.owlweave_bear is not implemented") and enemies() <= 3 and spell(moonfire) or { target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and message("runeforge.luffainfused_embrace.equipped is not implemented") or enemies() > 5 } and spell(thrash_bear) or buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and enemies() >= 4 and spell(swipe) or buffpresent(incarnation) and enemies() < 2 and spell(maul) or buffstacks(savage_combatant_buff) >= 1 and buffpresent(tooth_and_claw_buff) and buffpresent(incarnation) and enemies() == 2 and spell(maul) or buffpresent(incarnation) and enemies() <= 3 and spell(mangle) or target.refreshable(moonfire) and enemies() <= 3 and spell(moonfire) or { buffstacks(tooth_and_claw_buff) >= 2 or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 or buffstacks(savage_combatant_buff) >= 3 } and spell(maul) or enemies() > 1 and spell(thrash_bear) or { buffpresent(galactic_guardian) and message("druid.catweave_bear is not implemented") and enemies() <= 3 or buffpresent(galactic_guardian) and not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") and enemies() <= 3 } and spell(moonfire) or rage() < 80 and enemies() < 4 and spell(mangle) or spell(thrash_bear) or spell(maul) or spell(swipe_bear)
}

AddFunction guardianbearcdactions
{
 unless not buffpresent(bear_form) and spell(bear_form)
 {
  #potion,if=((buff.berserk_bear.up|buff.incarnation_guardian_of_ursoc.up)&(!druid.catweave_bear&!druid.owlweave_bear))
  #ravenous_frenzy
  spell(ravenous_frenzy)
  #convoke_the_spirits,if=!druid.catweave_bear&!druid.owlweave_bear
  if not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") spell(convoke_the_spirits)
 }
}

AddFunction guardianbearcdpostconditions
{
 not buffpresent(bear_form) and spell(bear_form) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(berserk_bear) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(incarnation) or { not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") or enemies() >= 2 } and spell(empower_bond) or hastalent(brambles_talent) and buffpresent(bear_form) and spell(barkskin) or buffremaining(ironfur) < 0.5 and spell(ironfur) or target.refreshable(adaptive_swarm) and spell(adaptive_swarm) or buffpresent(galactic_guardian) and message("druid.owlweave_bear is not implemented") and enemies() <= 3 and spell(moonfire) or { target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and message("runeforge.luffainfused_embrace.equipped is not implemented") or enemies() > 5 } and spell(thrash_bear) or buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and enemies() >= 4 and spell(swipe) or buffpresent(incarnation) and enemies() < 2 and spell(maul) or buffstacks(savage_combatant_buff) >= 1 and buffpresent(tooth_and_claw_buff) and buffpresent(incarnation) and enemies() == 2 and spell(maul) or buffpresent(incarnation) and enemies() <= 3 and spell(mangle) or target.refreshable(moonfire) and enemies() <= 3 and spell(moonfire) or { buffstacks(tooth_and_claw_buff) >= 2 or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 or buffstacks(savage_combatant_buff) >= 3 } and spell(maul) or enemies() > 1 and spell(thrash_bear) or { buffpresent(galactic_guardian) and message("druid.catweave_bear is not implemented") and enemies() <= 3 or buffpresent(galactic_guardian) and not message("druid.catweave_bear is not implemented") and not message("druid.owlweave_bear is not implemented") and enemies() <= 3 } and spell(moonfire) or rage() < 80 and enemies() < 4 and spell(mangle) or target.debuffstacks(thrash_bear_debuff) > 2 and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) and spell(pulverize) or spell(thrash_bear) or spell(maul) or spell(swipe_bear)
}

### actions.default

AddFunction guardian_defaultmainactions
{
 #potion,if=((talent.heart_of_the_wild.enabled&buff.heart_of_the_wild.up)&(druid.catweave_bear|druid.owlweave_bear))
 #run_action_list,name=catweave,if=druid.catweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&dot.moonfire.remains>=gcd+0.5&rage<40&buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&buff.galactic_guardian.down)|(buff.cat_form.up&energy>25)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up&(buff.cat_form.up&energy>20))|(runeforge.oath_of_the_elder_druid.equipped&buff.heart_of_the_wild.remains<10)&(buff.cat_form.up&energy>20)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
 if message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardiancatweavemainactions()

 unless message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweavemainpostconditions()
 {
  #run_action_list,name=owlweave,if=druid.owlweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&rage<20&buff.incarnation.down&buff.berserk_bear.down)|(buff.moonkin_form.up&dot.sunfire.refreshable)|(buff.moonkin_form.up&buff.heart_of_the_wild.up)|(buff.moonkin_form.up&(buff.eclipse_lunar.up|buff.eclipse_solar.up)&!runeforge.oath_of_the_elder_druid.equipped)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up)|(covenant.night_fae&cooldown.convoke_the_spirits.remains<=1)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
  if message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardianowlweavemainactions()

  unless message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweavemainpostconditions()
  {
   #run_action_list,name=lycarao,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.balance_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
   if message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaraomainactions()

   unless message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraomainpostconditions()
   {
    #run_action_list,name=lycarac,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.feral_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
    if message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaracmainactions()

    unless message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaracmainpostconditions()
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
 message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweavemainpostconditions() or message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweavemainpostconditions() or message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraomainpostconditions() or message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaracmainpostconditions() or guardianbearmainpostconditions()
}

AddFunction guardian_defaultshortcdactions
{
 #auto_attack
 guardiangetinmeleerange()
 #potion,if=((talent.heart_of_the_wild.enabled&buff.heart_of_the_wild.up)&(druid.catweave_bear|druid.owlweave_bear))
 #run_action_list,name=catweave,if=druid.catweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&dot.moonfire.remains>=gcd+0.5&rage<40&buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&buff.galactic_guardian.down)|(buff.cat_form.up&energy>25)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up&(buff.cat_form.up&energy>20))|(runeforge.oath_of_the_elder_druid.equipped&buff.heart_of_the_wild.remains<10)&(buff.cat_form.up&energy>20)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
 if message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardiancatweaveshortcdactions()

 unless message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweaveshortcdpostconditions()
 {
  #run_action_list,name=owlweave,if=druid.owlweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&rage<20&buff.incarnation.down&buff.berserk_bear.down)|(buff.moonkin_form.up&dot.sunfire.refreshable)|(buff.moonkin_form.up&buff.heart_of_the_wild.up)|(buff.moonkin_form.up&(buff.eclipse_lunar.up|buff.eclipse_solar.up)&!runeforge.oath_of_the_elder_druid.equipped)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up)|(covenant.night_fae&cooldown.convoke_the_spirits.remains<=1)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
  if message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardianowlweaveshortcdactions()

  unless message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweaveshortcdpostconditions()
  {
   #run_action_list,name=lycarao,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.balance_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
   if message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaraoshortcdactions()

   unless message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraoshortcdpostconditions()
   {
    #run_action_list,name=lycarac,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.feral_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
    if message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaracshortcdactions()

    unless message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaracshortcdpostconditions()
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
 message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweaveshortcdpostconditions() or message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweaveshortcdpostconditions() or message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraoshortcdpostconditions() or message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaracshortcdpostconditions() or guardianbearshortcdpostconditions()
}

AddFunction guardian_defaultcdactions
{
 guardianinterruptactions()
 #use_items
 guardianuseitemactions()
 #potion,if=((talent.heart_of_the_wild.enabled&buff.heart_of_the_wild.up)&(druid.catweave_bear|druid.owlweave_bear))
 #run_action_list,name=catweave,if=druid.catweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&dot.moonfire.remains>=gcd+0.5&rage<40&buff.incarnation_guardian_of_ursoc.down&buff.berserk_bear.down&buff.galactic_guardian.down)|(buff.cat_form.up&energy>25)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up&(buff.cat_form.up&energy>20))|(runeforge.oath_of_the_elder_druid.equipped&buff.heart_of_the_wild.remains<10)&(buff.cat_form.up&energy>20)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
 if message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardiancatweavecdactions()

 unless message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweavecdpostconditions()
 {
  #run_action_list,name=owlweave,if=druid.owlweave_bear&((cooldown.thrash_bear.remains>0&cooldown.mangle.remains>0&rage<20&buff.incarnation.down&buff.berserk_bear.down)|(buff.moonkin_form.up&dot.sunfire.refreshable)|(buff.moonkin_form.up&buff.heart_of_the_wild.up)|(buff.moonkin_form.up&(buff.eclipse_lunar.up|buff.eclipse_solar.up)&!runeforge.oath_of_the_elder_druid.equipped)|(runeforge.oath_of_the_elder_druid.equipped&!buff.oath_of_the_elder_druid.up)|(covenant.night_fae&cooldown.convoke_the_spirits.remains<=1)|(covenant.kyrian&cooldown.empower_bond.remains<=1&active_enemies<2))
  if message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } guardianowlweavecdactions()

  unless message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweavecdpostconditions()
  {
   #run_action_list,name=lycarao,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.balance_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
   if message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaraocdactions()

   unless message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraocdpostconditions()
   {
    #run_action_list,name=lycarac,if=((runeforge.lycaras_fleeting_glimpse.equipped)&(talent.feral_affinity.enabled)&(buff.lycaras_fleeting_glimpse.up)&(buff.lycaras_fleeting_glimpse.remains<=2))
    if message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 guardianlycaraccdactions()

    unless message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraccdpostconditions()
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
 message("druid.catweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and target.debuffremaining(moonfire) >= gcd() + 0.5 and rage() < 40 and buffexpires(incarnation_guardian_of_ursoc) and buffexpires(berserk_bear_buff) and buffexpires(galactic_guardian) or buffpresent(cat_form) and energy() > 25 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) and buffpresent(cat_form) and energy() > 20 or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and buffremaining(heart_of_the_wild) < 10 and buffpresent(cat_form) and energy() > 20 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardiancatweavecdpostconditions() or message("druid.owlweave_bear is not implemented") and { spellcooldown(thrash_bear) > 0 and spellcooldown(mangle) > 0 and rage() < 20 and buffexpires(incarnation) and buffexpires(berserk_bear_buff) or buffpresent(moonkin_form) and target.debuffrefreshable(sunfire) or buffpresent(moonkin_form) and buffpresent(heart_of_the_wild) or buffpresent(moonkin_form) and { buffpresent(eclipse_lunar) or buffpresent(eclipse_solar) } and not message("runeforge.oath_of_the_elder_druid.equipped is not implemented") or message("runeforge.oath_of_the_elder_druid.equipped is not implemented") and not buffpresent(oath_of_the_elder_druid) or message("covenant.night_fae is not implemented") and spellcooldown(convoke_the_spirits) <= 1 or message("covenant.kyrian is not implemented") and spellcooldown(empower_bond) <= 1 and enemies() < 2 } and guardianowlweavecdpostconditions() or message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(balance_affinity_talent) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraocdpostconditions() or message("runeforge.lycaras_fleeting_glimpse.equipped is not implemented") and hastalent(feral_affinity_talent_guardian) and buffpresent(lycaras_fleeting_glimpse) and buffremaining(lycaras_fleeting_glimpse) <= 2 and guardianlycaraccdpostconditions() or guardianbearcdpostconditions()
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
# adaptive_swarm
# balance_affinity_talent
# barkskin
# bear_form
# berserk_bear
# berserk_bear_buff
# brambles_talent
# cat_form
# convoke_the_spirits
# eclipse_lunar
# eclipse_solar
# empower_bond
# feral_affinity_talent_guardian
# ferocious_bite
# galactic_guardian
# heart_of_the_wild
# heart_of_the_wild_talent
# incapacitating_roar
# incarnation
# incarnation_guardian_of_ursoc
# ironfur
# lycaras_fleeting_glimpse
# mangle
# maul
# mighty_bash
# moonfire
# moonkin_form
# oath_of_the_elder_druid
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
# swipe
# swipe_bear
# thrash_bear
# thrash_bear_debuff
# tooth_and_claw_buff
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
# wrath
]]
        OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
    end
end
