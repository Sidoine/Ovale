local __exports = LibStub:NewLibrary("ovale/scripts/ovale_shaman", 80300)
if not __exports then return end
__exports.registerShaman = function(OvaleScripts)
    do
        local name = "sc_t24_shaman_elemental"
        local desc = "[8.3] Simulationcraft: T24_Shaman_Elemental"
        local code = [[
# Based on SimulationCraft profile "T24_Shaman_Elemental".
#	class=shaman
#	spec=elemental
#	talents=2311132

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=elemental)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=elemental)
AddCheckBox(opt_bloodlust spellname(bloodlust) specialization=elemental)

AddFunction elementalinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(wind_shear) and target.isinterruptible() spell(wind_shear)
  if not target.classification(worldboss) and target.remainingcasttime() > 2 spell(capacitor_totem)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.inrange(hex) and not target.classification(worldboss) and target.remainingcasttime() > casttime(hex) + gcdremaining() and target.creaturetype(humanoid beast) spell(hex)
 }
}

AddFunction elementaluseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction elementalbloodlust
{
 if checkboxon(opt_bloodlust) and debuffexpires(burst_haste_debuff any=1)
 {
  spell(bloodlust)
  spell(heroism)
 }
}

### actions.single_target

AddFunction elementalsingle_targetmainactions
{
 #flame_shock,target_if=(!ticking|dot.flame_shock.remains<=gcd|talent.ascendance.enabled&dot.flame_shock.remains<(cooldown.ascendance.remains+buff.ascendance.duration)&cooldown.ascendance.remains<4&(!talent.storm_elemental.enabled|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120))&(buff.wind_gust.stack<14|azerite.igneous_potential.rank>=2|buff.lava_surge.up|!buff.bloodlust.up)&!buff.surge_of_power.up
 if { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) spell(flame_shock)
 #elemental_blast,if=talent.elemental_blast.enabled&(talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up&maelstrom<60|!buff.master_of_the_elements.up)|!talent.master_of_the_elements.enabled)&(!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)|azerite.natural_harmony.rank=3&buff.wind_gust.stack<14)
 if hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not buffpresent(master_of_the_elements_buff) } or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } spell(elemental_blast)
 #lightning_bolt,if=buff.stormkeeper.up&spell_targets.chain_lightning<2&(azerite.lava_shock.rank*buff.lava_shock.stack)<26&(buff.master_of_the_elements.up&!talent.surge_of_power.enabled|buff.surge_of_power.up)
 if buffpresent(stormkeeper_buff) and enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } spell(lightning_bolt_elemental)
 #earthquake,if=(spell_targets.chain_lightning>1|azerite.tectonic_thunder.rank>=3&!talent.surge_of_power.enabled&azerite.lava_shock.rank<1)&azerite.lava_shock.rank*buff.lava_shock.stack<(36+3*azerite.tectonic_thunder.rank*spell_targets.chain_lightning)&(!talent.surge_of_power.enabled|!dot.flame_shock.refreshable|cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30))&(!talent.master_of_the_elements.enabled|buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled)
 if { enemies() > 1 or azeritetraitrank(tectonic_thunder_trait) >= 3 and not hastalent(surge_of_power_talent) and azeritetraitrank(lava_shock_trait) < 1 } and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 + 3 * azeritetraitrank(tectonic_thunder_trait) * enemies() and { not hastalent(surge_of_power_talent) or not target.debuffrefreshable(flame_shock_debuff) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and { not hastalent(master_of_the_elements_talent) or buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) } spell(earthquake)
 #earth_shock,if=!buff.surge_of_power.up&talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled|spell_targets.chain_lightning<2&(azerite.lava_shock.rank*buff.lava_shock.stack<26)&buff.stormkeeper.up&cooldown.lava_burst.remains<=gcd)
 if not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } spell(earth_shock)
 #earth_shock,if=!talent.master_of_the_elements.enabled&!(azerite.igneous_potential.rank>2&buff.ascendance.up)&(buff.stormkeeper.up|maelstrom>=90+30*talent.call_the_thunder.enabled|!(cooldown.storm_elemental.remains>cooldown.storm_elemental.duration&talent.storm_elemental.enabled)&expected_combat_length-time-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration)>=30*(1+(azerite.echo_of_the_elementals.rank>=2)))
 if not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } spell(earth_shock)
 #earth_shock,if=talent.surge_of_power.enabled&!buff.surge_of_power.up&cooldown.lava_burst.remains<=gcd&(!talent.storm_elemental.enabled&!(cooldown.fire_elemental.remains>(cooldown.fire_elemental.duration-30))|talent.storm_elemental.enabled&!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)))
 if hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(fire_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } spell(earth_shock)
 #lightning_bolt,if=cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled&(azerite.igneous_potential.rank<2|!buff.lava_surge.up&buff.bloodlust.up)
 if spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } spell(lightning_bolt_elemental)
 #lightning_bolt,if=(buff.stormkeeper.remains<1.1*gcd*buff.stormkeeper.stack|buff.stormkeeper.up&buff.master_of_the_elements.up)
 if buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) spell(lightning_bolt_elemental)
 #frost_shock,if=talent.icefury.enabled&talent.master_of_the_elements.enabled&buff.icefury.up&buff.master_of_the_elements.up
 if hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) spell(frost_shock)
 #lava_burst,if=buff.ascendance.up
 if buffpresent(ascendance_elemental_buff) spell(lava_burst)
 #flame_shock,target_if=refreshable&active_enemies>1&buff.surge_of_power.up
 if target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) spell(flame_shock)
 #lava_burst,if=talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration))<(expected_combat_length-time-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration)))
 if hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } spell(lava_burst)
 #lava_burst,if=!talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.fire_elemental.remains-cooldown.fire_elemental.duration*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%cooldown.fire_elemental.duration)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains-cooldown.fire_elemental.duration*floor((1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains)%cooldown.fire_elemental.duration))<(expected_combat_length-time-cooldown.fire_elemental.remains-cooldown.fire_elemental.duration*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%cooldown.fire_elemental.duration)))
 if not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } spell(lava_burst)
 #lightning_bolt,if=buff.surge_of_power.up
 if buffpresent(surge_of_power_buff) spell(lightning_bolt_elemental)
 #lava_burst,if=cooldown_react&!talent.master_of_the_elements.enabled
 if not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) spell(lava_burst)
 #lava_burst,if=cooldown_react&charges>talent.echo_of_the_elements.enabled
 if not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) spell(lava_burst)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&buff.icefury.remains<1.1*gcd*buff.icefury.stack
 if hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) spell(frost_shock)
 #lava_burst,if=cooldown_react
 if not spellcooldown(lava_burst) > 0 spell(lava_burst)
 #concentrated_flame
 spell(concentrated_flame_essence)
 #flame_shock,target_if=refreshable&!buff.surge_of_power.up
 if target.refreshable(flame_shock_debuff) and not buffpresent(surge_of_power_buff) spell(flame_shock)
 #totem_mastery,if=talent.totem_mastery.enabled&(buff.resonance_totem.remains<6|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15))
 if hastalent(totem_mastery_talent_elemental) and { totemremaining(totem_mastery_elemental) < 6 or totemremaining(totem_mastery_elemental) < baseduration(ascendance_elemental_buff) + spellcooldown(ascendance_elemental) and spellcooldown(ascendance_elemental) < 15 } spell(totem_mastery_elemental)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&(buff.icefury.remains<gcd*4*buff.icefury.stack|buff.stormkeeper.up|!talent.master_of_the_elements.enabled)
 if hastalent(icefury_talent) and buffpresent(icefury_buff) and { buffremaining(icefury_buff) < gcd() * 4 * buffstacks(icefury_buff) or buffpresent(stormkeeper_buff) or not hastalent(master_of_the_elements_talent) } spell(frost_shock)
 #chain_lightning,if=buff.tectonic_thunder.up&!buff.stormkeeper.up&spell_targets.chain_lightning>1
 if buffpresent(tectonic_thunder) and not buffpresent(stormkeeper_buff) and enemies() > 1 spell(chain_lightning_elemental)
 #lightning_bolt
 spell(lightning_bolt_elemental)
 #flame_shock,moving=1,target_if=refreshable
 if speed() > 0 and target.refreshable(flame_shock_debuff) spell(flame_shock)
 #flame_shock,moving=1,if=movement.distance>6
 if speed() > 0 and target.distance() > 6 spell(flame_shock)
 #frost_shock,moving=1
 if speed() > 0 spell(frost_shock)
}

AddFunction elementalsingle_targetmainpostconditions
{
}

AddFunction elementalsingle_targetshortcdactions
{
 unless { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not buffpresent(master_of_the_elements_buff) } or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } and spell(elemental_blast)
 {
  #stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)&(!talent.surge_of_power.enabled|buff.surge_of_power.up|maelstrom>=44)
  if hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) or maelstrom() >= 44 } spell(stormkeeper)
  #liquid_magma_totem,if=talent.liquid_magma_totem.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
  if hastalent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } spell(liquid_magma_totem)

  unless buffpresent(stormkeeper_buff) and enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } and spell(lightning_bolt_elemental) or { enemies() > 1 or azeritetraitrank(tectonic_thunder_trait) >= 3 and not hastalent(surge_of_power_talent) and azeritetraitrank(lava_shock_trait) < 1 } and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 + 3 * azeritetraitrank(tectonic_thunder_trait) * enemies() and { not hastalent(surge_of_power_talent) or not target.debuffrefreshable(flame_shock_debuff) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and { not hastalent(master_of_the_elements_talent) or buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) } and spell(earthquake) or not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } and spell(earth_shock) or not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } and spell(earth_shock) or hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(fire_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and spell(earth_shock)
  {
   #lightning_lasso
   spell(lightning_lasso)

   unless spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } and spell(lightning_bolt_elemental) or { buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) } and spell(lightning_bolt_elemental) or hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) and spell(frost_shock) or buffpresent(ascendance_elemental_buff) and spell(lava_burst) or target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } and spell(lava_burst) or not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } and spell(lava_burst) or buffpresent(surge_of_power_buff) and spell(lightning_bolt_elemental) or not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) and spell(lava_burst)
   {
    #icefury,if=talent.icefury.enabled&!(maelstrom>75&cooldown.lava_burst.remains<=0)&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<cooldown.storm_elemental.duration-30)
    if hastalent(icefury_talent) and not { maelstrom() > 75 and spellcooldown(lava_burst) <= 0 } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } spell(icefury)

    unless not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) and spell(lava_burst) or hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) and spell(frost_shock) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or spell(concentrated_flame_essence)
    {
     #reaping_flames
     spell(reaping_flames)
    }
   }
  }
 }
}

AddFunction elementalsingle_targetshortcdpostconditions
{
 { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not buffpresent(master_of_the_elements_buff) } or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } and spell(elemental_blast) or buffpresent(stormkeeper_buff) and enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } and spell(lightning_bolt_elemental) or { enemies() > 1 or azeritetraitrank(tectonic_thunder_trait) >= 3 and not hastalent(surge_of_power_talent) and azeritetraitrank(lava_shock_trait) < 1 } and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 + 3 * azeritetraitrank(tectonic_thunder_trait) * enemies() and { not hastalent(surge_of_power_talent) or not target.debuffrefreshable(flame_shock_debuff) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and { not hastalent(master_of_the_elements_talent) or buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) } and spell(earthquake) or not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } and spell(earth_shock) or not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } and spell(earth_shock) or hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(fire_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and spell(earth_shock) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } and spell(lightning_bolt_elemental) or { buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) } and spell(lightning_bolt_elemental) or hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) and spell(frost_shock) or buffpresent(ascendance_elemental_buff) and spell(lava_burst) or target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } and spell(lava_burst) or not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } and spell(lava_burst) or buffpresent(surge_of_power_buff) and spell(lightning_bolt_elemental) or not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) and spell(lava_burst) or not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) and spell(lava_burst) or hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) and spell(frost_shock) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or spell(concentrated_flame_essence) or target.refreshable(flame_shock_debuff) and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(totem_mastery_talent_elemental) and { totemremaining(totem_mastery_elemental) < 6 or totemremaining(totem_mastery_elemental) < baseduration(ascendance_elemental_buff) + spellcooldown(ascendance_elemental) and spellcooldown(ascendance_elemental) < 15 } and spell(totem_mastery_elemental) or hastalent(icefury_talent) and buffpresent(icefury_buff) and { buffremaining(icefury_buff) < gcd() * 4 * buffstacks(icefury_buff) or buffpresent(stormkeeper_buff) or not hastalent(master_of_the_elements_talent) } and spell(frost_shock) or buffpresent(tectonic_thunder) and not buffpresent(stormkeeper_buff) and enemies() > 1 and spell(chain_lightning_elemental) or spell(lightning_bolt_elemental) or speed() > 0 and target.refreshable(flame_shock_debuff) and spell(flame_shock) or speed() > 0 and target.distance() > 6 and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

AddFunction elementalsingle_targetcdactions
{
 unless { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) and spell(flame_shock)
 {
  #blood_of_the_enemy,if=!talent.ascendance.enabled&!talent.storm_elemental.enabled|talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if not hastalent(ascendance_talent) and not hastalent(storm_elemental_talent) or hastalent(ascendance_talent) and { timeincombat() >= 60 or buffpresent(bloodlust_buff) } and spellcooldown(lava_burst) > 0 and { spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or not hastalent(storm_elemental_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } spell(blood_of_the_enemy)
  #ascendance,if=talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if hastalent(ascendance_talent) and { timeincombat() >= 60 or buffpresent(bloodlust_buff) } and spellcooldown(lava_burst) > 0 and { spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or not hastalent(storm_elemental_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } and buffexpires(ascendance_elemental_buff) spell(ascendance_elemental)

  unless hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not buffpresent(master_of_the_elements_buff) } or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } and spell(elemental_blast) or hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) or maelstrom() >= 44 } and spell(stormkeeper) or hastalent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } and spell(liquid_magma_totem) or buffpresent(stormkeeper_buff) and enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } and spell(lightning_bolt_elemental) or { enemies() > 1 or azeritetraitrank(tectonic_thunder_trait) >= 3 and not hastalent(surge_of_power_talent) and azeritetraitrank(lava_shock_trait) < 1 } and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 + 3 * azeritetraitrank(tectonic_thunder_trait) * enemies() and { not hastalent(surge_of_power_talent) or not target.debuffrefreshable(flame_shock_debuff) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and { not hastalent(master_of_the_elements_talent) or buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) } and spell(earthquake) or not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } and spell(earth_shock) or not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } and spell(earth_shock) or hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(fire_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and spell(earth_shock) or spell(lightning_lasso) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } and spell(lightning_bolt_elemental) or { buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) } and spell(lightning_bolt_elemental) or hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) and spell(frost_shock) or buffpresent(ascendance_elemental_buff) and spell(lava_burst) or target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } and spell(lava_burst) or not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } and spell(lava_burst) or buffpresent(surge_of_power_buff) and spell(lightning_bolt_elemental) or not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) and spell(lava_burst) or hastalent(icefury_talent) and not { maelstrom() > 75 and spellcooldown(lava_burst) <= 0 } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } and spell(icefury) or not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) and spell(lava_burst) or hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) and spell(frost_shock) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or spell(concentrated_flame_essence) or spell(reaping_flames) or target.refreshable(flame_shock_debuff) and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(totem_mastery_talent_elemental) and { totemremaining(totem_mastery_elemental) < 6 or totemremaining(totem_mastery_elemental) < baseduration(ascendance_elemental_buff) + spellcooldown(ascendance_elemental) and spellcooldown(ascendance_elemental) < 15 } and spell(totem_mastery_elemental) or hastalent(icefury_talent) and buffpresent(icefury_buff) and { buffremaining(icefury_buff) < gcd() * 4 * buffstacks(icefury_buff) or buffpresent(stormkeeper_buff) or not hastalent(master_of_the_elements_talent) } and spell(frost_shock)
  {
   #earth_elemental,if=!talent.primal_elementalist.enabled|talent.primal_elementalist.enabled&(cooldown.fire_elemental.remains<(cooldown.fire_elemental.duration-30)&!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)
   if not hastalent(primal_elementalist_talent) or hastalent(primal_elementalist_talent) and { spellcooldown(fire_elemental) < spellcooldownduration(fire_elemental) - 30 and not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } spell(earth_elemental)
  }
 }
}

AddFunction elementalsingle_targetcdpostconditions
{
 { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not buffpresent(master_of_the_elements_buff) } or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } and spell(elemental_blast) or hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) or maelstrom() >= 44 } and spell(stormkeeper) or hastalent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } and spell(liquid_magma_totem) or buffpresent(stormkeeper_buff) and enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } and spell(lightning_bolt_elemental) or { enemies() > 1 or azeritetraitrank(tectonic_thunder_trait) >= 3 and not hastalent(surge_of_power_talent) and azeritetraitrank(lava_shock_trait) < 1 } and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 + 3 * azeritetraitrank(tectonic_thunder_trait) * enemies() and { not hastalent(surge_of_power_talent) or not target.debuffrefreshable(flame_shock_debuff) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and { not hastalent(master_of_the_elements_talent) or buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) } and spell(earthquake) or not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or enemies() < 2 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 26 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } and spell(earth_shock) or not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } and spell(earth_shock) or hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(fire_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and spell(earth_shock) or spell(lightning_lasso) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } and spell(lightning_bolt_elemental) or { buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) } and spell(lightning_bolt_elemental) or hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) and spell(frost_shock) or buffpresent(ascendance_elemental_buff) and spell(lava_burst) or target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } and spell(lava_burst) or not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } and spell(lava_burst) or buffpresent(surge_of_power_buff) and spell(lightning_bolt_elemental) or not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) and spell(lava_burst) or hastalent(icefury_talent) and not { maelstrom() > 75 and spellcooldown(lava_burst) <= 0 } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } and spell(icefury) or not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) and spell(lava_burst) or hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) and spell(frost_shock) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or spell(concentrated_flame_essence) or spell(reaping_flames) or target.refreshable(flame_shock_debuff) and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(totem_mastery_talent_elemental) and { totemremaining(totem_mastery_elemental) < 6 or totemremaining(totem_mastery_elemental) < baseduration(ascendance_elemental_buff) + spellcooldown(ascendance_elemental) and spellcooldown(ascendance_elemental) < 15 } and spell(totem_mastery_elemental) or hastalent(icefury_talent) and buffpresent(icefury_buff) and { buffremaining(icefury_buff) < gcd() * 4 * buffstacks(icefury_buff) or buffpresent(stormkeeper_buff) or not hastalent(master_of_the_elements_talent) } and spell(frost_shock) or buffpresent(tectonic_thunder) and not buffpresent(stormkeeper_buff) and enemies() > 1 and spell(chain_lightning_elemental) or spell(lightning_bolt_elemental) or speed() > 0 and target.refreshable(flame_shock_debuff) and spell(flame_shock) or speed() > 0 and target.distance() > 6 and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

### actions.precombat

AddFunction elementalprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #totem_mastery
 spell(totem_mastery_elemental)
 #elemental_blast,if=talent.elemental_blast.enabled
 if hastalent(elemental_blast_talent) spell(elemental_blast)
 #lava_burst,if=!talent.elemental_blast.enabled
 if not hastalent(elemental_blast_talent) spell(lava_burst)
}

AddFunction elementalprecombatmainpostconditions
{
}

AddFunction elementalprecombatshortcdactions
{
 unless spell(totem_mastery_elemental)
 {
  #stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
  if hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } spell(stormkeeper)
 }
}

AddFunction elementalprecombatshortcdpostconditions
{
 spell(totem_mastery_elemental) or hastalent(elemental_blast_talent) and spell(elemental_blast) or not hastalent(elemental_blast_talent) and spell(lava_burst)
}

AddFunction elementalprecombatcdactions
{
 unless spell(totem_mastery_elemental)
 {
  #earth_elemental,if=!talent.primal_elementalist.enabled
  if not hastalent(primal_elementalist_talent) spell(earth_elemental)
  #use_item,name=azsharas_font_of_power
  elementaluseitemactions()

  unless hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and spell(stormkeeper)
  {
   #potion
   if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  }
 }
}

AddFunction elementalprecombatcdpostconditions
{
 spell(totem_mastery_elemental) or hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and spell(stormkeeper) or hastalent(elemental_blast_talent) and spell(elemental_blast) or not hastalent(elemental_blast_talent) and spell(lava_burst)
}

### actions.funnel

AddFunction elementalfunnelmainactions
{
 #flame_shock,target_if=(!ticking|dot.flame_shock.remains<=gcd|talent.ascendance.enabled&dot.flame_shock.remains<(cooldown.ascendance.remains+buff.ascendance.duration)&cooldown.ascendance.remains<4&(!talent.storm_elemental.enabled|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120))&(buff.wind_gust.stack<14|azerite.igneous_potential.rank>=2|buff.lava_surge.up|!buff.bloodlust.up)&!buff.surge_of_power.up
 if { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) spell(flame_shock)
 #elemental_blast,if=talent.elemental_blast.enabled&(talent.master_of_the_elements.enabled&buff.master_of_the_elements.up&maelstrom<60|!talent.master_of_the_elements.enabled)&(!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)|azerite.natural_harmony.rank=3&buff.wind_gust.stack<14)
 if hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } spell(elemental_blast)
 #lightning_bolt,if=buff.stormkeeper.up&spell_targets.chain_lightning<6&(azerite.lava_shock.rank*buff.lava_shock.stack)<36&(buff.master_of_the_elements.up&!talent.surge_of_power.enabled|buff.surge_of_power.up)
 if buffpresent(stormkeeper_buff) and enemies() < 6 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } spell(lightning_bolt_elemental)
 #earth_shock,if=!buff.surge_of_power.up&talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled|(azerite.lava_shock.rank*buff.lava_shock.stack<36)&buff.stormkeeper.up&cooldown.lava_burst.remains<=gcd)
 if not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } spell(earth_shock)
 #earth_shock,if=!talent.master_of_the_elements.enabled&!(azerite.igneous_potential.rank>2&buff.ascendance.up)&(buff.stormkeeper.up|maelstrom>=90+30*talent.call_the_thunder.enabled|!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)&expected_combat_length-time-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration)>=30*(1+(azerite.echo_of_the_elementals.rank>=2)))
 if not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } spell(earth_shock)
 #earth_shock,if=talent.surge_of_power.enabled&!buff.surge_of_power.up&cooldown.lava_burst.remains<=gcd&(!talent.storm_elemental.enabled&!(cooldown.fire_elemental.remains>(cooldown.storm_elemental.duration-30))|talent.storm_elemental.enabled&!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)))
 if hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } spell(earth_shock)
 #lightning_bolt,if=cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled&(azerite.igneous_potential.rank<2|!buff.lava_surge.up&buff.bloodlust.up)
 if spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } spell(lightning_bolt_elemental)
 #lightning_bolt,if=(buff.stormkeeper.remains<1.1*gcd*buff.stormkeeper.stack|buff.stormkeeper.up&buff.master_of_the_elements.up)
 if buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) spell(lightning_bolt_elemental)
 #frost_shock,if=talent.icefury.enabled&talent.master_of_the_elements.enabled&buff.icefury.up&buff.master_of_the_elements.up
 if hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) spell(frost_shock)
 #lava_burst,if=buff.ascendance.up
 if buffpresent(ascendance_elemental_buff) spell(lava_burst)
 #flame_shock,target_if=refreshable&active_enemies>1&buff.surge_of_power.up
 if target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) spell(flame_shock)
 #lava_burst,if=talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.storm_elemental.remains-(cooldown.storm_elemental.duration-30)*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%(cooldown.storm_elemental.duration-30))<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration))<(expected_combat_length-time-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration)))
 if hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - { spellcooldownduration(storm_elemental) - 30 } * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / { spellcooldownduration(storm_elemental) - 30 } } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } spell(lava_burst)
 #lava_burst,if=!talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.fire_elemental.remains-cooldown.fire_elemental.duration*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%cooldown.fire_elemental.duration)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains-cooldown.fire_elemental.duration*floor((1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains)%cooldown.fire_elemental.duration))<(expected_combat_length-time-cooldown.fire_elemental.remains-cooldown.fire_elemental.duration*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%cooldown.fire_elemental.duration)))
 if not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } spell(lava_burst)
 #lightning_bolt,if=buff.surge_of_power.up
 if buffpresent(surge_of_power_buff) spell(lightning_bolt_elemental)
 #lava_burst,if=cooldown_react&!talent.master_of_the_elements.enabled
 if not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) spell(lava_burst)
 #lava_burst,if=cooldown_react&charges>talent.echo_of_the_elements.enabled
 if not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) spell(lava_burst)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&buff.icefury.remains<1.1*gcd*buff.icefury.stack
 if hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) spell(frost_shock)
 #lava_burst,if=cooldown_react
 if not spellcooldown(lava_burst) > 0 spell(lava_burst)
 #concentrated_flame
 spell(concentrated_flame_essence)
 #flame_shock,target_if=refreshable&!buff.surge_of_power.up
 if target.refreshable(flame_shock_debuff) and not buffpresent(surge_of_power_buff) spell(flame_shock)
 #totem_mastery,if=talent.totem_mastery.enabled&(buff.resonance_totem.remains<6|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15))
 if hastalent(totem_mastery_talent_elemental) and { totemremaining(totem_mastery_elemental) < 6 or totemremaining(totem_mastery_elemental) < baseduration(ascendance_elemental_buff) + spellcooldown(ascendance_elemental) and spellcooldown(ascendance_elemental) < 15 } spell(totem_mastery_elemental)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up&(buff.icefury.remains<gcd*4*buff.icefury.stack|buff.stormkeeper.up|!talent.master_of_the_elements.enabled)
 if hastalent(icefury_talent) and buffpresent(icefury_buff) and { buffremaining(icefury_buff) < gcd() * 4 * buffstacks(icefury_buff) or buffpresent(stormkeeper_buff) or not hastalent(master_of_the_elements_talent) } spell(frost_shock)
 #lightning_bolt
 spell(lightning_bolt_elemental)
 #flame_shock,moving=1,target_if=refreshable
 if speed() > 0 and target.refreshable(flame_shock_debuff) spell(flame_shock)
 #flame_shock,moving=1,if=movement.distance>6
 if speed() > 0 and target.distance() > 6 spell(flame_shock)
 #frost_shock,moving=1
 if speed() > 0 spell(frost_shock)
}

AddFunction elementalfunnelmainpostconditions
{
}

AddFunction elementalfunnelshortcdactions
{
 unless { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } and spell(elemental_blast)
 {
  #stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)&(!talent.surge_of_power.enabled|buff.surge_of_power.up|maelstrom>=44)
  if hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) or maelstrom() >= 44 } spell(stormkeeper)
  #liquid_magma_totem,if=talent.liquid_magma_totem.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
  if hastalent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } spell(liquid_magma_totem)

  unless buffpresent(stormkeeper_buff) and enemies() < 6 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } and spell(lightning_bolt_elemental) or not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } and spell(earth_shock) or not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } and spell(earth_shock) or hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and spell(earth_shock) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } and spell(lightning_bolt_elemental) or { buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) } and spell(lightning_bolt_elemental) or hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) and spell(frost_shock) or buffpresent(ascendance_elemental_buff) and spell(lava_burst) or target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - { spellcooldownduration(storm_elemental) - 30 } * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / { spellcooldownduration(storm_elemental) - 30 } } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } and spell(lava_burst) or not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } and spell(lava_burst) or buffpresent(surge_of_power_buff) and spell(lightning_bolt_elemental) or not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) and spell(lava_burst)
  {
   #icefury,if=talent.icefury.enabled&!(maelstrom>75&cooldown.lava_burst.remains<=0)&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<cooldown.storm_elemental.duration)
   if hastalent(icefury_talent) and not { maelstrom() > 75 and spellcooldown(lava_burst) <= 0 } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) } spell(icefury)

   unless not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) and spell(lava_burst) or hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) and spell(frost_shock) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or spell(concentrated_flame_essence)
   {
    #reaping_flames
    spell(reaping_flames)
   }
  }
 }
}

AddFunction elementalfunnelshortcdpostconditions
{
 { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } and spell(elemental_blast) or buffpresent(stormkeeper_buff) and enemies() < 6 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } and spell(lightning_bolt_elemental) or not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } and spell(earth_shock) or not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } and spell(earth_shock) or hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and spell(earth_shock) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } and spell(lightning_bolt_elemental) or { buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) } and spell(lightning_bolt_elemental) or hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) and spell(frost_shock) or buffpresent(ascendance_elemental_buff) and spell(lava_burst) or target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - { spellcooldownduration(storm_elemental) - 30 } * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / { spellcooldownduration(storm_elemental) - 30 } } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } and spell(lava_burst) or not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } and spell(lava_burst) or buffpresent(surge_of_power_buff) and spell(lightning_bolt_elemental) or not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) and spell(lava_burst) or not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) and spell(lava_burst) or hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) and spell(frost_shock) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or spell(concentrated_flame_essence) or target.refreshable(flame_shock_debuff) and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(totem_mastery_talent_elemental) and { totemremaining(totem_mastery_elemental) < 6 or totemremaining(totem_mastery_elemental) < baseduration(ascendance_elemental_buff) + spellcooldown(ascendance_elemental) and spellcooldown(ascendance_elemental) < 15 } and spell(totem_mastery_elemental) or hastalent(icefury_talent) and buffpresent(icefury_buff) and { buffremaining(icefury_buff) < gcd() * 4 * buffstacks(icefury_buff) or buffpresent(stormkeeper_buff) or not hastalent(master_of_the_elements_talent) } and spell(frost_shock) or spell(lightning_bolt_elemental) or speed() > 0 and target.refreshable(flame_shock_debuff) and spell(flame_shock) or speed() > 0 and target.distance() > 6 and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

AddFunction elementalfunnelcdactions
{
 unless { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) and spell(flame_shock)
 {
  #blood_of_the_enemy,if=!talent.ascendance.enabled&(!talent.storm_elemental.enabled|!talent.primal_elementalist.enabled)|talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if not hastalent(ascendance_talent) and { not hastalent(storm_elemental_talent) or not hastalent(primal_elementalist_talent) } or hastalent(ascendance_talent) and { timeincombat() >= 60 or buffpresent(bloodlust_buff) } and spellcooldown(lava_burst) > 0 and { spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or not hastalent(storm_elemental_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } spell(blood_of_the_enemy)
  #ascendance,if=talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if hastalent(ascendance_talent) and { timeincombat() >= 60 or buffpresent(bloodlust_buff) } and spellcooldown(lava_burst) > 0 and { spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or not hastalent(storm_elemental_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } and buffexpires(ascendance_elemental_buff) spell(ascendance_elemental)

  unless hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } and spell(elemental_blast) or hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) or maelstrom() >= 44 } and spell(stormkeeper) or hastalent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } and spell(liquid_magma_totem) or buffpresent(stormkeeper_buff) and enemies() < 6 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } and spell(lightning_bolt_elemental) or not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } and spell(earth_shock) or not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } and spell(earth_shock) or hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and spell(earth_shock) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } and spell(lightning_bolt_elemental) or { buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) } and spell(lightning_bolt_elemental) or hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) and spell(frost_shock) or buffpresent(ascendance_elemental_buff) and spell(lava_burst) or target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - { spellcooldownduration(storm_elemental) - 30 } * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / { spellcooldownduration(storm_elemental) - 30 } } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } and spell(lava_burst) or not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } and spell(lava_burst) or buffpresent(surge_of_power_buff) and spell(lightning_bolt_elemental) or not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) and spell(lava_burst) or hastalent(icefury_talent) and not { maelstrom() > 75 and spellcooldown(lava_burst) <= 0 } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) } and spell(icefury) or not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) and spell(lava_burst) or hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) and spell(frost_shock) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or spell(concentrated_flame_essence) or spell(reaping_flames) or target.refreshable(flame_shock_debuff) and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(totem_mastery_talent_elemental) and { totemremaining(totem_mastery_elemental) < 6 or totemremaining(totem_mastery_elemental) < baseduration(ascendance_elemental_buff) + spellcooldown(ascendance_elemental) and spellcooldown(ascendance_elemental) < 15 } and spell(totem_mastery_elemental) or hastalent(icefury_talent) and buffpresent(icefury_buff) and { buffremaining(icefury_buff) < gcd() * 4 * buffstacks(icefury_buff) or buffpresent(stormkeeper_buff) or not hastalent(master_of_the_elements_talent) } and spell(frost_shock)
  {
   #earth_elemental,if=!talent.primal_elementalist.enabled|talent.primal_elementalist.enabled&(cooldown.fire_elemental.remains<(cooldown.fire_elemental.duration-30)&!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)
   if not hastalent(primal_elementalist_talent) or hastalent(primal_elementalist_talent) and { spellcooldown(fire_elemental) < spellcooldownduration(fire_elemental) - 30 and not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } spell(earth_elemental)
  }
 }
}

AddFunction elementalfunnelcdpostconditions
{
 { not target.debuffpresent(flame_shock_debuff) or target.debuffremaining(flame_shock_debuff) <= gcd() or hastalent(ascendance_talent) and target.debuffremaining(flame_shock_debuff) < spellcooldown(ascendance_elemental) + baseduration(ascendance_elemental_buff) and spellcooldown(ascendance_elemental) < 4 and { not hastalent(storm_elemental_talent) or hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < 120 } } and { buffstacks(wind_gust_buff) < 14 or azeritetraitrank(igneous_potential_trait) >= 2 or buffpresent(lava_surge_buff) or not buffpresent(bloodlust_buff) } and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(elemental_blast_talent) and { hastalent(master_of_the_elements_talent) and buffpresent(master_of_the_elements_buff) and maelstrom() < 60 or not hastalent(master_of_the_elements_talent) } and { not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } or azeritetraitrank(natural_harmony_trait) == 3 and buffstacks(wind_gust_buff) < 14 } and spell(elemental_blast) or hastalent(stormkeeper_talent) and { 0 < 3 or 600 > 50 } and { not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) or maelstrom() >= 44 } and spell(stormkeeper) or hastalent(liquid_magma_totem_talent) and { 0 < 3 or 600 > 50 } and spell(liquid_magma_totem) or buffpresent(stormkeeper_buff) and enemies() < 6 and azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and { buffpresent(master_of_the_elements_buff) and not hastalent(surge_of_power_talent) or buffpresent(surge_of_power_buff) } and spell(lightning_bolt_elemental) or not buffpresent(surge_of_power_buff) and hastalent(master_of_the_elements_talent) and { buffpresent(master_of_the_elements_buff) or spellcooldown(lava_burst) > 0 and maelstrom() >= 92 + 30 * talentpoints(call_the_thunder_talent) or azeritetraitrank(lava_shock_trait) * buffstacks(lava_shock_buff) < 36 and buffpresent(stormkeeper_buff) and spellcooldown(lava_burst) <= gcd() } and spell(earth_shock) or not hastalent(master_of_the_elements_talent) and not { azeritetraitrank(igneous_potential_trait) > 2 and buffpresent(ascendance_elemental_buff) } and { buffpresent(stormkeeper_buff) or maelstrom() >= 90 + 30 * talentpoints(call_the_thunder_talent) or not { spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) } and 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } >= 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } } and spell(earth_shock) or hastalent(surge_of_power_talent) and not buffpresent(surge_of_power_buff) and spellcooldown(lava_burst) <= gcd() and { not hastalent(storm_elemental_talent) and not spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 or hastalent(storm_elemental_talent) and not spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 } and spell(earth_shock) or spellcooldown(storm_elemental) > spellcooldownduration(storm_elemental) - 30 and hastalent(storm_elemental_talent) and { azeritetraitrank(igneous_potential_trait) < 2 or not buffpresent(lava_surge_buff) and buffpresent(bloodlust_buff) } and spell(lightning_bolt_elemental) or { buffremaining(stormkeeper_buff) < 1.1 * gcd() * buffstacks(stormkeeper_buff) or buffpresent(stormkeeper_buff) and buffpresent(master_of_the_elements_buff) } and spell(lightning_bolt_elemental) or hastalent(icefury_talent) and hastalent(master_of_the_elements_talent) and buffpresent(icefury_buff) and buffpresent(master_of_the_elements_buff) and spell(frost_shock) or buffpresent(ascendance_elemental_buff) and spell(lava_burst) or target.refreshable(flame_shock_debuff) and enemies() > 1 and buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(storm_elemental) - { spellcooldownduration(storm_elemental) - 30 } * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / { spellcooldownduration(storm_elemental) - 30 } } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } < 600 - timeincombat() - spellcooldown(storm_elemental) - spellcooldownduration(storm_elemental) * { { 600 - timeincombat() - spellcooldown(storm_elemental) } / spellcooldownduration(storm_elemental) } } and spell(lava_burst) or not hastalent(storm_elemental_talent) and not spellcooldown(lava_burst) > 0 and buffpresent(surge_of_power_buff) and { 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 30 * { 1 + { azeritetraitrank(echo_of_the_elementals_trait) >= 2 } } or 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 1.16 * { 600 - timeincombat() } - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } < 600 - timeincombat() - spellcooldown(fire_elemental) - spellcooldownduration(fire_elemental) * { { 600 - timeincombat() - spellcooldown(fire_elemental) } / spellcooldownduration(fire_elemental) } } and spell(lava_burst) or buffpresent(surge_of_power_buff) and spell(lightning_bolt_elemental) or not spellcooldown(lava_burst) > 0 and not hastalent(master_of_the_elements_talent) and spell(lava_burst) or hastalent(icefury_talent) and not { maelstrom() > 75 and spellcooldown(lava_burst) <= 0 } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) } and spell(icefury) or not spellcooldown(lava_burst) > 0 and charges(lava_burst) > talentpoints(echo_of_the_elements_talent_elemental) and spell(lava_burst) or hastalent(icefury_talent) and buffpresent(icefury_buff) and buffremaining(icefury_buff) < 1.1 * gcd() * buffstacks(icefury_buff) and spell(frost_shock) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or spell(concentrated_flame_essence) or spell(reaping_flames) or target.refreshable(flame_shock_debuff) and not buffpresent(surge_of_power_buff) and spell(flame_shock) or hastalent(totem_mastery_talent_elemental) and { totemremaining(totem_mastery_elemental) < 6 or totemremaining(totem_mastery_elemental) < baseduration(ascendance_elemental_buff) + spellcooldown(ascendance_elemental) and spellcooldown(ascendance_elemental) < 15 } and spell(totem_mastery_elemental) or hastalent(icefury_talent) and buffpresent(icefury_buff) and { buffremaining(icefury_buff) < gcd() * 4 * buffstacks(icefury_buff) or buffpresent(stormkeeper_buff) or not hastalent(master_of_the_elements_talent) } and spell(frost_shock) or spell(lightning_bolt_elemental) or speed() > 0 and target.refreshable(flame_shock_debuff) and spell(flame_shock) or speed() > 0 and target.distance() > 6 and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

### actions.aoe

AddFunction elementalaoemainactions
{
 #flame_shock,target_if=refreshable&(spell_targets.chain_lightning<(5-!talent.totem_mastery.enabled)|!talent.storm_elemental.enabled&(cooldown.fire_elemental.remains>(cooldown.storm_elemental.duration-30+14*spell_haste)|cooldown.fire_elemental.remains<(24-14*spell_haste)))&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|spell_targets.chain_lightning=3&buff.wind_gust.stack<14)
 if target.refreshable(flame_shock_debuff) and { enemies() < 5 - hastalent(totem_mastery_talent_elemental no) or not hastalent(storm_elemental_talent) and { spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 + 14 * { 100 / { 100 + spellcastspeedpercent() } } or spellcooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + spellcastspeedpercent() } } } } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or enemies() == 3 and buffstacks(wind_gust_buff) < 14 } spell(flame_shock)
 #earthquake,if=!talent.master_of_the_elements.enabled|buff.stormkeeper.up|maelstrom>=(100-4*spell_targets.chain_lightning)|buff.master_of_the_elements.up|spell_targets.chain_lightning>3
 if not hastalent(master_of_the_elements_talent) or buffpresent(stormkeeper_buff) or maelstrom() >= 100 - 4 * enemies() or buffpresent(master_of_the_elements_buff) or enemies() > 3 spell(earthquake)
 #chain_lightning,if=buff.stormkeeper.remains<3*gcd*buff.stormkeeper.stack
 if buffremaining(stormkeeper_buff) < 3 * gcd() * buffstacks(stormkeeper_buff) spell(chain_lightning_elemental)
 #lava_burst,if=buff.lava_surge.up&spell_targets.chain_lightning<4&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30))&dot.flame_shock.ticking
 if buffpresent(lava_surge_buff) and enemies() < 4 and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } and target.debuffpresent(flame_shock_debuff) spell(lava_burst)
 #frost_shock,if=spell_targets.chain_lightning<4&buff.icefury.up&!buff.ascendance.up
 if enemies() < 4 and buffpresent(icefury_buff) and not buffpresent(ascendance_elemental_buff) spell(frost_shock)
 #elemental_blast,if=talent.elemental_blast.enabled&spell_targets.chain_lightning<4&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30))
 if hastalent(elemental_blast_talent) and enemies() < 4 and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } spell(elemental_blast)
 #lava_beam,if=talent.ascendance.enabled
 if hastalent(ascendance_talent) spell(lava_beam)
 #chain_lightning
 spell(chain_lightning_elemental)
 #lava_burst,moving=1,if=talent.ascendance.enabled
 if speed() > 0 and hastalent(ascendance_talent) spell(lava_burst)
 #flame_shock,moving=1,target_if=refreshable
 if speed() > 0 and target.refreshable(flame_shock_debuff) spell(flame_shock)
 #frost_shock,moving=1
 if speed() > 0 spell(frost_shock)
}

AddFunction elementalaoemainpostconditions
{
}

AddFunction elementalaoeshortcdactions
{
 #stormkeeper,if=talent.stormkeeper.enabled
 if hastalent(stormkeeper_talent) spell(stormkeeper)

 unless target.refreshable(flame_shock_debuff) and { enemies() < 5 - hastalent(totem_mastery_talent_elemental no) or not hastalent(storm_elemental_talent) and { spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 + 14 * { 100 / { 100 + spellcastspeedpercent() } } or spellcooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + spellcastspeedpercent() } } } } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or enemies() == 3 and buffstacks(wind_gust_buff) < 14 } and spell(flame_shock)
 {
  #liquid_magma_totem,if=talent.liquid_magma_totem.enabled
  if hastalent(liquid_magma_totem_talent) spell(liquid_magma_totem)

  unless { not hastalent(master_of_the_elements_talent) or buffpresent(stormkeeper_buff) or maelstrom() >= 100 - 4 * enemies() or buffpresent(master_of_the_elements_buff) or enemies() > 3 } and spell(earthquake) or buffremaining(stormkeeper_buff) < 3 * gcd() * buffstacks(stormkeeper_buff) and spell(chain_lightning_elemental) or buffpresent(lava_surge_buff) and enemies() < 4 and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } and target.debuffpresent(flame_shock_debuff) and spell(lava_burst)
  {
   #icefury,if=spell_targets.chain_lightning<4&!buff.ascendance.up
   if enemies() < 4 and not buffpresent(ascendance_elemental_buff) spell(icefury)
  }
 }
}

AddFunction elementalaoeshortcdpostconditions
{
 target.refreshable(flame_shock_debuff) and { enemies() < 5 - hastalent(totem_mastery_talent_elemental no) or not hastalent(storm_elemental_talent) and { spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 + 14 * { 100 / { 100 + spellcastspeedpercent() } } or spellcooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + spellcastspeedpercent() } } } } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or enemies() == 3 and buffstacks(wind_gust_buff) < 14 } and spell(flame_shock) or { not hastalent(master_of_the_elements_talent) or buffpresent(stormkeeper_buff) or maelstrom() >= 100 - 4 * enemies() or buffpresent(master_of_the_elements_buff) or enemies() > 3 } and spell(earthquake) or buffremaining(stormkeeper_buff) < 3 * gcd() * buffstacks(stormkeeper_buff) and spell(chain_lightning_elemental) or buffpresent(lava_surge_buff) and enemies() < 4 and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } and target.debuffpresent(flame_shock_debuff) and spell(lava_burst) or enemies() < 4 and buffpresent(icefury_buff) and not buffpresent(ascendance_elemental_buff) and spell(frost_shock) or hastalent(elemental_blast_talent) and enemies() < 4 and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } and spell(elemental_blast) or hastalent(ascendance_talent) and spell(lava_beam) or spell(chain_lightning_elemental) or speed() > 0 and hastalent(ascendance_talent) and spell(lava_burst) or speed() > 0 and target.refreshable(flame_shock_debuff) and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

AddFunction elementalaoecdactions
{
 unless hastalent(stormkeeper_talent) and spell(stormkeeper) or target.refreshable(flame_shock_debuff) and { enemies() < 5 - hastalent(totem_mastery_talent_elemental no) or not hastalent(storm_elemental_talent) and { spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 + 14 * { 100 / { 100 + spellcastspeedpercent() } } or spellcooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + spellcastspeedpercent() } } } } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or enemies() == 3 and buffstacks(wind_gust_buff) < 14 } and spell(flame_shock)
 {
  #ascendance,if=talent.ascendance.enabled&(talent.storm_elemental.enabled&cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)&cooldown.storm_elemental.remains>15|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
  if hastalent(ascendance_talent) and { hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 and spellcooldown(storm_elemental) > 15 or not hastalent(storm_elemental_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } and buffexpires(ascendance_elemental_buff) spell(ascendance_elemental)

  unless hastalent(liquid_magma_totem_talent) and spell(liquid_magma_totem) or { not hastalent(master_of_the_elements_talent) or buffpresent(stormkeeper_buff) or maelstrom() >= 100 - 4 * enemies() or buffpresent(master_of_the_elements_buff) or enemies() > 3 } and spell(earthquake)
  {
   #blood_of_the_enemy,if=!talent.primal_elementalist.enabled|!talent.storm_elemental.enabled
   if not hastalent(primal_elementalist_talent) or not hastalent(storm_elemental_talent) spell(blood_of_the_enemy)
  }
 }
}

AddFunction elementalaoecdpostconditions
{
 hastalent(stormkeeper_talent) and spell(stormkeeper) or target.refreshable(flame_shock_debuff) and { enemies() < 5 - hastalent(totem_mastery_talent_elemental no) or not hastalent(storm_elemental_talent) and { spellcooldown(fire_elemental) > spellcooldownduration(storm_elemental) - 30 + 14 * { 100 / { 100 + spellcastspeedpercent() } } or spellcooldown(fire_elemental) < 24 - 14 * { 100 / { 100 + spellcastspeedpercent() } } } } and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 or enemies() == 3 and buffstacks(wind_gust_buff) < 14 } and spell(flame_shock) or hastalent(liquid_magma_totem_talent) and spell(liquid_magma_totem) or { not hastalent(master_of_the_elements_talent) or buffpresent(stormkeeper_buff) or maelstrom() >= 100 - 4 * enemies() or buffpresent(master_of_the_elements_buff) or enemies() > 3 } and spell(earthquake) or buffremaining(stormkeeper_buff) < 3 * gcd() * buffstacks(stormkeeper_buff) and spell(chain_lightning_elemental) or buffpresent(lava_surge_buff) and enemies() < 4 and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } and target.debuffpresent(flame_shock_debuff) and spell(lava_burst) or enemies() < 4 and not buffpresent(ascendance_elemental_buff) and spell(icefury) or enemies() < 4 and buffpresent(icefury_buff) and not buffpresent(ascendance_elemental_buff) and spell(frost_shock) or hastalent(elemental_blast_talent) and enemies() < 4 and { not hastalent(storm_elemental_talent) or spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 } and spell(elemental_blast) or hastalent(ascendance_talent) and spell(lava_beam) or spell(chain_lightning_elemental) or speed() > 0 and hastalent(ascendance_talent) and spell(lava_burst) or speed() > 0 and target.refreshable(flame_shock_debuff) and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

### actions.default

AddFunction elemental_defaultmainactions
{
 #totem_mastery,if=talent.totem_mastery.enabled&buff.resonance_totem.remains<2
 if hastalent(totem_mastery_talent_elemental) and totemremaining(totem_mastery_elemental) < 2 spell(totem_mastery_elemental)
 #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
 if enemies() > 2 and { enemies() > 2 or enemies() > 2 } elementalaoemainactions()

 unless enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoemainpostconditions()
 {
  #run_action_list,name=funnel,if=active_enemies>=2&(spell_targets.chain_lightning<2|spell_targets.lava_beam<2)
  if enemies() >= 2 and { enemies() < 2 or enemies() < 2 } elementalfunnelmainactions()

  unless enemies() >= 2 and { enemies() < 2 or enemies() < 2 } and elementalfunnelmainpostconditions()
  {
   #run_action_list,name=single_target,if=active_enemies<=2
   if enemies() <= 2 elementalsingle_targetmainactions()
  }
 }
}

AddFunction elemental_defaultmainpostconditions
{
 enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoemainpostconditions() or enemies() >= 2 and { enemies() < 2 or enemies() < 2 } and elementalfunnelmainpostconditions() or enemies() <= 2 and elementalsingle_targetmainpostconditions()
}

AddFunction elemental_defaultshortcdactions
{
 unless hastalent(totem_mastery_talent_elemental) and totemremaining(totem_mastery_elemental) < 2 and spell(totem_mastery_elemental)
 {
  #purifying_blast
  spell(purifying_blast)
  #the_unbound_force
  spell(the_unbound_force)
  #ripple_in_space
  spell(ripple_in_space_essence)
  #worldvein_resonance,if=(talent.unlimited_power.enabled|buff.stormkeeper.up|talent.ascendance.enabled&((talent.storm_elemental.enabled&cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)&cooldown.storm_elemental.remains>15|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up))|!cooldown.ascendance.up)
  if hastalent(unlimited_power_talent) or buffpresent(stormkeeper_buff) or hastalent(ascendance_talent) and { hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 and spellcooldown(storm_elemental) > 15 or not hastalent(storm_elemental_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } or not { not spellcooldown(ascendance_elemental) > 0 } spell(worldvein_resonance_essence)
  #bag_of_tricks,if=!talent.ascendance.enabled|!buff.ascendance.up
  if not hastalent(ascendance_talent) or not buffpresent(ascendance_elemental_buff) spell(bag_of_tricks)
  #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
  if enemies() > 2 and { enemies() > 2 or enemies() > 2 } elementalaoeshortcdactions()

  unless enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoeshortcdpostconditions()
  {
   #run_action_list,name=funnel,if=active_enemies>=2&(spell_targets.chain_lightning<2|spell_targets.lava_beam<2)
   if enemies() >= 2 and { enemies() < 2 or enemies() < 2 } elementalfunnelshortcdactions()

   unless enemies() >= 2 and { enemies() < 2 or enemies() < 2 } and elementalfunnelshortcdpostconditions()
   {
    #run_action_list,name=single_target,if=active_enemies<=2
    if enemies() <= 2 elementalsingle_targetshortcdactions()
   }
  }
 }
}

AddFunction elemental_defaultshortcdpostconditions
{
 hastalent(totem_mastery_talent_elemental) and totemremaining(totem_mastery_elemental) < 2 and spell(totem_mastery_elemental) or enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoeshortcdpostconditions() or enemies() >= 2 and { enemies() < 2 or enemies() < 2 } and elementalfunnelshortcdpostconditions() or enemies() <= 2 and elementalsingle_targetshortcdpostconditions()
}

AddFunction elemental_defaultcdactions
{
 #bloodlust,if=azerite.ancestral_resonance.enabled
 if hasazeritetrait(ancestral_resonance_trait) elementalbloodlust()
 #potion,if=expected_combat_length-time<60|cooldown.guardian_of_azeroth.remains<30
 if { 600 - timeincombat() < 60 or spellcooldown(guardian_of_azeroth) < 30 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #wind_shear
 elementalinterruptactions()

 unless hastalent(totem_mastery_talent_elemental) and totemremaining(totem_mastery_elemental) < 2 and spell(totem_mastery_elemental)
 {
  #use_items
  elementaluseitemactions()
  #guardian_of_azeroth,if=dot.flame_shock.ticking&(!talent.storm_elemental.enabled&(cooldown.fire_elemental.duration-30<cooldown.fire_elemental.remains|expected_combat_length-time>190|expected_combat_length-time<32|!(cooldown.fire_elemental.remains+30<expected_combat_length-time)|cooldown.fire_elemental.remains<2)|talent.storm_elemental.enabled&(cooldown.storm_elemental.duration-30<cooldown.storm_elemental.remains|expected_combat_length-time>190|expected_combat_length-time<35|!(cooldown.storm_elemental.remains+30<expected_combat_length-time)|cooldown.storm_elemental.remains<2))
  if target.debuffpresent(flame_shock_debuff) and { not hastalent(storm_elemental_talent) and { spellcooldownduration(fire_elemental) - 30 < spellcooldown(fire_elemental) or 600 - timeincombat() > 190 or 600 - timeincombat() < 32 or not spellcooldown(fire_elemental) + 30 < 600 - timeincombat() or spellcooldown(fire_elemental) < 2 } or hastalent(storm_elemental_talent) and { spellcooldownduration(storm_elemental) - 30 < spellcooldown(storm_elemental) or 600 - timeincombat() > 190 or 600 - timeincombat() < 35 or not spellcooldown(storm_elemental) + 30 < 600 - timeincombat() or spellcooldown(storm_elemental) < 2 } } spell(guardian_of_azeroth)
  #fire_elemental,if=!talent.storm_elemental.enabled&(!essence.condensed_lifeforce.major|cooldown.guardian_of_azeroth.remains>150|expected_combat_length-time<30|expected_combat_length-time<60|expected_combat_length-time>155|!(cooldown.guardian_of_azeroth.remains+30<expected_combat_length-time))
  if not hastalent(storm_elemental_talent) and { not azeriteessenceismajor(condensed_life_force_essence_id) or spellcooldown(guardian_of_azeroth) > 150 or 600 - timeincombat() < 30 or 600 - timeincombat() < 60 or 600 - timeincombat() > 155 or not spellcooldown(guardian_of_azeroth) + 30 < 600 - timeincombat() } spell(fire_elemental)
  #focused_azerite_beam
  spell(focused_azerite_beam)

  unless spell(purifying_blast) or spell(the_unbound_force)
  {
   #memory_of_lucid_dreams
   spell(memory_of_lucid_dreams_essence)

   unless spell(ripple_in_space_essence) or { hastalent(unlimited_power_talent) or buffpresent(stormkeeper_buff) or hastalent(ascendance_talent) and { hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 and spellcooldown(storm_elemental) > 15 or not hastalent(storm_elemental_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } or not { not spellcooldown(ascendance_elemental) > 0 } } and spell(worldvein_resonance_essence)
   {
    #blood_of_the_enemy,if=talent.storm_elemental.enabled&pet.primal_storm_elemental.active
    if hastalent(storm_elemental_talent) and pet.present() spell(blood_of_the_enemy)
    #storm_elemental,if=talent.storm_elemental.enabled&(!cooldown.stormkeeper.up|!talent.stormkeeper.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)&(!talent.ascendance.enabled|!buff.ascendance.up|expected_combat_length-time<32)&(!essence.condensed_lifeforce.major|cooldown.guardian_of_azeroth.remains>150|expected_combat_length-time<30|expected_combat_length-time<60|expected_combat_length-time>155|!(cooldown.guardian_of_azeroth.remains+30<expected_combat_length-time))
    if hastalent(storm_elemental_talent) and { not { not spellcooldown(stormkeeper) > 0 } or not hastalent(stormkeeper_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } and { not hastalent(ascendance_talent) or not buffpresent(ascendance_elemental_buff) or 600 - timeincombat() < 32 } and { not azeriteessenceismajor(condensed_life_force_essence_id) or spellcooldown(guardian_of_azeroth) > 150 or 600 - timeincombat() < 30 or 600 - timeincombat() < 60 or 600 - timeincombat() > 155 or not spellcooldown(guardian_of_azeroth) + 30 < 600 - timeincombat() } spell(storm_elemental)
    #blood_fury,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
    if not hastalent(ascendance_talent) or buffpresent(ascendance_elemental_buff) or spellcooldown(ascendance_elemental) > 50 spell(blood_fury_apsp)
    #berserking,if=!talent.ascendance.enabled|buff.ascendance.up
    if not hastalent(ascendance_talent) or buffpresent(ascendance_elemental_buff) spell(berserking)
    #fireblood,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
    if not hastalent(ascendance_talent) or buffpresent(ascendance_elemental_buff) or spellcooldown(ascendance_elemental) > 50 spell(fireblood)
    #ancestral_call,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
    if not hastalent(ascendance_talent) or buffpresent(ascendance_elemental_buff) or spellcooldown(ascendance_elemental) > 50 spell(ancestral_call)

    unless { not hastalent(ascendance_talent) or not buffpresent(ascendance_elemental_buff) } and spell(bag_of_tricks)
    {
     #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
     if enemies() > 2 and { enemies() > 2 or enemies() > 2 } elementalaoecdactions()

     unless enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoecdpostconditions()
     {
      #run_action_list,name=funnel,if=active_enemies>=2&(spell_targets.chain_lightning<2|spell_targets.lava_beam<2)
      if enemies() >= 2 and { enemies() < 2 or enemies() < 2 } elementalfunnelcdactions()

      unless enemies() >= 2 and { enemies() < 2 or enemies() < 2 } and elementalfunnelcdpostconditions()
      {
       #run_action_list,name=single_target,if=active_enemies<=2
       if enemies() <= 2 elementalsingle_targetcdactions()
      }
     }
    }
   }
  }
 }
}

AddFunction elemental_defaultcdpostconditions
{
 hastalent(totem_mastery_talent_elemental) and totemremaining(totem_mastery_elemental) < 2 and spell(totem_mastery_elemental) or spell(purifying_blast) or spell(the_unbound_force) or spell(ripple_in_space_essence) or { hastalent(unlimited_power_talent) or buffpresent(stormkeeper_buff) or hastalent(ascendance_talent) and { hastalent(storm_elemental_talent) and spellcooldown(storm_elemental) < spellcooldownduration(storm_elemental) - 30 and spellcooldown(storm_elemental) > 15 or not hastalent(storm_elemental_talent) } and { not hastalent(icefury_talent) or not buffpresent(icefury_buff) and not { not spellcooldown(icefury) > 0 } } or not { not spellcooldown(ascendance_elemental) > 0 } } and spell(worldvein_resonance_essence) or { not hastalent(ascendance_talent) or not buffpresent(ascendance_elemental_buff) } and spell(bag_of_tricks) or enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoecdpostconditions() or enemies() >= 2 and { enemies() < 2 or enemies() < 2 } and elementalfunnelcdpostconditions() or enemies() <= 2 and elementalsingle_targetcdpostconditions()
}

### Elemental icons.

AddCheckBox(opt_shaman_elemental_aoe l(aoe) default specialization=elemental)

AddIcon checkbox=!opt_shaman_elemental_aoe enemies=1 help=shortcd specialization=elemental
{
 if not incombat() elementalprecombatshortcdactions()
 elemental_defaultshortcdactions()
}

AddIcon checkbox=opt_shaman_elemental_aoe help=shortcd specialization=elemental
{
 if not incombat() elementalprecombatshortcdactions()
 elemental_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=elemental
{
 if not incombat() elementalprecombatmainactions()
 elemental_defaultmainactions()
}

AddIcon checkbox=opt_shaman_elemental_aoe help=aoe specialization=elemental
{
 if not incombat() elementalprecombatmainactions()
 elemental_defaultmainactions()
}

AddIcon checkbox=!opt_shaman_elemental_aoe enemies=1 help=cd specialization=elemental
{
 if not incombat() elementalprecombatcdactions()
 elemental_defaultcdactions()
}

AddIcon checkbox=opt_shaman_elemental_aoe help=cd specialization=elemental
{
 if not incombat() elementalprecombatcdactions()
 elemental_defaultcdactions()
}

### Required symbols
# ancestral_call
# ancestral_resonance_trait
# ascendance_elemental
# ascendance_elemental_buff
# ascendance_talent
# bag_of_tricks
# berserking
# blood_fury_apsp
# blood_of_the_enemy
# bloodlust
# bloodlust_buff
# call_the_thunder_talent
# capacitor_totem
# chain_lightning_elemental
# concentrated_flame_essence
# condensed_life_force_essence_id
# earth_elemental
# earth_shock
# earthquake
# echo_of_the_elementals_trait
# echo_of_the_elements_talent_elemental
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
# lava_beam
# lava_burst
# lava_shock_buff
# lava_shock_trait
# lava_surge_buff
# lightning_bolt_elemental
# lightning_lasso
# liquid_magma_totem
# liquid_magma_totem_talent
# master_of_the_elements_buff
# master_of_the_elements_talent
# memory_of_lucid_dreams_essence
# natural_harmony_trait
# primal_elementalist_talent
# purifying_blast
# quaking_palm
# reaping_flames
# ripple_in_space_essence
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
# unbridled_fury_item
# unlimited_power_talent
# war_stomp
# wind_gust_buff
# wind_shear
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("SHAMAN", "elemental", name, desc, code, "script")
    end
    do
        local name = "sc_t24_shaman_enhancement_earth"
        local desc = "[8.3] Simulationcraft: T24_Shaman_Enhancement_Earth"
        local code = [[
# Based on SimulationCraft profile "T24_Shaman_Enhancement_Earth".
#	class=shaman
#	spec=enhancement
#	talents=1102022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)


AddFunction rockslide_enabled
{
 not freezerburn_enabled() and hastalent(boulderfist_talent) and hastalent(landslide_talent) and hasazeritetrait(strength_of_earth_trait)
}

AddFunction freezerburn_enabled
{
 hastalent(hot_hand_talent) and hastalent(hailstorm_talent) and hasazeritetrait(primal_primer_trait)
}

AddFunction CLPool_SS
{
 enemies() == 1 or maelstrom() >= powercost(crash_lightning) + powercost(stormstrike)
}

AddFunction CLPool_LL
{
 enemies() == 1 or maelstrom() >= powercost(crash_lightning) + powercost(lava_lash)
}

AddFunction OCPool_FB
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(frostbrand) }
}

AddFunction OCPool_CL
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(crash_lightning) }
}

AddFunction OCPool_LL
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(lava_lash) }
}

AddFunction OCPool_SS
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(stormstrike) }
}

AddFunction OCPool
{
 enemies() > 1 or spellcooldown(lightning_bolt_enhancement) >= 2 * gcd()
}

AddFunction furyCheck_LB
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + 40 }
}

AddFunction furyCheck_ES
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(earthen_spike) }
}

AddFunction furyCheck_FB
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(frostbrand) }
}

AddFunction furyCheck_CL
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(crash_lightning) }
}

AddFunction furyCheck_LL
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(lava_lash) }
}

AddFunction furyCheck_SS
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(stormstrike) }
}

AddFunction cooldown_sync
{
 hastalent(ascendance_talent_enhancement) and { buffpresent(ascendance_enhancement_buff) or spellcooldown(ascendance_enhancement) > 50 } or not hastalent(ascendance_talent_enhancement) and { totemremaining(sprit_wolf) > 5 or spellcooldown(feral_spirit) > 50 }
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=enhancement)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=enhancement)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=enhancement)
AddCheckBox(opt_bloodlust spellname(bloodlust) specialization=enhancement)

AddFunction enhancementinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(wind_shear) and target.isinterruptible() spell(wind_shear)
  if target.distance(less 5) and not target.classification(worldboss) spell(sundering)
  if not target.classification(worldboss) and target.remainingcasttime() > 2 spell(capacitor_totem)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.inrange(hex) and not target.classification(worldboss) and target.remainingcasttime() > casttime(hex) + gcdremaining() and target.creaturetype(humanoid beast) spell(hex)
 }
}

AddFunction enhancementuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction enhancementbloodlust
{
 if checkboxon(opt_bloodlust) and debuffexpires(burst_haste_debuff any=1)
 {
  spell(bloodlust)
  spell(heroism)
 }
}

AddFunction enhancementgetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(stormstrike)
 {
  if target.inrange(feral_lunge) spell(feral_lunge)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.priority

AddFunction enhancementprioritymainactions
{
 #crash_lightning,if=active_enemies>=(8-(talent.forceful_winds.enabled*3))&variable.freezerburn_enabled&variable.furyCheck_CL
 if enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() spell(crash_lightning)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&active_enemies=1&variable.freezerburn_enabled&variable.furyCheck_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() spell(lava_lash)
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #fury_of_air,if=!buff.fury_of_air.up&maelstrom>=20&spell_targets.fury_of_air_damage>=(1+variable.freezerburn_enabled)
 if not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() spell(fury_of_air)
 #fury_of_air,if=buff.fury_of_air.up&&spell_targets.fury_of_air_damage<(1+variable.freezerburn_enabled)
 if buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() spell(fury_of_air)
 #totem_mastery,if=buff.resonance_totem.remains<=2*gcd
 if totemremaining(totem_mastery_enhancement) <= 2 * gcd() spell(totem_mastery_enhancement)
 #sundering,if=active_enemies>=3&(!essence.blood_of_the_enemy.major|(essence.blood_of_the_enemy.major&(buff.seething_rage.up|cooldown.blood_of_the_enemy.remains>40)))
 if enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } spell(sundering)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 spell(rockbiter)
 #frostbrand,if=(azerite.natural_harmony.enabled&buff.natural_harmony_frost.remains<=2*gcd)&talent.hailstorm.enabled&variable.furyCheck_FB
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() spell(frostbrand)
 #flametongue,if=(azerite.natural_harmony.enabled&buff.natural_harmony_fire.remains<=2*gcd)
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() spell(flametongue)
 #rockbiter,if=(azerite.natural_harmony.enabled&buff.natural_harmony_nature.remains<=2*gcd)&maelstrom<70
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 spell(rockbiter)
}

AddFunction enhancementprioritymainpostconditions
{
}

AddFunction enhancementpriorityshortcdactions
{
 unless enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning)
 {
  #the_unbound_force,if=buff.reckless_force.up|time<5
  if buffpresent(reckless_force_buff) or timeincombat() < 5 spell(the_unbound_force)

  unless azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering)
  {
   #purifying_blast,if=active_enemies>1
   if enemies() > 1 spell(purifying_blast)
   #ripple_in_space,if=active_enemies>1
   if enemies() > 1 spell(ripple_in_space_essence)
  }
 }
}

AddFunction enhancementpriorityshortcdpostconditions
{
 enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() and spell(frostbrand) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() and spell(flametongue) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 and spell(rockbiter)
}

AddFunction enhancementprioritycdactions
{
 unless enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or { buffpresent(reckless_force_buff) or timeincombat() < 5 } and spell(the_unbound_force) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering)
 {
  #focused_azerite_beam,if=active_enemies>1
  if enemies() > 1 spell(focused_azerite_beam)
 }
}

AddFunction enhancementprioritycdpostconditions
{
 enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or { buffpresent(reckless_force_buff) or timeincombat() < 5 } and spell(the_unbound_force) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering) or enemies() > 1 and spell(purifying_blast) or enemies() > 1 and spell(ripple_in_space_essence) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() and spell(frostbrand) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() and spell(flametongue) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 and spell(rockbiter)
}

### actions.precombat

AddFunction enhancementprecombatmainactions
{
 #lightning_shield
 spell(lightning_shield)
}

AddFunction enhancementprecombatmainpostconditions
{
}

AddFunction enhancementprecombatshortcdactions
{
}

AddFunction enhancementprecombatshortcdpostconditions
{
 spell(lightning_shield)
}

AddFunction enhancementprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless spell(lightning_shield)
 {
  #use_item,name=azsharas_font_of_power
  enhancementuseitemactions()
 }
}

AddFunction enhancementprecombatcdpostconditions
{
 spell(lightning_shield)
}

### actions.opener

AddFunction enhancementopenermainactions
{
 #rockbiter,if=maelstrom<15&time<gcd
 if maelstrom() < 15 and timeincombat() < gcd() spell(rockbiter)
}

AddFunction enhancementopenermainpostconditions
{
}

AddFunction enhancementopenershortcdactions
{
}

AddFunction enhancementopenershortcdpostconditions
{
 maelstrom() < 15 and timeincombat() < gcd() and spell(rockbiter)
}

AddFunction enhancementopenercdactions
{
}

AddFunction enhancementopenercdpostconditions
{
 maelstrom() < 15 and timeincombat() < gcd() and spell(rockbiter)
}

### actions.maintenance

AddFunction enhancementmaintenancemainactions
{
 #flametongue,if=!buff.flametongue.up
 if not buffpresent(flametongue_buff) spell(flametongue)
 #frostbrand,if=talent.hailstorm.enabled&!buff.frostbrand.up&variable.furyCheck_FB
 if hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() spell(frostbrand)
}

AddFunction enhancementmaintenancemainpostconditions
{
}

AddFunction enhancementmaintenanceshortcdactions
{
}

AddFunction enhancementmaintenanceshortcdpostconditions
{
 not buffpresent(flametongue_buff) and spell(flametongue) or hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() and spell(frostbrand)
}

AddFunction enhancementmaintenancecdactions
{
}

AddFunction enhancementmaintenancecdpostconditions
{
 not buffpresent(flametongue_buff) and spell(flametongue) or hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() and spell(frostbrand)
}

### actions.freezerburn_core

AddFunction enhancementfreezerburn_coremainactions
{
 #lava_lash,target_if=max:debuff.primal_primer.stack,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&variable.furyCheck_LL&variable.CLPool_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() spell(lava_lash)
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if enemies() >= 3 and furyCheck_CL() spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 spell(lightning_bolt_enhancement)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack>7&variable.furyCheck_LL&variable.CLPool_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() spell(lava_lash)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS&variable.CLPool_SS
 if OCPool_SS() and furyCheck_SS() and CLPool_SS() spell(stormstrike)
 #lava_lash,if=debuff.primal_primer.stack=10&variable.furyCheck_LL
 if target.debuffstacks(primal_primer) == 10 and furyCheck_LL() spell(lava_lash)
}

AddFunction enhancementfreezerburn_coremainpostconditions
{
}

AddFunction enhancementfreezerburn_coreshortcdactions
{
}

AddFunction enhancementfreezerburn_coreshortcdpostconditions
{
 azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and spell(stormstrike) or target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and spell(lava_lash)
}

AddFunction enhancementfreezerburn_corecdactions
{
}

AddFunction enhancementfreezerburn_corecdpostconditions
{
 azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and spell(stormstrike) or target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and spell(lava_lash)
}

### actions.filler

AddFunction enhancementfillermainactions
{
 #sundering,if=raid_event.adds.in>40
 if 600 > 40 spell(sundering)
 #concentrated_flame
 spell(concentrated_flame_essence)
 #crash_lightning,if=talent.forceful_winds.enabled&active_enemies>1&variable.furyCheck_CL
 if hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #flametongue,if=talent.searing_assault.enabled
 if hastalent(searing_assault_talent) spell(flametongue)
 #lava_lash,if=!azerite.primal_primer.enabled&talent.hot_hand.enabled&buff.hot_hand.react
 if not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) spell(lava_lash)
 #crash_lightning,if=active_enemies>1&variable.furyCheck_CL
 if enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #rockbiter,if=maelstrom<70&!buff.strength_of_earth.up
 if maelstrom() < 70 and not buffpresent(strength_of_earth_buff) spell(rockbiter)
 #crash_lightning,if=(talent.crashing_storm.enabled|talent.forceful_winds.enabled)&variable.OCPool_CL
 if { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() spell(crash_lightning)
 #lava_lash,if=variable.OCPool_LL&variable.furyCheck_LL
 if OCPool_LL() and furyCheck_LL() spell(lava_lash)
 #rockbiter
 spell(rockbiter)
 #frostbrand,if=talent.hailstorm.enabled&buff.frostbrand.remains<4.8+gcd&variable.furyCheck_FB
 if hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() spell(frostbrand)
 #flametongue
 spell(flametongue)
}

AddFunction enhancementfillermainpostconditions
{
}

AddFunction enhancementfillershortcdactions
{
 unless 600 > 40 and spell(sundering)
 {
  #purifying_blast,if=raid_event.adds.in>60
  if 600 > 60 spell(purifying_blast)
  #ripple_in_space,if=raid_event.adds.in>60
  if 600 > 60 spell(ripple_in_space_essence)
  #thundercharge
  spell(thundercharge)

  unless spell(concentrated_flame_essence)
  {
   #reaping_flames
   spell(reaping_flames)
   #bag_of_tricks
   spell(bag_of_tricks)
  }
 }
}

AddFunction enhancementfillershortcdpostconditions
{
 600 > 40 and spell(sundering) or spell(concentrated_flame_essence) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash) or spell(rockbiter) or hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() and spell(frostbrand) or spell(flametongue)
}

AddFunction enhancementfillercdactions
{
 unless 600 > 40 and spell(sundering)
 {
  #focused_azerite_beam,if=raid_event.adds.in>90&!buff.ascendance.up&!buff.molten_weapon.up&!buff.icy_edge.up&!buff.crackling_surge.up&!debuff.earthen_spike.up
  if 600 > 90 and not buffpresent(ascendance_enhancement_buff) and not buffpresent(molten_weapon_buff) and not buffpresent(icy_edge_buff) and not buffpresent(crackling_surge) and not target.debuffpresent(earthen_spike_debuff) spell(focused_azerite_beam)

  unless 600 > 60 and spell(purifying_blast) or 600 > 60 and spell(ripple_in_space_essence) or spell(thundercharge) or spell(concentrated_flame_essence) or spell(reaping_flames) or spell(bag_of_tricks) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash)
  {
   #memory_of_lucid_dreams
   spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction enhancementfillercdpostconditions
{
 600 > 40 and spell(sundering) or 600 > 60 and spell(purifying_blast) or 600 > 60 and spell(ripple_in_space_essence) or spell(thundercharge) or spell(concentrated_flame_essence) or spell(reaping_flames) or spell(bag_of_tricks) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash) or spell(rockbiter) or hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() and spell(frostbrand) or spell(flametongue)
}

### actions.default_core

AddFunction enhancementdefault_coremainactions
{
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if enemies() >= 3 and furyCheck_CL() spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 spell(lightning_bolt_enhancement)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS
 if OCPool_SS() and furyCheck_SS() spell(stormstrike)
}

AddFunction enhancementdefault_coremainpostconditions
{
}

AddFunction enhancementdefault_coreshortcdactions
{
}

AddFunction enhancementdefault_coreshortcdpostconditions
{
 furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and spell(stormstrike)
}

AddFunction enhancementdefault_corecdactions
{
}

AddFunction enhancementdefault_corecdpostconditions
{
 furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and spell(stormstrike)
}

### actions.cds

AddFunction enhancementcdsmainactions
{
}

AddFunction enhancementcdsmainpostconditions
{
}

AddFunction enhancementcdsshortcdactions
{
 #worldvein_resonance
 spell(worldvein_resonance_essence)
}

AddFunction enhancementcdsshortcdpostconditions
{
}

AddFunction enhancementcdscdactions
{
 #bloodlust,if=azerite.ancestral_resonance.enabled
 if hasazeritetrait(ancestral_resonance_trait) enhancementbloodlust()

 unless spell(worldvein_resonance_essence)
 {
  #berserking,if=variable.cooldown_sync
  if cooldown_sync() spell(berserking)
  #use_item,name=azsharas_font_of_power
  enhancementuseitemactions()
  #blood_fury,if=variable.cooldown_sync
  if cooldown_sync() spell(blood_fury_apsp)
  #fireblood,if=variable.cooldown_sync
  if cooldown_sync() spell(fireblood)
  #ancestral_call,if=variable.cooldown_sync
  if cooldown_sync() spell(ancestral_call)
  #potion,if=buff.ascendance.up|!talent.ascendance.enabled&feral_spirit.remains>5|target.time_to_die<=60
  if { buffpresent(ascendance_enhancement_buff) or not hastalent(ascendance_talent_enhancement) and totemremaining(sprit_wolf) > 5 or target.timetodie() <= 60 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #feral_spirit
  spell(feral_spirit)
  #blood_of_the_enemy,if=raid_event.adds.in>90|active_enemies>1
  if 600 > 90 or enemies() > 1 spell(blood_of_the_enemy)
  #ascendance,if=cooldown.strike.remains>0
  if spellcooldown(windstrike) > 0 and buffexpires(ascendance_enhancement_buff) spell(ascendance_enhancement)
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|(target.time_to_die<20&debuff.razor_coral_debuff.stack>2)
  if target.debuffexpires(razor_coral) or target.timetodie() < 20 and target.debuffstacks(razor_coral) > 2 enhancementuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.stack>2&debuff.conductive_ink_debuff.down&(buff.ascendance.remains>10|buff.molten_weapon.remains>10|buff.crackling_surge.remains>10|buff.icy_edge.remains>10|debuff.earthen_spike.remains>6)
  if target.debuffstacks(razor_coral) > 2 and target.debuffexpires(conductive_ink) and { buffremaining(ascendance_enhancement_buff) > 10 or buffremaining(molten_weapon_buff) > 10 or buffremaining(crackling_surge) > 10 or buffremaining(icy_edge_buff) > 10 or target.debuffremaining(earthen_spike_debuff) > 6 } enhancementuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=(debuff.conductive_ink_debuff.up|buff.ascendance.remains>10|buff.molten_weapon.remains>10|buff.crackling_surge.remains>10|buff.icy_edge.remains>10|debuff.earthen_spike.remains>6)&target.health.pct<31
  if { target.debuffpresent(conductive_ink) or buffremaining(ascendance_enhancement_buff) > 10 or buffremaining(molten_weapon_buff) > 10 or buffremaining(crackling_surge) > 10 or buffremaining(icy_edge_buff) > 10 or target.debuffremaining(earthen_spike_debuff) > 6 } and target.healthpercent() < 31 enhancementuseitemactions()
  #use_items
  enhancementuseitemactions()
  #earth_elemental
  spell(earth_elemental)
 }
}

AddFunction enhancementcdscdpostconditions
{
 spell(worldvein_resonance_essence)
}

### actions.asc

AddFunction enhancementascmainactions
{
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 spell(rockbiter)
 #windstrike
 spell(windstrike)
}

AddFunction enhancementascmainpostconditions
{
}

AddFunction enhancementascshortcdactions
{
}

AddFunction enhancementascshortcdpostconditions
{
 not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or spell(windstrike)
}

AddFunction enhancementasccdactions
{
}

AddFunction enhancementasccdpostconditions
{
 not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or spell(windstrike)
}

### actions.default

AddFunction enhancement_defaultmainactions
{
 #call_action_list,name=opener
 enhancementopenermainactions()

 unless enhancementopenermainpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementascmainactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementascmainpostconditions()
  {
   #call_action_list,name=priority
   enhancementprioritymainactions()

   unless enhancementprioritymainpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenancemainactions()

    unless enemies() < 3 and enhancementmaintenancemainpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdsmainactions()

     unless enhancementcdsmainpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_coremainactions()

      unless freezerburn_enabled() and enhancementfreezerburn_coremainpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_coremainactions()

       unless not freezerburn_enabled() and enhancementdefault_coremainpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenancemainactions()

        unless enemies() >= 3 and enhancementmaintenancemainpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillermainactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultmainpostconditions
{
 enhancementopenermainpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementascmainpostconditions() or enhancementprioritymainpostconditions() or enemies() < 3 and enhancementmaintenancemainpostconditions() or enhancementcdsmainpostconditions() or freezerburn_enabled() and enhancementfreezerburn_coremainpostconditions() or not freezerburn_enabled() and enhancementdefault_coremainpostconditions() or enemies() >= 3 and enhancementmaintenancemainpostconditions() or enhancementfillermainpostconditions()
}

AddFunction enhancement_defaultshortcdactions
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
 enhancementgetinmeleerange()
 #call_action_list,name=opener
 enhancementopenershortcdactions()

 unless enhancementopenershortcdpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementascshortcdactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementascshortcdpostconditions()
  {
   #call_action_list,name=priority
   enhancementpriorityshortcdactions()

   unless enhancementpriorityshortcdpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenanceshortcdactions()

    unless enemies() < 3 and enhancementmaintenanceshortcdpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdsshortcdactions()

     unless enhancementcdsshortcdpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_coreshortcdactions()

      unless freezerburn_enabled() and enhancementfreezerburn_coreshortcdpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_coreshortcdactions()

       unless not freezerburn_enabled() and enhancementdefault_coreshortcdpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenanceshortcdactions()

        unless enemies() >= 3 and enhancementmaintenanceshortcdpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillershortcdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultshortcdpostconditions
{
 enhancementopenershortcdpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementascshortcdpostconditions() or enhancementpriorityshortcdpostconditions() or enemies() < 3 and enhancementmaintenanceshortcdpostconditions() or enhancementcdsshortcdpostconditions() or freezerburn_enabled() and enhancementfreezerburn_coreshortcdpostconditions() or not freezerburn_enabled() and enhancementdefault_coreshortcdpostconditions() or enemies() >= 3 and enhancementmaintenanceshortcdpostconditions() or enhancementfillershortcdpostconditions()
}

AddFunction enhancement_defaultcdactions
{
 #wind_shear
 enhancementinterruptactions()
 #call_action_list,name=opener
 enhancementopenercdactions()

 unless enhancementopenercdpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementasccdactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementasccdpostconditions()
  {
   #call_action_list,name=priority
   enhancementprioritycdactions()

   unless enhancementprioritycdpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenancecdactions()

    unless enemies() < 3 and enhancementmaintenancecdpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdscdactions()

     unless enhancementcdscdpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_corecdactions()

      unless freezerburn_enabled() and enhancementfreezerburn_corecdpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_corecdactions()

       unless not freezerburn_enabled() and enhancementdefault_corecdpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenancecdactions()

        unless enemies() >= 3 and enhancementmaintenancecdpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillercdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultcdpostconditions
{
 enhancementopenercdpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementasccdpostconditions() or enhancementprioritycdpostconditions() or enemies() < 3 and enhancementmaintenancecdpostconditions() or enhancementcdscdpostconditions() or freezerburn_enabled() and enhancementfreezerburn_corecdpostconditions() or not freezerburn_enabled() and enhancementdefault_corecdpostconditions() or enemies() >= 3 and enhancementmaintenancecdpostconditions() or enhancementfillercdpostconditions()
}

### Enhancement icons.

AddCheckBox(opt_shaman_enhancement_aoe l(aoe) default specialization=enhancement)

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=shortcd specialization=enhancement
{
 if not incombat() enhancementprecombatshortcdactions()
 enhancement_defaultshortcdactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=shortcd specialization=enhancement
{
 if not incombat() enhancementprecombatshortcdactions()
 enhancement_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=enhancement
{
 if not incombat() enhancementprecombatmainactions()
 enhancement_defaultmainactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=aoe specialization=enhancement
{
 if not incombat() enhancementprecombatmainactions()
 enhancement_defaultmainactions()
}

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=cd specialization=enhancement
{
 if not incombat() enhancementprecombatcdactions()
 enhancement_defaultcdactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=cd specialization=enhancement
{
 if not incombat() enhancementprecombatcdactions()
 enhancement_defaultcdactions()
}

### Required symbols
# ancestral_call
# ancestral_resonance_trait
# ascendance_enhancement
# ascendance_enhancement_buff
# ascendance_talent_enhancement
# bag_of_tricks
# berserking
# blood_fury_apsp
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodlust
# boulderfist_talent
# capacitor_totem
# concentrated_flame_essence
# conductive_ink
# crackling_surge
# crash_lightning
# crash_lightning_buff
# crashing_storm_talent
# earth_elemental
# earthen_spike
# earthen_spike_debuff
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
# icy_edge_buff
# landslide_buff
# landslide_talent
# lava_lash
# lightning_bolt_enhancement
# lightning_conduit_debuff
# lightning_conduit_trait
# lightning_shield
# memory_of_lucid_dreams_essence
# molten_weapon_buff
# natural_harmony_fire
# natural_harmony_frost
# natural_harmony_nature
# natural_harmony_trait
# overcharge_talent
# primal_primer
# primal_primer_trait
# purifying_blast
# quaking_palm
# razor_coral
# reaping_flames
# reckless_force_buff
# ripple_in_space_essence
# rockbiter
# searing_assault_talent
# seething_rage
# stormbringer_buff
# stormstrike
# strength_of_earth_buff
# strength_of_earth_trait
# sundering
# the_unbound_force
# thundercharge
# totem_mastery_enhancement
# unbridled_fury_item
# war_stomp
# wind_shear
# windstrike
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
    end
    do
        local name = "sc_t24_shaman_enhancement_fire"
        local desc = "[8.3] Simulationcraft: T24_Shaman_Enhancement_Fire"
        local code = [[
# Based on SimulationCraft profile "T24_Shaman_Enhancement_Fire".
#	class=shaman
#	spec=enhancement
#	talents=2302031

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)


AddFunction rockslide_enabled
{
 not freezerburn_enabled() and hastalent(boulderfist_talent) and hastalent(landslide_talent) and hasazeritetrait(strength_of_earth_trait)
}

AddFunction freezerburn_enabled
{
 hastalent(hot_hand_talent) and hastalent(hailstorm_talent) and hasazeritetrait(primal_primer_trait)
}

AddFunction CLPool_SS
{
 enemies() == 1 or maelstrom() >= powercost(crash_lightning) + powercost(stormstrike)
}

AddFunction CLPool_LL
{
 enemies() == 1 or maelstrom() >= powercost(crash_lightning) + powercost(lava_lash)
}

AddFunction OCPool_FB
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(frostbrand) }
}

AddFunction OCPool_CL
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(crash_lightning) }
}

AddFunction OCPool_LL
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(lava_lash) }
}

AddFunction OCPool_SS
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(stormstrike) }
}

AddFunction OCPool
{
 enemies() > 1 or spellcooldown(lightning_bolt_enhancement) >= 2 * gcd()
}

AddFunction furyCheck_LB
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + 40 }
}

AddFunction furyCheck_ES
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(earthen_spike) }
}

AddFunction furyCheck_FB
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(frostbrand) }
}

AddFunction furyCheck_CL
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(crash_lightning) }
}

AddFunction furyCheck_LL
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(lava_lash) }
}

AddFunction furyCheck_SS
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(stormstrike) }
}

AddFunction cooldown_sync
{
 hastalent(ascendance_talent_enhancement) and { buffpresent(ascendance_enhancement_buff) or spellcooldown(ascendance_enhancement) > 50 } or not hastalent(ascendance_talent_enhancement) and { totemremaining(sprit_wolf) > 5 or spellcooldown(feral_spirit) > 50 }
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=enhancement)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=enhancement)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=enhancement)
AddCheckBox(opt_bloodlust spellname(bloodlust) specialization=enhancement)

AddFunction enhancementinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(wind_shear) and target.isinterruptible() spell(wind_shear)
  if target.distance(less 5) and not target.classification(worldboss) spell(sundering)
  if not target.classification(worldboss) and target.remainingcasttime() > 2 spell(capacitor_totem)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.inrange(hex) and not target.classification(worldboss) and target.remainingcasttime() > casttime(hex) + gcdremaining() and target.creaturetype(humanoid beast) spell(hex)
 }
}

AddFunction enhancementuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction enhancementbloodlust
{
 if checkboxon(opt_bloodlust) and debuffexpires(burst_haste_debuff any=1)
 {
  spell(bloodlust)
  spell(heroism)
 }
}

AddFunction enhancementgetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(stormstrike)
 {
  if target.inrange(feral_lunge) spell(feral_lunge)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.priority

AddFunction enhancementprioritymainactions
{
 #crash_lightning,if=active_enemies>=(8-(talent.forceful_winds.enabled*3))&variable.freezerburn_enabled&variable.furyCheck_CL
 if enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() spell(crash_lightning)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&active_enemies=1&variable.freezerburn_enabled&variable.furyCheck_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() spell(lava_lash)
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #fury_of_air,if=!buff.fury_of_air.up&maelstrom>=20&spell_targets.fury_of_air_damage>=(1+variable.freezerburn_enabled)
 if not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() spell(fury_of_air)
 #fury_of_air,if=buff.fury_of_air.up&&spell_targets.fury_of_air_damage<(1+variable.freezerburn_enabled)
 if buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() spell(fury_of_air)
 #totem_mastery,if=buff.resonance_totem.remains<=2*gcd
 if totemremaining(totem_mastery_enhancement) <= 2 * gcd() spell(totem_mastery_enhancement)
 #sundering,if=active_enemies>=3&(!essence.blood_of_the_enemy.major|(essence.blood_of_the_enemy.major&(buff.seething_rage.up|cooldown.blood_of_the_enemy.remains>40)))
 if enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } spell(sundering)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 spell(rockbiter)
 #frostbrand,if=(azerite.natural_harmony.enabled&buff.natural_harmony_frost.remains<=2*gcd)&talent.hailstorm.enabled&variable.furyCheck_FB
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() spell(frostbrand)
 #flametongue,if=(azerite.natural_harmony.enabled&buff.natural_harmony_fire.remains<=2*gcd)
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() spell(flametongue)
 #rockbiter,if=(azerite.natural_harmony.enabled&buff.natural_harmony_nature.remains<=2*gcd)&maelstrom<70
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 spell(rockbiter)
}

AddFunction enhancementprioritymainpostconditions
{
}

AddFunction enhancementpriorityshortcdactions
{
 unless enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning)
 {
  #the_unbound_force,if=buff.reckless_force.up|time<5
  if buffpresent(reckless_force_buff) or timeincombat() < 5 spell(the_unbound_force)

  unless azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering)
  {
   #purifying_blast,if=active_enemies>1
   if enemies() > 1 spell(purifying_blast)
   #ripple_in_space,if=active_enemies>1
   if enemies() > 1 spell(ripple_in_space_essence)
  }
 }
}

AddFunction enhancementpriorityshortcdpostconditions
{
 enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() and spell(frostbrand) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() and spell(flametongue) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 and spell(rockbiter)
}

AddFunction enhancementprioritycdactions
{
 unless enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or { buffpresent(reckless_force_buff) or timeincombat() < 5 } and spell(the_unbound_force) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering)
 {
  #focused_azerite_beam,if=active_enemies>1
  if enemies() > 1 spell(focused_azerite_beam)
 }
}

AddFunction enhancementprioritycdpostconditions
{
 enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or { buffpresent(reckless_force_buff) or timeincombat() < 5 } and spell(the_unbound_force) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering) or enemies() > 1 and spell(purifying_blast) or enemies() > 1 and spell(ripple_in_space_essence) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() and spell(frostbrand) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() and spell(flametongue) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 and spell(rockbiter)
}

### actions.precombat

AddFunction enhancementprecombatmainactions
{
 #lightning_shield
 spell(lightning_shield)
}

AddFunction enhancementprecombatmainpostconditions
{
}

AddFunction enhancementprecombatshortcdactions
{
}

AddFunction enhancementprecombatshortcdpostconditions
{
 spell(lightning_shield)
}

AddFunction enhancementprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless spell(lightning_shield)
 {
  #use_item,name=azsharas_font_of_power
  enhancementuseitemactions()
 }
}

AddFunction enhancementprecombatcdpostconditions
{
 spell(lightning_shield)
}

### actions.opener

AddFunction enhancementopenermainactions
{
 #rockbiter,if=maelstrom<15&time<gcd
 if maelstrom() < 15 and timeincombat() < gcd() spell(rockbiter)
}

AddFunction enhancementopenermainpostconditions
{
}

AddFunction enhancementopenershortcdactions
{
}

AddFunction enhancementopenershortcdpostconditions
{
 maelstrom() < 15 and timeincombat() < gcd() and spell(rockbiter)
}

AddFunction enhancementopenercdactions
{
}

AddFunction enhancementopenercdpostconditions
{
 maelstrom() < 15 and timeincombat() < gcd() and spell(rockbiter)
}

### actions.maintenance

AddFunction enhancementmaintenancemainactions
{
 #flametongue,if=!buff.flametongue.up
 if not buffpresent(flametongue_buff) spell(flametongue)
 #frostbrand,if=talent.hailstorm.enabled&!buff.frostbrand.up&variable.furyCheck_FB
 if hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() spell(frostbrand)
}

AddFunction enhancementmaintenancemainpostconditions
{
}

AddFunction enhancementmaintenanceshortcdactions
{
}

AddFunction enhancementmaintenanceshortcdpostconditions
{
 not buffpresent(flametongue_buff) and spell(flametongue) or hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() and spell(frostbrand)
}

AddFunction enhancementmaintenancecdactions
{
}

AddFunction enhancementmaintenancecdpostconditions
{
 not buffpresent(flametongue_buff) and spell(flametongue) or hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() and spell(frostbrand)
}

### actions.freezerburn_core

AddFunction enhancementfreezerburn_coremainactions
{
 #lava_lash,target_if=max:debuff.primal_primer.stack,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&variable.furyCheck_LL&variable.CLPool_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() spell(lava_lash)
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if enemies() >= 3 and furyCheck_CL() spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 spell(lightning_bolt_enhancement)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack>7&variable.furyCheck_LL&variable.CLPool_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() spell(lava_lash)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS&variable.CLPool_SS
 if OCPool_SS() and furyCheck_SS() and CLPool_SS() spell(stormstrike)
 #lava_lash,if=debuff.primal_primer.stack=10&variable.furyCheck_LL
 if target.debuffstacks(primal_primer) == 10 and furyCheck_LL() spell(lava_lash)
}

AddFunction enhancementfreezerburn_coremainpostconditions
{
}

AddFunction enhancementfreezerburn_coreshortcdactions
{
}

AddFunction enhancementfreezerburn_coreshortcdpostconditions
{
 azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and spell(stormstrike) or target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and spell(lava_lash)
}

AddFunction enhancementfreezerburn_corecdactions
{
}

AddFunction enhancementfreezerburn_corecdpostconditions
{
 azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and spell(stormstrike) or target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and spell(lava_lash)
}

### actions.filler

AddFunction enhancementfillermainactions
{
 #sundering,if=raid_event.adds.in>40
 if 600 > 40 spell(sundering)
 #concentrated_flame
 spell(concentrated_flame_essence)
 #crash_lightning,if=talent.forceful_winds.enabled&active_enemies>1&variable.furyCheck_CL
 if hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #flametongue,if=talent.searing_assault.enabled
 if hastalent(searing_assault_talent) spell(flametongue)
 #lava_lash,if=!azerite.primal_primer.enabled&talent.hot_hand.enabled&buff.hot_hand.react
 if not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) spell(lava_lash)
 #crash_lightning,if=active_enemies>1&variable.furyCheck_CL
 if enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #rockbiter,if=maelstrom<70&!buff.strength_of_earth.up
 if maelstrom() < 70 and not buffpresent(strength_of_earth_buff) spell(rockbiter)
 #crash_lightning,if=(talent.crashing_storm.enabled|talent.forceful_winds.enabled)&variable.OCPool_CL
 if { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() spell(crash_lightning)
 #lava_lash,if=variable.OCPool_LL&variable.furyCheck_LL
 if OCPool_LL() and furyCheck_LL() spell(lava_lash)
 #rockbiter
 spell(rockbiter)
 #frostbrand,if=talent.hailstorm.enabled&buff.frostbrand.remains<4.8+gcd&variable.furyCheck_FB
 if hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() spell(frostbrand)
 #flametongue
 spell(flametongue)
}

AddFunction enhancementfillermainpostconditions
{
}

AddFunction enhancementfillershortcdactions
{
 unless 600 > 40 and spell(sundering)
 {
  #purifying_blast,if=raid_event.adds.in>60
  if 600 > 60 spell(purifying_blast)
  #ripple_in_space,if=raid_event.adds.in>60
  if 600 > 60 spell(ripple_in_space_essence)
  #thundercharge
  spell(thundercharge)

  unless spell(concentrated_flame_essence)
  {
   #reaping_flames
   spell(reaping_flames)
   #bag_of_tricks
   spell(bag_of_tricks)
  }
 }
}

AddFunction enhancementfillershortcdpostconditions
{
 600 > 40 and spell(sundering) or spell(concentrated_flame_essence) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash) or spell(rockbiter) or hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() and spell(frostbrand) or spell(flametongue)
}

AddFunction enhancementfillercdactions
{
 unless 600 > 40 and spell(sundering)
 {
  #focused_azerite_beam,if=raid_event.adds.in>90&!buff.ascendance.up&!buff.molten_weapon.up&!buff.icy_edge.up&!buff.crackling_surge.up&!debuff.earthen_spike.up
  if 600 > 90 and not buffpresent(ascendance_enhancement_buff) and not buffpresent(molten_weapon_buff) and not buffpresent(icy_edge_buff) and not buffpresent(crackling_surge) and not target.debuffpresent(earthen_spike_debuff) spell(focused_azerite_beam)

  unless 600 > 60 and spell(purifying_blast) or 600 > 60 and spell(ripple_in_space_essence) or spell(thundercharge) or spell(concentrated_flame_essence) or spell(reaping_flames) or spell(bag_of_tricks) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash)
  {
   #memory_of_lucid_dreams
   spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction enhancementfillercdpostconditions
{
 600 > 40 and spell(sundering) or 600 > 60 and spell(purifying_blast) or 600 > 60 and spell(ripple_in_space_essence) or spell(thundercharge) or spell(concentrated_flame_essence) or spell(reaping_flames) or spell(bag_of_tricks) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash) or spell(rockbiter) or hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() and spell(frostbrand) or spell(flametongue)
}

### actions.default_core

AddFunction enhancementdefault_coremainactions
{
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if enemies() >= 3 and furyCheck_CL() spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 spell(lightning_bolt_enhancement)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS
 if OCPool_SS() and furyCheck_SS() spell(stormstrike)
}

AddFunction enhancementdefault_coremainpostconditions
{
}

AddFunction enhancementdefault_coreshortcdactions
{
}

AddFunction enhancementdefault_coreshortcdpostconditions
{
 furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and spell(stormstrike)
}

AddFunction enhancementdefault_corecdactions
{
}

AddFunction enhancementdefault_corecdpostconditions
{
 furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and spell(stormstrike)
}

### actions.cds

AddFunction enhancementcdsmainactions
{
}

AddFunction enhancementcdsmainpostconditions
{
}

AddFunction enhancementcdsshortcdactions
{
 #worldvein_resonance
 spell(worldvein_resonance_essence)
}

AddFunction enhancementcdsshortcdpostconditions
{
}

AddFunction enhancementcdscdactions
{
 #bloodlust,if=azerite.ancestral_resonance.enabled
 if hasazeritetrait(ancestral_resonance_trait) enhancementbloodlust()

 unless spell(worldvein_resonance_essence)
 {
  #berserking,if=variable.cooldown_sync
  if cooldown_sync() spell(berserking)
  #use_item,name=azsharas_font_of_power
  enhancementuseitemactions()
  #blood_fury,if=variable.cooldown_sync
  if cooldown_sync() spell(blood_fury_apsp)
  #fireblood,if=variable.cooldown_sync
  if cooldown_sync() spell(fireblood)
  #ancestral_call,if=variable.cooldown_sync
  if cooldown_sync() spell(ancestral_call)
  #potion,if=buff.ascendance.up|!talent.ascendance.enabled&feral_spirit.remains>5|target.time_to_die<=60
  if { buffpresent(ascendance_enhancement_buff) or not hastalent(ascendance_talent_enhancement) and totemremaining(sprit_wolf) > 5 or target.timetodie() <= 60 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #feral_spirit
  spell(feral_spirit)
  #blood_of_the_enemy,if=raid_event.adds.in>90|active_enemies>1
  if 600 > 90 or enemies() > 1 spell(blood_of_the_enemy)
  #ascendance,if=cooldown.strike.remains>0
  if spellcooldown(windstrike) > 0 and buffexpires(ascendance_enhancement_buff) spell(ascendance_enhancement)
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|(target.time_to_die<20&debuff.razor_coral_debuff.stack>2)
  if target.debuffexpires(razor_coral) or target.timetodie() < 20 and target.debuffstacks(razor_coral) > 2 enhancementuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.stack>2&debuff.conductive_ink_debuff.down&(buff.ascendance.remains>10|buff.molten_weapon.remains>10|buff.crackling_surge.remains>10|buff.icy_edge.remains>10|debuff.earthen_spike.remains>6)
  if target.debuffstacks(razor_coral) > 2 and target.debuffexpires(conductive_ink) and { buffremaining(ascendance_enhancement_buff) > 10 or buffremaining(molten_weapon_buff) > 10 or buffremaining(crackling_surge) > 10 or buffremaining(icy_edge_buff) > 10 or target.debuffremaining(earthen_spike_debuff) > 6 } enhancementuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=(debuff.conductive_ink_debuff.up|buff.ascendance.remains>10|buff.molten_weapon.remains>10|buff.crackling_surge.remains>10|buff.icy_edge.remains>10|debuff.earthen_spike.remains>6)&target.health.pct<31
  if { target.debuffpresent(conductive_ink) or buffremaining(ascendance_enhancement_buff) > 10 or buffremaining(molten_weapon_buff) > 10 or buffremaining(crackling_surge) > 10 or buffremaining(icy_edge_buff) > 10 or target.debuffremaining(earthen_spike_debuff) > 6 } and target.healthpercent() < 31 enhancementuseitemactions()
  #use_items
  enhancementuseitemactions()
  #earth_elemental
  spell(earth_elemental)
 }
}

AddFunction enhancementcdscdpostconditions
{
 spell(worldvein_resonance_essence)
}

### actions.asc

AddFunction enhancementascmainactions
{
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 spell(rockbiter)
 #windstrike
 spell(windstrike)
}

AddFunction enhancementascmainpostconditions
{
}

AddFunction enhancementascshortcdactions
{
}

AddFunction enhancementascshortcdpostconditions
{
 not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or spell(windstrike)
}

AddFunction enhancementasccdactions
{
}

AddFunction enhancementasccdpostconditions
{
 not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or spell(windstrike)
}

### actions.default

AddFunction enhancement_defaultmainactions
{
 #call_action_list,name=opener
 enhancementopenermainactions()

 unless enhancementopenermainpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementascmainactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementascmainpostconditions()
  {
   #call_action_list,name=priority
   enhancementprioritymainactions()

   unless enhancementprioritymainpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenancemainactions()

    unless enemies() < 3 and enhancementmaintenancemainpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdsmainactions()

     unless enhancementcdsmainpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_coremainactions()

      unless freezerburn_enabled() and enhancementfreezerburn_coremainpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_coremainactions()

       unless not freezerburn_enabled() and enhancementdefault_coremainpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenancemainactions()

        unless enemies() >= 3 and enhancementmaintenancemainpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillermainactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultmainpostconditions
{
 enhancementopenermainpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementascmainpostconditions() or enhancementprioritymainpostconditions() or enemies() < 3 and enhancementmaintenancemainpostconditions() or enhancementcdsmainpostconditions() or freezerburn_enabled() and enhancementfreezerburn_coremainpostconditions() or not freezerburn_enabled() and enhancementdefault_coremainpostconditions() or enemies() >= 3 and enhancementmaintenancemainpostconditions() or enhancementfillermainpostconditions()
}

AddFunction enhancement_defaultshortcdactions
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
 enhancementgetinmeleerange()
 #call_action_list,name=opener
 enhancementopenershortcdactions()

 unless enhancementopenershortcdpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementascshortcdactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementascshortcdpostconditions()
  {
   #call_action_list,name=priority
   enhancementpriorityshortcdactions()

   unless enhancementpriorityshortcdpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenanceshortcdactions()

    unless enemies() < 3 and enhancementmaintenanceshortcdpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdsshortcdactions()

     unless enhancementcdsshortcdpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_coreshortcdactions()

      unless freezerburn_enabled() and enhancementfreezerburn_coreshortcdpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_coreshortcdactions()

       unless not freezerburn_enabled() and enhancementdefault_coreshortcdpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenanceshortcdactions()

        unless enemies() >= 3 and enhancementmaintenanceshortcdpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillershortcdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultshortcdpostconditions
{
 enhancementopenershortcdpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementascshortcdpostconditions() or enhancementpriorityshortcdpostconditions() or enemies() < 3 and enhancementmaintenanceshortcdpostconditions() or enhancementcdsshortcdpostconditions() or freezerburn_enabled() and enhancementfreezerburn_coreshortcdpostconditions() or not freezerburn_enabled() and enhancementdefault_coreshortcdpostconditions() or enemies() >= 3 and enhancementmaintenanceshortcdpostconditions() or enhancementfillershortcdpostconditions()
}

AddFunction enhancement_defaultcdactions
{
 #wind_shear
 enhancementinterruptactions()
 #call_action_list,name=opener
 enhancementopenercdactions()

 unless enhancementopenercdpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementasccdactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementasccdpostconditions()
  {
   #call_action_list,name=priority
   enhancementprioritycdactions()

   unless enhancementprioritycdpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenancecdactions()

    unless enemies() < 3 and enhancementmaintenancecdpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdscdactions()

     unless enhancementcdscdpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_corecdactions()

      unless freezerburn_enabled() and enhancementfreezerburn_corecdpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_corecdactions()

       unless not freezerburn_enabled() and enhancementdefault_corecdpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenancecdactions()

        unless enemies() >= 3 and enhancementmaintenancecdpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillercdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultcdpostconditions
{
 enhancementopenercdpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementasccdpostconditions() or enhancementprioritycdpostconditions() or enemies() < 3 and enhancementmaintenancecdpostconditions() or enhancementcdscdpostconditions() or freezerburn_enabled() and enhancementfreezerburn_corecdpostconditions() or not freezerburn_enabled() and enhancementdefault_corecdpostconditions() or enemies() >= 3 and enhancementmaintenancecdpostconditions() or enhancementfillercdpostconditions()
}

### Enhancement icons.

AddCheckBox(opt_shaman_enhancement_aoe l(aoe) default specialization=enhancement)

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=shortcd specialization=enhancement
{
 if not incombat() enhancementprecombatshortcdactions()
 enhancement_defaultshortcdactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=shortcd specialization=enhancement
{
 if not incombat() enhancementprecombatshortcdactions()
 enhancement_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=enhancement
{
 if not incombat() enhancementprecombatmainactions()
 enhancement_defaultmainactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=aoe specialization=enhancement
{
 if not incombat() enhancementprecombatmainactions()
 enhancement_defaultmainactions()
}

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=cd specialization=enhancement
{
 if not incombat() enhancementprecombatcdactions()
 enhancement_defaultcdactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=cd specialization=enhancement
{
 if not incombat() enhancementprecombatcdactions()
 enhancement_defaultcdactions()
}

### Required symbols
# ancestral_call
# ancestral_resonance_trait
# ascendance_enhancement
# ascendance_enhancement_buff
# ascendance_talent_enhancement
# bag_of_tricks
# berserking
# blood_fury_apsp
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodlust
# boulderfist_talent
# capacitor_totem
# concentrated_flame_essence
# conductive_ink
# crackling_surge
# crash_lightning
# crash_lightning_buff
# crashing_storm_talent
# earth_elemental
# earthen_spike
# earthen_spike_debuff
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
# icy_edge_buff
# landslide_buff
# landslide_talent
# lava_lash
# lightning_bolt_enhancement
# lightning_conduit_debuff
# lightning_conduit_trait
# lightning_shield
# memory_of_lucid_dreams_essence
# molten_weapon_buff
# natural_harmony_fire
# natural_harmony_frost
# natural_harmony_nature
# natural_harmony_trait
# overcharge_talent
# primal_primer
# primal_primer_trait
# purifying_blast
# quaking_palm
# razor_coral
# reaping_flames
# reckless_force_buff
# ripple_in_space_essence
# rockbiter
# searing_assault_talent
# seething_rage
# stormbringer_buff
# stormstrike
# strength_of_earth_buff
# strength_of_earth_trait
# sundering
# the_unbound_force
# thundercharge
# totem_mastery_enhancement
# unbridled_fury_item
# war_stomp
# wind_shear
# windstrike
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
    end
    do
        local name = "sc_t24_shaman_enhancement_storm"
        local desc = "[8.3] Simulationcraft: T24_Shaman_Enhancement_Storm"
        local code = [[
# Based on SimulationCraft profile "T24_Shaman_Enhancement_Storm".
#	class=shaman
#	spec=enhancement
#	talents=3202033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)


AddFunction rockslide_enabled
{
 not freezerburn_enabled() and hastalent(boulderfist_talent) and hastalent(landslide_talent) and hasazeritetrait(strength_of_earth_trait)
}

AddFunction freezerburn_enabled
{
 hastalent(hot_hand_talent) and hastalent(hailstorm_talent) and hasazeritetrait(primal_primer_trait)
}

AddFunction CLPool_SS
{
 enemies() == 1 or maelstrom() >= powercost(crash_lightning) + powercost(stormstrike)
}

AddFunction CLPool_LL
{
 enemies() == 1 or maelstrom() >= powercost(crash_lightning) + powercost(lava_lash)
}

AddFunction OCPool_FB
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(frostbrand) }
}

AddFunction OCPool_CL
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(crash_lightning) }
}

AddFunction OCPool_LL
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(lava_lash) }
}

AddFunction OCPool_SS
{
 OCPool() or maelstrom() >= talentpoints(overcharge_talent) * { 40 + powercost(stormstrike) }
}

AddFunction OCPool
{
 enemies() > 1 or spellcooldown(lightning_bolt_enhancement) >= 2 * gcd()
}

AddFunction furyCheck_LB
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + 40 }
}

AddFunction furyCheck_ES
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(earthen_spike) }
}

AddFunction furyCheck_FB
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(frostbrand) }
}

AddFunction furyCheck_CL
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(crash_lightning) }
}

AddFunction furyCheck_LL
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(lava_lash) }
}

AddFunction furyCheck_SS
{
 maelstrom() >= talentpoints(fury_of_air_talent) * { 6 + powercost(stormstrike) }
}

AddFunction cooldown_sync
{
 hastalent(ascendance_talent_enhancement) and { buffpresent(ascendance_enhancement_buff) or spellcooldown(ascendance_enhancement) > 50 } or not hastalent(ascendance_talent_enhancement) and { totemremaining(sprit_wolf) > 5 or spellcooldown(feral_spirit) > 50 }
}

AddCheckBox(opt_interrupt l(interrupt) default specialization=enhancement)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=enhancement)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=enhancement)
AddCheckBox(opt_bloodlust spellname(bloodlust) specialization=enhancement)

AddFunction enhancementinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(wind_shear) and target.isinterruptible() spell(wind_shear)
  if target.distance(less 5) and not target.classification(worldboss) spell(sundering)
  if not target.classification(worldboss) and target.remainingcasttime() > 2 spell(capacitor_totem)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.inrange(hex) and not target.classification(worldboss) and target.remainingcasttime() > casttime(hex) + gcdremaining() and target.creaturetype(humanoid beast) spell(hex)
 }
}

AddFunction enhancementuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

AddFunction enhancementbloodlust
{
 if checkboxon(opt_bloodlust) and debuffexpires(burst_haste_debuff any=1)
 {
  spell(bloodlust)
  spell(heroism)
 }
}

AddFunction enhancementgetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(stormstrike)
 {
  if target.inrange(feral_lunge) spell(feral_lunge)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.priority

AddFunction enhancementprioritymainactions
{
 #crash_lightning,if=active_enemies>=(8-(talent.forceful_winds.enabled*3))&variable.freezerburn_enabled&variable.furyCheck_CL
 if enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() spell(crash_lightning)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&active_enemies=1&variable.freezerburn_enabled&variable.furyCheck_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() spell(lava_lash)
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #fury_of_air,if=!buff.fury_of_air.up&maelstrom>=20&spell_targets.fury_of_air_damage>=(1+variable.freezerburn_enabled)
 if not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() spell(fury_of_air)
 #fury_of_air,if=buff.fury_of_air.up&&spell_targets.fury_of_air_damage<(1+variable.freezerburn_enabled)
 if buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() spell(fury_of_air)
 #totem_mastery,if=buff.resonance_totem.remains<=2*gcd
 if totemremaining(totem_mastery_enhancement) <= 2 * gcd() spell(totem_mastery_enhancement)
 #sundering,if=active_enemies>=3&(!essence.blood_of_the_enemy.major|(essence.blood_of_the_enemy.major&(buff.seething_rage.up|cooldown.blood_of_the_enemy.remains>40)))
 if enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } spell(sundering)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 spell(rockbiter)
 #frostbrand,if=(azerite.natural_harmony.enabled&buff.natural_harmony_frost.remains<=2*gcd)&talent.hailstorm.enabled&variable.furyCheck_FB
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() spell(frostbrand)
 #flametongue,if=(azerite.natural_harmony.enabled&buff.natural_harmony_fire.remains<=2*gcd)
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() spell(flametongue)
 #rockbiter,if=(azerite.natural_harmony.enabled&buff.natural_harmony_nature.remains<=2*gcd)&maelstrom<70
 if hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 spell(rockbiter)
}

AddFunction enhancementprioritymainpostconditions
{
}

AddFunction enhancementpriorityshortcdactions
{
 unless enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning)
 {
  #the_unbound_force,if=buff.reckless_force.up|time<5
  if buffpresent(reckless_force_buff) or timeincombat() < 5 spell(the_unbound_force)

  unless azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering)
  {
   #purifying_blast,if=active_enemies>1
   if enemies() > 1 spell(purifying_blast)
   #ripple_in_space,if=active_enemies>1
   if enemies() > 1 spell(ripple_in_space_essence)
  }
 }
}

AddFunction enhancementpriorityshortcdpostconditions
{
 enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() and spell(frostbrand) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() and spell(flametongue) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 and spell(rockbiter)
}

AddFunction enhancementprioritycdactions
{
 unless enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or { buffpresent(reckless_force_buff) or timeincombat() < 5 } and spell(the_unbound_force) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering)
 {
  #focused_azerite_beam,if=active_enemies>1
  if enemies() > 1 spell(focused_azerite_beam)
 }
}

AddFunction enhancementprioritycdpostconditions
{
 enemies() >= 8 - talentpoints(forceful_winds_talent) * 3 and freezerburn_enabled() and furyCheck_CL() and spell(crash_lightning) or { buffpresent(reckless_force_buff) or timeincombat() < 5 } and spell(the_unbound_force) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and enemies() == 1 and freezerburn_enabled() and furyCheck_LL() and spell(lava_lash) or not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or not buffpresent(fury_of_air_buff) and maelstrom() >= 20 and enemies() >= 1 + freezerburn_enabled() and spell(fury_of_air) or buffpresent(fury_of_air_buff) and enemies() < 1 + freezerburn_enabled() and spell(fury_of_air) or totemremaining(totem_mastery_enhancement) <= 2 * gcd() and spell(totem_mastery_enhancement) or enemies() >= 3 and { not azeriteessenceismajor(blood_of_the_enemy_essence_id) or azeriteessenceismajor(blood_of_the_enemy_essence_id) and { buffpresent(seething_rage) or spellcooldown(blood_of_the_enemy) > 40 } } and spell(sundering) or enemies() > 1 and spell(purifying_blast) or enemies() > 1 and spell(ripple_in_space_essence) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_frost) <= 2 * gcd() and hastalent(hailstorm_talent) and furyCheck_FB() and spell(frostbrand) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_fire) <= 2 * gcd() and spell(flametongue) or hasazeritetrait(natural_harmony_trait) and buffremaining(natural_harmony_nature) <= 2 * gcd() and maelstrom() < 70 and spell(rockbiter)
}

### actions.precombat

AddFunction enhancementprecombatmainactions
{
 #lightning_shield
 spell(lightning_shield)
}

AddFunction enhancementprecombatmainpostconditions
{
}

AddFunction enhancementprecombatshortcdactions
{
}

AddFunction enhancementprecombatshortcdpostconditions
{
 spell(lightning_shield)
}

AddFunction enhancementprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)

 unless spell(lightning_shield)
 {
  #use_item,name=azsharas_font_of_power
  enhancementuseitemactions()
 }
}

AddFunction enhancementprecombatcdpostconditions
{
 spell(lightning_shield)
}

### actions.opener

AddFunction enhancementopenermainactions
{
 #rockbiter,if=maelstrom<15&time<gcd
 if maelstrom() < 15 and timeincombat() < gcd() spell(rockbiter)
}

AddFunction enhancementopenermainpostconditions
{
}

AddFunction enhancementopenershortcdactions
{
}

AddFunction enhancementopenershortcdpostconditions
{
 maelstrom() < 15 and timeincombat() < gcd() and spell(rockbiter)
}

AddFunction enhancementopenercdactions
{
}

AddFunction enhancementopenercdpostconditions
{
 maelstrom() < 15 and timeincombat() < gcd() and spell(rockbiter)
}

### actions.maintenance

AddFunction enhancementmaintenancemainactions
{
 #flametongue,if=!buff.flametongue.up
 if not buffpresent(flametongue_buff) spell(flametongue)
 #frostbrand,if=talent.hailstorm.enabled&!buff.frostbrand.up&variable.furyCheck_FB
 if hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() spell(frostbrand)
}

AddFunction enhancementmaintenancemainpostconditions
{
}

AddFunction enhancementmaintenanceshortcdactions
{
}

AddFunction enhancementmaintenanceshortcdpostconditions
{
 not buffpresent(flametongue_buff) and spell(flametongue) or hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() and spell(frostbrand)
}

AddFunction enhancementmaintenancecdactions
{
}

AddFunction enhancementmaintenancecdpostconditions
{
 not buffpresent(flametongue_buff) and spell(flametongue) or hastalent(hailstorm_talent) and not buffpresent(frostbrand_buff) and furyCheck_FB() and spell(frostbrand)
}

### actions.freezerburn_core

AddFunction enhancementfreezerburn_coremainactions
{
 #lava_lash,target_if=max:debuff.primal_primer.stack,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack=10&variable.furyCheck_LL&variable.CLPool_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() spell(lava_lash)
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if enemies() >= 3 and furyCheck_CL() spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 spell(lightning_bolt_enhancement)
 #lava_lash,if=azerite.primal_primer.rank>=2&debuff.primal_primer.stack>7&variable.furyCheck_LL&variable.CLPool_LL
 if azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() spell(lava_lash)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS&variable.CLPool_SS
 if OCPool_SS() and furyCheck_SS() and CLPool_SS() spell(stormstrike)
 #lava_lash,if=debuff.primal_primer.stack=10&variable.furyCheck_LL
 if target.debuffstacks(primal_primer) == 10 and furyCheck_LL() spell(lava_lash)
}

AddFunction enhancementfreezerburn_coremainpostconditions
{
}

AddFunction enhancementfreezerburn_coreshortcdactions
{
}

AddFunction enhancementfreezerburn_coreshortcdpostconditions
{
 azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and spell(stormstrike) or target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and spell(lava_lash)
}

AddFunction enhancementfreezerburn_corecdactions
{
}

AddFunction enhancementfreezerburn_corecdpostconditions
{
 azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or azeritetraitrank(primal_primer_trait) >= 2 and target.debuffstacks(primal_primer) > 7 and furyCheck_LL() and CLPool_LL() and spell(lava_lash) or OCPool_SS() and furyCheck_SS() and CLPool_SS() and spell(stormstrike) or target.debuffstacks(primal_primer) == 10 and furyCheck_LL() and spell(lava_lash)
}

### actions.filler

AddFunction enhancementfillermainactions
{
 #sundering,if=raid_event.adds.in>40
 if 600 > 40 spell(sundering)
 #concentrated_flame
 spell(concentrated_flame_essence)
 #crash_lightning,if=talent.forceful_winds.enabled&active_enemies>1&variable.furyCheck_CL
 if hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #flametongue,if=talent.searing_assault.enabled
 if hastalent(searing_assault_talent) spell(flametongue)
 #lava_lash,if=!azerite.primal_primer.enabled&talent.hot_hand.enabled&buff.hot_hand.react
 if not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) spell(lava_lash)
 #crash_lightning,if=active_enemies>1&variable.furyCheck_CL
 if enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #rockbiter,if=maelstrom<70&!buff.strength_of_earth.up
 if maelstrom() < 70 and not buffpresent(strength_of_earth_buff) spell(rockbiter)
 #crash_lightning,if=(talent.crashing_storm.enabled|talent.forceful_winds.enabled)&variable.OCPool_CL
 if { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() spell(crash_lightning)
 #lava_lash,if=variable.OCPool_LL&variable.furyCheck_LL
 if OCPool_LL() and furyCheck_LL() spell(lava_lash)
 #rockbiter
 spell(rockbiter)
 #frostbrand,if=talent.hailstorm.enabled&buff.frostbrand.remains<4.8+gcd&variable.furyCheck_FB
 if hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() spell(frostbrand)
 #flametongue
 spell(flametongue)
}

AddFunction enhancementfillermainpostconditions
{
}

AddFunction enhancementfillershortcdactions
{
 unless 600 > 40 and spell(sundering)
 {
  #purifying_blast,if=raid_event.adds.in>60
  if 600 > 60 spell(purifying_blast)
  #ripple_in_space,if=raid_event.adds.in>60
  if 600 > 60 spell(ripple_in_space_essence)
  #thundercharge
  spell(thundercharge)

  unless spell(concentrated_flame_essence)
  {
   #reaping_flames
   spell(reaping_flames)
   #bag_of_tricks
   spell(bag_of_tricks)
  }
 }
}

AddFunction enhancementfillershortcdpostconditions
{
 600 > 40 and spell(sundering) or spell(concentrated_flame_essence) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash) or spell(rockbiter) or hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() and spell(frostbrand) or spell(flametongue)
}

AddFunction enhancementfillercdactions
{
 unless 600 > 40 and spell(sundering)
 {
  #focused_azerite_beam,if=raid_event.adds.in>90&!buff.ascendance.up&!buff.molten_weapon.up&!buff.icy_edge.up&!buff.crackling_surge.up&!debuff.earthen_spike.up
  if 600 > 90 and not buffpresent(ascendance_enhancement_buff) and not buffpresent(molten_weapon_buff) and not buffpresent(icy_edge_buff) and not buffpresent(crackling_surge) and not target.debuffpresent(earthen_spike_debuff) spell(focused_azerite_beam)

  unless 600 > 60 and spell(purifying_blast) or 600 > 60 and spell(ripple_in_space_essence) or spell(thundercharge) or spell(concentrated_flame_essence) or spell(reaping_flames) or spell(bag_of_tricks) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash)
  {
   #memory_of_lucid_dreams
   spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction enhancementfillercdpostconditions
{
 600 > 40 and spell(sundering) or 600 > 60 and spell(purifying_blast) or 600 > 60 and spell(ripple_in_space_essence) or spell(thundercharge) or spell(concentrated_flame_essence) or spell(reaping_flames) or spell(bag_of_tricks) or hastalent(forceful_winds_talent) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(searing_assault_talent) and spell(flametongue) or not hasazeritetrait(primal_primer_trait) and hastalent(hot_hand_talent) and buffpresent(hot_hand_buff) and spell(lava_lash) or enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or maelstrom() < 70 and not buffpresent(strength_of_earth_buff) and spell(rockbiter) or { hastalent(crashing_storm_talent) or hastalent(forceful_winds_talent) } and OCPool_CL() and spell(crash_lightning) or OCPool_LL() and furyCheck_LL() and spell(lava_lash) or spell(rockbiter) or hastalent(hailstorm_talent) and buffremaining(frostbrand_buff) < 4.8 + gcd() and furyCheck_FB() and spell(frostbrand) or spell(flametongue)
}

### actions.default_core

AddFunction enhancementdefault_coremainactions
{
 #earthen_spike,if=variable.furyCheck_ES
 if furyCheck_ES() spell(earthen_spike)
 #stormstrike,cycle_targets=1,if=active_enemies>1&azerite.lightning_conduit.enabled&!debuff.lightning_conduit.up&variable.furyCheck_SS
 if enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() spell(stormstrike)
 #stormstrike,if=buff.stormbringer.up|(active_enemies>1&buff.gathering_storms.up&variable.furyCheck_SS)
 if buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() spell(stormstrike)
 #crash_lightning,if=active_enemies>=3&variable.furyCheck_CL
 if enemies() >= 3 and furyCheck_CL() spell(crash_lightning)
 #lightning_bolt,if=talent.overcharge.enabled&active_enemies=1&variable.furyCheck_LB&maelstrom>=40
 if hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 spell(lightning_bolt_enhancement)
 #stormstrike,if=variable.OCPool_SS&variable.furyCheck_SS
 if OCPool_SS() and furyCheck_SS() spell(stormstrike)
}

AddFunction enhancementdefault_coremainpostconditions
{
}

AddFunction enhancementdefault_coreshortcdactions
{
}

AddFunction enhancementdefault_coreshortcdpostconditions
{
 furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and spell(stormstrike)
}

AddFunction enhancementdefault_corecdactions
{
}

AddFunction enhancementdefault_corecdpostconditions
{
 furyCheck_ES() and spell(earthen_spike) or enemies() > 1 and hasazeritetrait(lightning_conduit_trait) and not target.debuffpresent(lightning_conduit_debuff) and furyCheck_SS() and spell(stormstrike) or { buffpresent(stormbringer_buff) or enemies() > 1 and buffpresent(gathering_storms_buff) and furyCheck_SS() } and spell(stormstrike) or enemies() >= 3 and furyCheck_CL() and spell(crash_lightning) or hastalent(overcharge_talent) and enemies() == 1 and furyCheck_LB() and maelstrom() >= 40 and spell(lightning_bolt_enhancement) or OCPool_SS() and furyCheck_SS() and spell(stormstrike)
}

### actions.cds

AddFunction enhancementcdsmainactions
{
}

AddFunction enhancementcdsmainpostconditions
{
}

AddFunction enhancementcdsshortcdactions
{
 #worldvein_resonance
 spell(worldvein_resonance_essence)
}

AddFunction enhancementcdsshortcdpostconditions
{
}

AddFunction enhancementcdscdactions
{
 #bloodlust,if=azerite.ancestral_resonance.enabled
 if hasazeritetrait(ancestral_resonance_trait) enhancementbloodlust()

 unless spell(worldvein_resonance_essence)
 {
  #berserking,if=variable.cooldown_sync
  if cooldown_sync() spell(berserking)
  #use_item,name=azsharas_font_of_power
  enhancementuseitemactions()
  #blood_fury,if=variable.cooldown_sync
  if cooldown_sync() spell(blood_fury_apsp)
  #fireblood,if=variable.cooldown_sync
  if cooldown_sync() spell(fireblood)
  #ancestral_call,if=variable.cooldown_sync
  if cooldown_sync() spell(ancestral_call)
  #potion,if=buff.ascendance.up|!talent.ascendance.enabled&feral_spirit.remains>5|target.time_to_die<=60
  if { buffpresent(ascendance_enhancement_buff) or not hastalent(ascendance_talent_enhancement) and totemremaining(sprit_wolf) > 5 or target.timetodie() <= 60 } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
  #guardian_of_azeroth
  spell(guardian_of_azeroth)
  #feral_spirit
  spell(feral_spirit)
  #blood_of_the_enemy,if=raid_event.adds.in>90|active_enemies>1
  if 600 > 90 or enemies() > 1 spell(blood_of_the_enemy)
  #ascendance,if=cooldown.strike.remains>0
  if spellcooldown(windstrike) > 0 and buffexpires(ascendance_enhancement_buff) spell(ascendance_enhancement)
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|(target.time_to_die<20&debuff.razor_coral_debuff.stack>2)
  if target.debuffexpires(razor_coral) or target.timetodie() < 20 and target.debuffstacks(razor_coral) > 2 enhancementuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.stack>2&debuff.conductive_ink_debuff.down&(buff.ascendance.remains>10|buff.molten_weapon.remains>10|buff.crackling_surge.remains>10|buff.icy_edge.remains>10|debuff.earthen_spike.remains>6)
  if target.debuffstacks(razor_coral) > 2 and target.debuffexpires(conductive_ink) and { buffremaining(ascendance_enhancement_buff) > 10 or buffremaining(molten_weapon_buff) > 10 or buffremaining(crackling_surge) > 10 or buffremaining(icy_edge_buff) > 10 or target.debuffremaining(earthen_spike_debuff) > 6 } enhancementuseitemactions()
  #use_item,name=ashvanes_razor_coral,if=(debuff.conductive_ink_debuff.up|buff.ascendance.remains>10|buff.molten_weapon.remains>10|buff.crackling_surge.remains>10|buff.icy_edge.remains>10|debuff.earthen_spike.remains>6)&target.health.pct<31
  if { target.debuffpresent(conductive_ink) or buffremaining(ascendance_enhancement_buff) > 10 or buffremaining(molten_weapon_buff) > 10 or buffremaining(crackling_surge) > 10 or buffremaining(icy_edge_buff) > 10 or target.debuffremaining(earthen_spike_debuff) > 6 } and target.healthpercent() < 31 enhancementuseitemactions()
  #use_items
  enhancementuseitemactions()
  #earth_elemental
  spell(earth_elemental)
 }
}

AddFunction enhancementcdscdpostconditions
{
 spell(worldvein_resonance_essence)
}

### actions.asc

AddFunction enhancementascmainactions
{
 #crash_lightning,if=!buff.crash_lightning.up&active_enemies>1&variable.furyCheck_CL
 if not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() spell(crash_lightning)
 #rockbiter,if=talent.landslide.enabled&!buff.landslide.up&charges_fractional>1.7
 if hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 spell(rockbiter)
 #windstrike
 spell(windstrike)
}

AddFunction enhancementascmainpostconditions
{
}

AddFunction enhancementascshortcdactions
{
}

AddFunction enhancementascshortcdpostconditions
{
 not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or spell(windstrike)
}

AddFunction enhancementasccdactions
{
}

AddFunction enhancementasccdpostconditions
{
 not buffpresent(crash_lightning_buff) and enemies() > 1 and furyCheck_CL() and spell(crash_lightning) or hastalent(landslide_talent) and not buffpresent(landslide_buff) and charges(rockbiter count=0) > 1.7 and spell(rockbiter) or spell(windstrike)
}

### actions.default

AddFunction enhancement_defaultmainactions
{
 #call_action_list,name=opener
 enhancementopenermainactions()

 unless enhancementopenermainpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementascmainactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementascmainpostconditions()
  {
   #call_action_list,name=priority
   enhancementprioritymainactions()

   unless enhancementprioritymainpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenancemainactions()

    unless enemies() < 3 and enhancementmaintenancemainpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdsmainactions()

     unless enhancementcdsmainpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_coremainactions()

      unless freezerburn_enabled() and enhancementfreezerburn_coremainpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_coremainactions()

       unless not freezerburn_enabled() and enhancementdefault_coremainpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenancemainactions()

        unless enemies() >= 3 and enhancementmaintenancemainpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillermainactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultmainpostconditions
{
 enhancementopenermainpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementascmainpostconditions() or enhancementprioritymainpostconditions() or enemies() < 3 and enhancementmaintenancemainpostconditions() or enhancementcdsmainpostconditions() or freezerburn_enabled() and enhancementfreezerburn_coremainpostconditions() or not freezerburn_enabled() and enhancementdefault_coremainpostconditions() or enemies() >= 3 and enhancementmaintenancemainpostconditions() or enhancementfillermainpostconditions()
}

AddFunction enhancement_defaultshortcdactions
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
 enhancementgetinmeleerange()
 #call_action_list,name=opener
 enhancementopenershortcdactions()

 unless enhancementopenershortcdpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementascshortcdactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementascshortcdpostconditions()
  {
   #call_action_list,name=priority
   enhancementpriorityshortcdactions()

   unless enhancementpriorityshortcdpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenanceshortcdactions()

    unless enemies() < 3 and enhancementmaintenanceshortcdpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdsshortcdactions()

     unless enhancementcdsshortcdpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_coreshortcdactions()

      unless freezerburn_enabled() and enhancementfreezerburn_coreshortcdpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_coreshortcdactions()

       unless not freezerburn_enabled() and enhancementdefault_coreshortcdpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenanceshortcdactions()

        unless enemies() >= 3 and enhancementmaintenanceshortcdpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillershortcdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultshortcdpostconditions
{
 enhancementopenershortcdpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementascshortcdpostconditions() or enhancementpriorityshortcdpostconditions() or enemies() < 3 and enhancementmaintenanceshortcdpostconditions() or enhancementcdsshortcdpostconditions() or freezerburn_enabled() and enhancementfreezerburn_coreshortcdpostconditions() or not freezerburn_enabled() and enhancementdefault_coreshortcdpostconditions() or enemies() >= 3 and enhancementmaintenanceshortcdpostconditions() or enhancementfillershortcdpostconditions()
}

AddFunction enhancement_defaultcdactions
{
 #wind_shear
 enhancementinterruptactions()
 #call_action_list,name=opener
 enhancementopenercdactions()

 unless enhancementopenercdpostconditions()
 {
  #call_action_list,name=asc,if=buff.ascendance.up
  if buffpresent(ascendance_enhancement_buff) enhancementasccdactions()

  unless buffpresent(ascendance_enhancement_buff) and enhancementasccdpostconditions()
  {
   #call_action_list,name=priority
   enhancementprioritycdactions()

   unless enhancementprioritycdpostconditions()
   {
    #call_action_list,name=maintenance,if=active_enemies<3
    if enemies() < 3 enhancementmaintenancecdactions()

    unless enemies() < 3 and enhancementmaintenancecdpostconditions()
    {
     #call_action_list,name=cds
     enhancementcdscdactions()

     unless enhancementcdscdpostconditions()
     {
      #call_action_list,name=freezerburn_core,if=variable.freezerburn_enabled
      if freezerburn_enabled() enhancementfreezerburn_corecdactions()

      unless freezerburn_enabled() and enhancementfreezerburn_corecdpostconditions()
      {
       #call_action_list,name=default_core,if=!variable.freezerburn_enabled
       if not freezerburn_enabled() enhancementdefault_corecdactions()

       unless not freezerburn_enabled() and enhancementdefault_corecdpostconditions()
       {
        #call_action_list,name=maintenance,if=active_enemies>=3
        if enemies() >= 3 enhancementmaintenancecdactions()

        unless enemies() >= 3 and enhancementmaintenancecdpostconditions()
        {
         #call_action_list,name=filler
         enhancementfillercdactions()
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultcdpostconditions
{
 enhancementopenercdpostconditions() or buffpresent(ascendance_enhancement_buff) and enhancementasccdpostconditions() or enhancementprioritycdpostconditions() or enemies() < 3 and enhancementmaintenancecdpostconditions() or enhancementcdscdpostconditions() or freezerburn_enabled() and enhancementfreezerburn_corecdpostconditions() or not freezerburn_enabled() and enhancementdefault_corecdpostconditions() or enemies() >= 3 and enhancementmaintenancecdpostconditions() or enhancementfillercdpostconditions()
}

### Enhancement icons.

AddCheckBox(opt_shaman_enhancement_aoe l(aoe) default specialization=enhancement)

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=shortcd specialization=enhancement
{
 if not incombat() enhancementprecombatshortcdactions()
 enhancement_defaultshortcdactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=shortcd specialization=enhancement
{
 if not incombat() enhancementprecombatshortcdactions()
 enhancement_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=enhancement
{
 if not incombat() enhancementprecombatmainactions()
 enhancement_defaultmainactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=aoe specialization=enhancement
{
 if not incombat() enhancementprecombatmainactions()
 enhancement_defaultmainactions()
}

AddIcon checkbox=!opt_shaman_enhancement_aoe enemies=1 help=cd specialization=enhancement
{
 if not incombat() enhancementprecombatcdactions()
 enhancement_defaultcdactions()
}

AddIcon checkbox=opt_shaman_enhancement_aoe help=cd specialization=enhancement
{
 if not incombat() enhancementprecombatcdactions()
 enhancement_defaultcdactions()
}

### Required symbols
# ancestral_call
# ancestral_resonance_trait
# ascendance_enhancement
# ascendance_enhancement_buff
# ascendance_talent_enhancement
# bag_of_tricks
# berserking
# blood_fury_apsp
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodlust
# boulderfist_talent
# capacitor_totem
# concentrated_flame_essence
# conductive_ink
# crackling_surge
# crash_lightning
# crash_lightning_buff
# crashing_storm_talent
# earth_elemental
# earthen_spike
# earthen_spike_debuff
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
# icy_edge_buff
# landslide_buff
# landslide_talent
# lava_lash
# lightning_bolt_enhancement
# lightning_conduit_debuff
# lightning_conduit_trait
# lightning_shield
# memory_of_lucid_dreams_essence
# molten_weapon_buff
# natural_harmony_fire
# natural_harmony_frost
# natural_harmony_nature
# natural_harmony_trait
# overcharge_talent
# primal_primer
# primal_primer_trait
# purifying_blast
# quaking_palm
# razor_coral
# reaping_flames
# reckless_force_buff
# ripple_in_space_essence
# rockbiter
# searing_assault_talent
# seething_rage
# stormbringer_buff
# stormstrike
# strength_of_earth_buff
# strength_of_earth_trait
# sundering
# the_unbound_force
# thundercharge
# totem_mastery_enhancement
# unbridled_fury_item
# war_stomp
# wind_shear
# windstrike
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
    end
    do
        local name = "sc_t24_shaman_restoration"
        local desc = "[8.3] Simulationcraft: T24_Shaman_Restoration"
        local code = [[
# Based on SimulationCraft profile "T24_Shaman_Restoration".
#	class=shaman
#	spec=restoration
#	talents=1132221

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=restoration)
AddCheckBox(opt_use_consumables l(opt_use_consumables) default specialization=restoration)

AddFunction restorationinterruptactions
{
 if checkboxon(opt_interrupt) and not target.isfriend() and target.casting()
 {
  if target.inrange(wind_shear) and target.isinterruptible() spell(wind_shear)
  if not target.classification(worldboss) and target.remainingcasttime() > 2 spell(capacitor_totem)
  if target.inrange(quaking_palm) and not target.classification(worldboss) spell(quaking_palm)
  if target.distance(less 5) and not target.classification(worldboss) spell(war_stomp)
  if target.inrange(hex) and not target.classification(worldboss) and target.remainingcasttime() > casttime(hex) + gcdremaining() and target.creaturetype(humanoid beast) spell(hex)
 }
}

AddFunction restorationuseitemactions
{
 item(trinket0slot text=13 usable=1)
 item(trinket1slot text=14 usable=1)
}

### actions.precombat

AddFunction restorationprecombatmainactions
{
 #lava_burst
 spell(lava_burst)
}

AddFunction restorationprecombatmainpostconditions
{
}

AddFunction restorationprecombatshortcdactions
{
}

AddFunction restorationprecombatshortcdpostconditions
{
 spell(lava_burst)
}

AddFunction restorationprecombatcdactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
}

AddFunction restorationprecombatcdpostconditions
{
 spell(lava_burst)
}

### actions.default

AddFunction restoration_defaultmainactions
{
 #concentrated_flame
 spell(concentrated_flame_essence)
 #flame_shock,target_if=(!ticking|dot.flame_shock.remains<=gcd)|refreshable
 if not target.debuffpresent(flame_shock_restoration_debuff) or target.debuffremaining(flame_shock_restoration_debuff) <= gcd() or target.refreshable(flame_shock_restoration_debuff) spell(flame_shock_restoration)
 #lava_burst,if=dot.flame_shock.remains>cast_time&cooldown_react
 if target.debuffremaining(flame_shock_restoration_debuff) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 spell(lava_burst)
 #lightning_bolt,if=spell_targets.chain_lightning<2
 if enemies() < 2 spell(lightning_bolt)
 #chain_lightning,if=active_enemies>1&spell_targets.chain_lightning>1
 if enemies() > 1 and enemies() > 1 spell(chain_lightning_restoration)
 #flame_shock,moving=1
 if speed() > 0 spell(flame_shock_restoration)
}

AddFunction restoration_defaultmainpostconditions
{
}

AddFunction restoration_defaultshortcdactions
{
 unless spell(concentrated_flame_essence)
 {
  #ripple_in_space
  spell(ripple_in_space_essence)
  #worldvein_resonance
  spell(worldvein_resonance_essence)
 }
}

AddFunction restoration_defaultshortcdpostconditions
{
 spell(concentrated_flame_essence) or { not target.debuffpresent(flame_shock_restoration_debuff) or target.debuffremaining(flame_shock_restoration_debuff) <= gcd() or target.refreshable(flame_shock_restoration_debuff) } and spell(flame_shock_restoration) or target.debuffremaining(flame_shock_restoration_debuff) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or enemies() < 2 and spell(lightning_bolt) or enemies() > 1 and enemies() > 1 and spell(chain_lightning_restoration) or speed() > 0 and spell(flame_shock_restoration)
}

AddFunction restoration_defaultcdactions
{
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(unbridled_fury_item usable=1)
 #wind_shear
 restorationinterruptactions()
 #spiritwalkers_grace,moving=1,if=movement.distance>6
 if speed() > 0 and target.distance() > 6 spell(spiritwalkers_grace)
 #use_items
 restorationuseitemactions()
 #blood_fury
 spell(blood_fury_apsp)
 #berserking
 spell(berserking)
 #fireblood
 spell(fireblood)
 #ancestral_call
 spell(ancestral_call)

 unless spell(concentrated_flame_essence) or spell(ripple_in_space_essence) or spell(worldvein_resonance_essence) or { not target.debuffpresent(flame_shock_restoration_debuff) or target.debuffremaining(flame_shock_restoration_debuff) <= gcd() or target.refreshable(flame_shock_restoration_debuff) } and spell(flame_shock_restoration) or target.debuffremaining(flame_shock_restoration_debuff) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst)
 {
  #earth_elemental
  spell(earth_elemental)
 }
}

AddFunction restoration_defaultcdpostconditions
{
 spell(concentrated_flame_essence) or spell(ripple_in_space_essence) or spell(worldvein_resonance_essence) or { not target.debuffpresent(flame_shock_restoration_debuff) or target.debuffremaining(flame_shock_restoration_debuff) <= gcd() or target.refreshable(flame_shock_restoration_debuff) } and spell(flame_shock_restoration) or target.debuffremaining(flame_shock_restoration_debuff) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or enemies() < 2 and spell(lightning_bolt) or enemies() > 1 and enemies() > 1 and spell(chain_lightning_restoration) or speed() > 0 and spell(flame_shock_restoration)
}

### Restoration icons.

AddCheckBox(opt_shaman_restoration_aoe l(aoe) default specialization=restoration)

AddIcon checkbox=!opt_shaman_restoration_aoe enemies=1 help=shortcd specialization=restoration
{
 if not incombat() restorationprecombatshortcdactions()
 restoration_defaultshortcdactions()
}

AddIcon checkbox=opt_shaman_restoration_aoe help=shortcd specialization=restoration
{
 if not incombat() restorationprecombatshortcdactions()
 restoration_defaultshortcdactions()
}

AddIcon enemies=1 help=main specialization=restoration
{
 if not incombat() restorationprecombatmainactions()
 restoration_defaultmainactions()
}

AddIcon checkbox=opt_shaman_restoration_aoe help=aoe specialization=restoration
{
 if not incombat() restorationprecombatmainactions()
 restoration_defaultmainactions()
}

AddIcon checkbox=!opt_shaman_restoration_aoe enemies=1 help=cd specialization=restoration
{
 if not incombat() restorationprecombatcdactions()
 restoration_defaultcdactions()
}

AddIcon checkbox=opt_shaman_restoration_aoe help=cd specialization=restoration
{
 if not incombat() restorationprecombatcdactions()
 restoration_defaultcdactions()
}

### Required symbols
# ancestral_call
# berserking
# blood_fury_apsp
# capacitor_totem
# chain_lightning_restoration
# concentrated_flame_essence
# earth_elemental
# fireblood
# flame_shock_restoration
# flame_shock_restoration_debuff
# hex
# lava_burst
# lightning_bolt
# quaking_palm
# ripple_in_space_essence
# spiritwalkers_grace
# unbridled_fury_item
# war_stomp
# wind_shear
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("SHAMAN", "restoration", name, desc, code, "script")
    end
end
