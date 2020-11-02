local __exports = LibStub:NewLibrary("ovale/scripts/ovale_shaman", 80300)
if not __exports then return end
__exports.registerShaman = function(OvaleScripts)
    do
        local name = "sc_t25_shaman_elemental"
        local desc = "[9.0] Simulationcraft: T25_Shaman_Elemental"
        local code = [[
# Based on SimulationCraft profile "T25_Shaman_Elemental".
#	class=shaman
#	spec=elemental
#	talents=2311132

Include(ovale_common)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=elemental)

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

### actions.single_target

AddFunction elementalsingle_targetmainactions
{
 #flame_shock,target_if=refreshable
 if target.refreshable(flame_shock) spell(flame_shock)
 #elemental_blast,if=talent.elemental_blast.enabled
 if hastalent(elemental_blast_talent_elemental) spell(elemental_blast)
 #stormkeeper,if=talent.stormkeeper.enabled
 if hastalent(stormkeeper_talent) spell(stormkeeper)
 #liquid_magma_totem,if=talent.liquid_magma_totem.enabled
 if hastalent(liquid_magma_totem_talent) spell(liquid_magma_totem)
 #echoing_shock,if=talent.echoing_shock.enabled
 if hastalent(echoing_shock_talent) spell(echoing_shock)
 #ascendance,if=talent.ascendance.enabled
 if hastalent(ascendance_talent) spell(ascendance)
 #lava_burst,if=cooldown_react
 if not spellcooldown(lava_burst) > 0 spell(lava_burst)
 #lava_burst,if=cooldown_react
 if not spellcooldown(lava_burst) > 0 spell(lava_burst)
 #earthquake,if=(spell_targets.chain_lightning>1&!runeforge.echoes_of_great_sundering.equipped|buff.echoes_of_great_sundering.up)
 if enemies() > 1 and not equippedruneforge(echoes_of_great_sundering_runeforge) or buffpresent(echoes_of_great_sundering_buff) spell(earthquake)
 #earth_shock
 spell(earth_shock)
 #frost_shock,if=talent.icefury.enabled&buff.icefury.up
 if hastalent(icefury_talent) and buffpresent(icefury) spell(frost_shock)
 #icefury,if=talent.icefury.enabled
 if hastalent(icefury_talent) spell(icefury)
 #lightning_bolt
 spell(lightning_bolt)
 #flame_shock,moving=1,target_if=refreshable
 if speed() > 0 and target.refreshable(flame_shock) spell(flame_shock)
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
 unless target.refreshable(flame_shock) and spell(flame_shock) or hastalent(elemental_blast_talent_elemental) and spell(elemental_blast) or hastalent(stormkeeper_talent) and spell(stormkeeper) or hastalent(liquid_magma_totem_talent) and spell(liquid_magma_totem) or hastalent(echoing_shock_talent) and spell(echoing_shock) or hastalent(ascendance_talent) and spell(ascendance) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or { enemies() > 1 and not equippedruneforge(echoes_of_great_sundering_runeforge) or buffpresent(echoes_of_great_sundering_buff) } and spell(earthquake) or spell(earth_shock)
 {
  #lightning_lasso
  spell(lightning_lasso)
 }
}

AddFunction elementalsingle_targetshortcdpostconditions
{
 target.refreshable(flame_shock) and spell(flame_shock) or hastalent(elemental_blast_talent_elemental) and spell(elemental_blast) or hastalent(stormkeeper_talent) and spell(stormkeeper) or hastalent(liquid_magma_totem_talent) and spell(liquid_magma_totem) or hastalent(echoing_shock_talent) and spell(echoing_shock) or hastalent(ascendance_talent) and spell(ascendance) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or { enemies() > 1 and not equippedruneforge(echoes_of_great_sundering_runeforge) or buffpresent(echoes_of_great_sundering_buff) } and spell(earthquake) or spell(earth_shock) or hastalent(icefury_talent) and buffpresent(icefury) and spell(frost_shock) or hastalent(icefury_talent) and spell(icefury) or spell(lightning_bolt) or speed() > 0 and target.refreshable(flame_shock) and spell(flame_shock) or speed() > 0 and target.distance() > 6 and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

AddFunction elementalsingle_targetcdactions
{
}

AddFunction elementalsingle_targetcdpostconditions
{
 target.refreshable(flame_shock) and spell(flame_shock) or hastalent(elemental_blast_talent_elemental) and spell(elemental_blast) or hastalent(stormkeeper_talent) and spell(stormkeeper) or hastalent(liquid_magma_totem_talent) and spell(liquid_magma_totem) or hastalent(echoing_shock_talent) and spell(echoing_shock) or hastalent(ascendance_talent) and spell(ascendance) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not spellcooldown(lava_burst) > 0 and spell(lava_burst) or { enemies() > 1 and not equippedruneforge(echoes_of_great_sundering_runeforge) or buffpresent(echoes_of_great_sundering_buff) } and spell(earthquake) or spell(earth_shock) or spell(lightning_lasso) or hastalent(icefury_talent) and buffpresent(icefury) and spell(frost_shock) or hastalent(icefury_talent) and spell(icefury) or spell(lightning_bolt) or speed() > 0 and target.refreshable(flame_shock) and spell(flame_shock) or speed() > 0 and target.distance() > 6 and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

### actions.precombat

AddFunction elementalprecombatmainactions
{
}

AddFunction elementalprecombatmainpostconditions
{
}

AddFunction elementalprecombatshortcdactions
{
}

AddFunction elementalprecombatshortcdpostconditions
{
}

AddFunction elementalprecombatcdactions
{
}

AddFunction elementalprecombatcdpostconditions
{
}

### actions.aoe

AddFunction elementalaoemainactions
{
 #stormkeeper,if=talent.stormkeeper.enabled
 if hastalent(stormkeeper_talent) spell(stormkeeper)
 #flame_shock,target_if=refreshable
 if target.refreshable(flame_shock) spell(flame_shock)
 #liquid_magma_totem,if=talent.liquid_magma_totem.enabled
 if hastalent(liquid_magma_totem_talent) spell(liquid_magma_totem)
 #lava_burst,if=talent.master_of_the_elements.enabled&maelstrom>=50&buff.lava_surge.up
 if hastalent(master_of_the_elements_talent) and maelstrom() >= 50 and buffpresent(lava_surge) spell(lava_burst)
 #echoing_shock,if=talent.echoing_shock.enabled
 if hastalent(echoing_shock_talent) spell(echoing_shock)
 #earthquake
 spell(earthquake)
 #chain_lightning
 spell(chain_lightning)
 #flame_shock,moving=1,target_if=refreshable
 if speed() > 0 and target.refreshable(flame_shock) spell(flame_shock)
 #frost_shock,moving=1
 if speed() > 0 spell(frost_shock)
}

AddFunction elementalaoemainpostconditions
{
}

AddFunction elementalaoeshortcdactions
{
}

AddFunction elementalaoeshortcdpostconditions
{
 hastalent(stormkeeper_talent) and spell(stormkeeper) or target.refreshable(flame_shock) and spell(flame_shock) or hastalent(liquid_magma_totem_talent) and spell(liquid_magma_totem) or hastalent(master_of_the_elements_talent) and maelstrom() >= 50 and buffpresent(lava_surge) and spell(lava_burst) or hastalent(echoing_shock_talent) and spell(echoing_shock) or spell(earthquake) or spell(chain_lightning) or speed() > 0 and target.refreshable(flame_shock) and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

AddFunction elementalaoecdactions
{
}

AddFunction elementalaoecdpostconditions
{
 hastalent(stormkeeper_talent) and spell(stormkeeper) or target.refreshable(flame_shock) and spell(flame_shock) or hastalent(liquid_magma_totem_talent) and spell(liquid_magma_totem) or hastalent(master_of_the_elements_talent) and maelstrom() >= 50 and buffpresent(lava_surge) and spell(lava_burst) or hastalent(echoing_shock_talent) and spell(echoing_shock) or spell(earthquake) or spell(chain_lightning) or speed() > 0 and target.refreshable(flame_shock) and spell(flame_shock) or speed() > 0 and spell(frost_shock)
}

### actions.default

AddFunction elemental_defaultmainactions
{
 #flame_shock,if=!ticking
 if not buffpresent(flame_shock) spell(flame_shock)
 #storm_elemental
 spell(storm_elemental)
 #berserking,if=!talent.ascendance.enabled|buff.ascendance.up
 if not hastalent(ascendance_talent) or buffpresent(ascendance) spell(berserking)
 #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
 if enemies() > 2 and { enemies() > 2 or enemies() > 2 } elementalaoemainactions()

 unless enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoemainpostconditions()
 {
  #run_action_list,name=single_target,if=active_enemies<=2
  if enemies() <= 2 elementalsingle_targetmainactions()
 }
}

AddFunction elemental_defaultmainpostconditions
{
 enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoemainpostconditions() or enemies() <= 2 and elementalsingle_targetmainpostconditions()
}

AddFunction elemental_defaultshortcdactions
{
 unless not buffpresent(flame_shock) and spell(flame_shock) or spell(storm_elemental) or { not hastalent(ascendance_talent) or buffpresent(ascendance) } and spell(berserking)
 {
  #bag_of_tricks,if=!talent.ascendance.enabled|!buff.ascendance.up
  if not hastalent(ascendance_talent) or not buffpresent(ascendance) spell(bag_of_tricks)
  #primordial_wave,if=covenant.necrolord
  if covenant(necrolord) spell(primordial_wave)
  #vesper_totem,if=covenant.kyrian
  if covenant(kyrian) spell(vesper_totem)
  #chain_harvest,if=covenant.venthyr
  if covenant(venthyr) spell(chain_harvest)
  #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
  if enemies() > 2 and { enemies() > 2 or enemies() > 2 } elementalaoeshortcdactions()

  unless enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoeshortcdpostconditions()
  {
   #run_action_list,name=single_target,if=active_enemies<=2
   if enemies() <= 2 elementalsingle_targetshortcdactions()
  }
 }
}

AddFunction elemental_defaultshortcdpostconditions
{
 not buffpresent(flame_shock) and spell(flame_shock) or spell(storm_elemental) or { not hastalent(ascendance_talent) or buffpresent(ascendance) } and spell(berserking) or enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoeshortcdpostconditions() or enemies() <= 2 and elementalsingle_targetshortcdpostconditions()
}

AddFunction elemental_defaultcdactions
{
 #wind_shear
 elementalinterruptactions()
 #use_items
 elementaluseitemactions()

 unless not buffpresent(flame_shock) and spell(flame_shock)
 {
  #fire_elemental
  spell(fire_elemental)

  unless spell(storm_elemental)
  {
   #blood_fury,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
   if not hastalent(ascendance_talent) or buffpresent(ascendance) or spellcooldown(ascendance) > 50 spell(blood_fury)

   unless { not hastalent(ascendance_talent) or buffpresent(ascendance) } and spell(berserking)
   {
    #fireblood,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
    if not hastalent(ascendance_talent) or buffpresent(ascendance) or spellcooldown(ascendance) > 50 spell(fireblood)
    #ancestral_call,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
    if not hastalent(ascendance_talent) or buffpresent(ascendance) or spellcooldown(ascendance) > 50 spell(ancestral_call)

    unless { not hastalent(ascendance_talent) or not buffpresent(ascendance) } and spell(bag_of_tricks) or covenant(necrolord) and spell(primordial_wave) or covenant(kyrian) and spell(vesper_totem) or covenant(venthyr) and spell(chain_harvest)
    {
     #fae_transfusion,if=covenant.night_fae
     if covenant(night_fae) spell(fae_transfusion)
     #run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
     if enemies() > 2 and { enemies() > 2 or enemies() > 2 } elementalaoecdactions()

     unless enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoecdpostconditions()
     {
      #run_action_list,name=single_target,if=active_enemies<=2
      if enemies() <= 2 elementalsingle_targetcdactions()
     }
    }
   }
  }
 }
}

AddFunction elemental_defaultcdpostconditions
{
 not buffpresent(flame_shock) and spell(flame_shock) or spell(storm_elemental) or { not hastalent(ascendance_talent) or buffpresent(ascendance) } and spell(berserking) or { not hastalent(ascendance_talent) or not buffpresent(ascendance) } and spell(bag_of_tricks) or covenant(necrolord) and spell(primordial_wave) or covenant(kyrian) and spell(vesper_totem) or covenant(venthyr) and spell(chain_harvest) or enemies() > 2 and { enemies() > 2 or enemies() > 2 } and elementalaoecdpostconditions() or enemies() <= 2 and elementalsingle_targetcdpostconditions()
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
# ascendance
# ascendance_talent
# bag_of_tricks
# berserking
# blood_fury
# capacitor_totem
# chain_harvest
# chain_lightning
# earth_shock
# earthquake
# echoes_of_great_sundering_buff
# echoes_of_great_sundering_runeforge
# echoing_shock
# echoing_shock_talent
# elemental_blast
# elemental_blast_talent_elemental
# fae_transfusion
# fire_elemental
# fireblood
# flame_shock
# frost_shock
# hex
# icefury
# icefury_talent
# kyrian
# lava_burst
# lava_surge
# lightning_bolt
# lightning_lasso
# liquid_magma_totem
# liquid_magma_totem_talent
# master_of_the_elements_talent
# necrolord
# night_fae
# primordial_wave
# quaking_palm
# storm_elemental
# stormkeeper
# stormkeeper_talent
# venthyr
# vesper_totem
# war_stomp
# wind_shear
]]
        OvaleScripts:RegisterScript("SHAMAN", "elemental", name, desc, code, "script")
    end
    do
        local name = "sc_t25_shaman_enhancement"
        local desc = "[9.0] Simulationcraft: T25_Shaman_Enhancement"
        local code = [[
# Based on SimulationCraft profile "T25_Shaman_Enhancement".
#	class=shaman
#	spec=enhancement
#	talents=1101023

Include(ovale_common)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=enhancement)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=enhancement)
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

### actions.single

AddFunction enhancementsinglemainactions
{
 #flame_shock,if=!ticking
 if not buffpresent(flame_shock) spell(flame_shock)
 #frost_shock,if=buff.hailstorm.up
 if buffpresent(hailstorm) spell(frost_shock)
 #earthen_spike
 spell(earthen_spike)
 #lightning_bolt,if=buff.stormkeeper.up&buff.maelstrom_weapon.stack>=5
 if buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 spell(lightning_bolt)
 #elemental_blast,if=buff.maelstrom_weapon.stack>=5
 if buffstacks(maelstrom_weapon) >= 5 spell(elemental_blast)
 #lightning_bolt,if=buff.maelstrom_weapon.stack=10
 if buffstacks(maelstrom_weapon) == 10 spell(lightning_bolt)
 #lava_lash,if=buff.hot_hand.up
 if buffpresent(hot_hand_buff) spell(lava_lash)
 #stormstrike
 spell(stormstrike)
 #stormkeeper,if=buff.maelstrom_weapon.stack>=5
 if buffstacks(maelstrom_weapon) >= 5 spell(stormkeeper_enhancement)
 #lava_lash
 spell(lava_lash)
 #crash_lightning
 spell(crash_lightning)
 #flame_shock,target_if=refreshable
 if target.refreshable(flame_shock) spell(flame_shock)
 #frost_shock
 spell(frost_shock)
 #ice_strike
 spell(ice_strike)
 #sundering
 spell(sundering)
 #fire_nova,if=active_dot.flame_shock
 if debuffcountonany(flame_shock) spell(fire_nova)
 #lightning_bolt,if=buff.maelstrom_weapon.stack>=5
 if buffstacks(maelstrom_weapon) >= 5 spell(lightning_bolt)
 #earth_elemental
 spell(earth_elemental)
 #windfury_totem,if=buff.windfury_totem.remains<30
 if buffremaining(windfury_totem) < 30 spell(windfury_totem)
}

AddFunction enhancementsinglemainpostconditions
{
}

AddFunction enhancementsingleshortcdactions
{
 #primordial_wave,if=!buff.primordial_wave.up&(!talent.stormkeeper.enabled|buff.stormkeeper.up)
 if not buffpresent(primordial_wave) and { not hastalent(stormkeeper_talent_enhancement) or buffpresent(stormkeeper_enhancement) } spell(primordial_wave)

 unless not buffpresent(flame_shock) and spell(flame_shock)
 {
  #vesper_totem
  spell(vesper_totem)

  unless buffpresent(hailstorm) and spell(frost_shock) or spell(earthen_spike) or buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or buffstacks(maelstrom_weapon) >= 5 and spell(elemental_blast)
  {
   #chain_harvest,if=buff.maelstrom_weapon.stack>=5
   if buffstacks(maelstrom_weapon) >= 5 spell(chain_harvest)
  }
 }
}

AddFunction enhancementsingleshortcdpostconditions
{
 not buffpresent(flame_shock) and spell(flame_shock) or buffpresent(hailstorm) and spell(frost_shock) or spell(earthen_spike) or buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or buffstacks(maelstrom_weapon) >= 5 and spell(elemental_blast) or buffstacks(maelstrom_weapon) == 10 and spell(lightning_bolt) or buffpresent(hot_hand_buff) and spell(lava_lash) or spell(stormstrike) or buffstacks(maelstrom_weapon) >= 5 and spell(stormkeeper_enhancement) or spell(lava_lash) or spell(crash_lightning) or target.refreshable(flame_shock) and spell(flame_shock) or spell(frost_shock) or spell(ice_strike) or spell(sundering) or debuffcountonany(flame_shock) and spell(fire_nova) or buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or spell(earth_elemental) or buffremaining(windfury_totem) < 30 and spell(windfury_totem)
}

AddFunction enhancementsinglecdactions
{
 unless not buffpresent(primordial_wave) and { not hastalent(stormkeeper_talent_enhancement) or buffpresent(stormkeeper_enhancement) } and spell(primordial_wave) or not buffpresent(flame_shock) and spell(flame_shock) or spell(vesper_totem) or buffpresent(hailstorm) and spell(frost_shock) or spell(earthen_spike)
 {
  #fae_transfusion
  spell(fae_transfusion)
 }
}

AddFunction enhancementsinglecdpostconditions
{
 not buffpresent(primordial_wave) and { not hastalent(stormkeeper_talent_enhancement) or buffpresent(stormkeeper_enhancement) } and spell(primordial_wave) or not buffpresent(flame_shock) and spell(flame_shock) or spell(vesper_totem) or buffpresent(hailstorm) and spell(frost_shock) or spell(earthen_spike) or buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or buffstacks(maelstrom_weapon) >= 5 and spell(elemental_blast) or buffstacks(maelstrom_weapon) >= 5 and spell(chain_harvest) or buffstacks(maelstrom_weapon) == 10 and spell(lightning_bolt) or buffpresent(hot_hand_buff) and spell(lava_lash) or spell(stormstrike) or buffstacks(maelstrom_weapon) >= 5 and spell(stormkeeper_enhancement) or spell(lava_lash) or spell(crash_lightning) or target.refreshable(flame_shock) and spell(flame_shock) or spell(frost_shock) or spell(ice_strike) or spell(sundering) or debuffcountonany(flame_shock) and spell(fire_nova) or buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or spell(earth_elemental) or buffremaining(windfury_totem) < 30 and spell(windfury_totem)
}

### actions.precombat

AddFunction enhancementprecombatmainactions
{
 #flask
 #food
 #augmentation
 #windfury_weapon
 spell(windfury_weapon)
 #flametongue_weapon
 spell(flametongue_weapon)
 #lightning_shield
 spell(lightning_shield)
 #stormkeeper,if=talent.stormkeeper.enabled
 if hastalent(stormkeeper_talent_enhancement) spell(stormkeeper_enhancement)
 #windfury_totem
 spell(windfury_totem)
}

AddFunction enhancementprecombatmainpostconditions
{
}

AddFunction enhancementprecombatshortcdactions
{
}

AddFunction enhancementprecombatshortcdpostconditions
{
 spell(windfury_weapon) or spell(flametongue_weapon) or spell(lightning_shield) or hastalent(stormkeeper_talent_enhancement) and spell(stormkeeper_enhancement) or spell(windfury_totem)
}

AddFunction enhancementprecombatcdactions
{
}

AddFunction enhancementprecombatcdpostconditions
{
 spell(windfury_weapon) or spell(flametongue_weapon) or spell(lightning_shield) or hastalent(stormkeeper_talent_enhancement) and spell(stormkeeper_enhancement) or spell(windfury_totem)
}

### actions.aoe

AddFunction enhancementaoemainactions
{
 #frost_shock,if=buff.hailstorm.up
 if buffpresent(hailstorm) spell(frost_shock)
 #fire_nova,if=active_dot.flame_shock>=3
 if debuffcountonany(flame_shock) >= 3 spell(fire_nova)
 #flame_shock,target_if=refreshable,cycle_targets=1,if=talent.fire_nova.enabled|covenant.necrolord
 if target.refreshable(flame_shock) and { hastalent(fire_nova_talent) or covenant(necrolord) } spell(flame_shock)
 #lightning_bolt,if=buff.primordial_wave.up&buff.maelstrom_weapon.stack>=5
 if buffpresent(primordial_wave) and buffstacks(maelstrom_weapon) >= 5 spell(lightning_bolt)
 #crash_lightning
 spell(crash_lightning)
 #chain_lightning,if=buff.stormkeeper.up&buff.maelstrom_weapon.stack>=5
 if buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 spell(chain_lightning)
 #elemental_blast,if=buff.maelstrom_weapon.stack>=5&active_enemies!=3
 if buffstacks(maelstrom_weapon) >= 5 and enemies() != 3 spell(elemental_blast)
 #stormkeeper,if=buff.maelstrom_weapon.stack>=5
 if buffstacks(maelstrom_weapon) >= 5 spell(stormkeeper_enhancement)
 #chain_lightning,if=buff.maelstrom_weapon.stack=10
 if buffstacks(maelstrom_weapon) == 10 spell(chain_lightning)
 #flame_shock,target_if=refreshable,cycle_targets=1,if=talent.fire_nova.enabled
 if target.refreshable(flame_shock) and hastalent(fire_nova_talent) spell(flame_shock)
 #sundering
 spell(sundering)
 #stormstrike
 spell(stormstrike)
 #lava_lash
 spell(lava_lash)
 #flame_shock,target_if=refreshable,cycle_targets=1
 if target.refreshable(flame_shock) spell(flame_shock)
 #elemental_blast,if=buff.maelstrom_weapon.stack>=5&active_enemies=3
 if buffstacks(maelstrom_weapon) >= 5 and enemies() == 3 spell(elemental_blast)
 #frost_shock
 spell(frost_shock)
 #ice_strike
 spell(ice_strike)
 #chain_lightning,if=buff.maelstrom_weapon.stack>=5
 if buffstacks(maelstrom_weapon) >= 5 spell(chain_lightning)
 #fire_nova,if=active_dot.flame_shock>1
 if debuffcountonany(flame_shock) > 1 spell(fire_nova)
 #earthen_spike
 spell(earthen_spike)
 #earth_elemental
 spell(earth_elemental)
 #windfury_totem,if=buff.windfury_totem.remains<30
 if buffremaining(windfury_totem) < 30 spell(windfury_totem)
}

AddFunction enhancementaoemainpostconditions
{
}

AddFunction enhancementaoeshortcdactions
{
 unless buffpresent(hailstorm) and spell(frost_shock) or debuffcountonany(flame_shock) >= 3 and spell(fire_nova) or target.refreshable(flame_shock) and { hastalent(fire_nova_talent) or covenant(necrolord) } and spell(flame_shock)
 {
  #primordial_wave,target_if=min:dot.flame_shock.remains,cycle_targets=1,if=!buff.primordial_wave.up&(!talent.stormkeeper.enabled|buff.stormkeeper.up)
  if not buffpresent(primordial_wave) and { not hastalent(stormkeeper_talent_enhancement) or buffpresent(stormkeeper_enhancement) } spell(primordial_wave)
  #vesper_totem
  spell(vesper_totem)

  unless buffpresent(primordial_wave) and buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or spell(crash_lightning) or buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 and spell(chain_lightning)
  {
   #chain_harvest,if=buff.maelstrom_weapon.stack>=5
   if buffstacks(maelstrom_weapon) >= 5 spell(chain_harvest)
  }
 }
}

AddFunction enhancementaoeshortcdpostconditions
{
 buffpresent(hailstorm) and spell(frost_shock) or debuffcountonany(flame_shock) >= 3 and spell(fire_nova) or target.refreshable(flame_shock) and { hastalent(fire_nova_talent) or covenant(necrolord) } and spell(flame_shock) or buffpresent(primordial_wave) and buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or spell(crash_lightning) or buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 and spell(chain_lightning) or buffstacks(maelstrom_weapon) >= 5 and enemies() != 3 and spell(elemental_blast) or buffstacks(maelstrom_weapon) >= 5 and spell(stormkeeper_enhancement) or buffstacks(maelstrom_weapon) == 10 and spell(chain_lightning) or target.refreshable(flame_shock) and hastalent(fire_nova_talent) and spell(flame_shock) or spell(sundering) or spell(stormstrike) or spell(lava_lash) or target.refreshable(flame_shock) and spell(flame_shock) or buffstacks(maelstrom_weapon) >= 5 and enemies() == 3 and spell(elemental_blast) or spell(frost_shock) or spell(ice_strike) or buffstacks(maelstrom_weapon) >= 5 and spell(chain_lightning) or debuffcountonany(flame_shock) > 1 and spell(fire_nova) or spell(earthen_spike) or spell(earth_elemental) or buffremaining(windfury_totem) < 30 and spell(windfury_totem)
}

AddFunction enhancementaoecdactions
{
 unless buffpresent(hailstorm) and spell(frost_shock) or debuffcountonany(flame_shock) >= 3 and spell(fire_nova) or target.refreshable(flame_shock) and { hastalent(fire_nova_talent) or covenant(necrolord) } and spell(flame_shock) or not buffpresent(primordial_wave) and { not hastalent(stormkeeper_talent_enhancement) or buffpresent(stormkeeper_enhancement) } and spell(primordial_wave) or spell(vesper_totem) or buffpresent(primordial_wave) and buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or spell(crash_lightning) or buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 and spell(chain_lightning) or buffstacks(maelstrom_weapon) >= 5 and spell(chain_harvest) or buffstacks(maelstrom_weapon) >= 5 and enemies() != 3 and spell(elemental_blast) or buffstacks(maelstrom_weapon) >= 5 and spell(stormkeeper_enhancement) or buffstacks(maelstrom_weapon) == 10 and spell(chain_lightning) or target.refreshable(flame_shock) and hastalent(fire_nova_talent) and spell(flame_shock) or spell(sundering) or spell(stormstrike) or spell(lava_lash) or target.refreshable(flame_shock) and spell(flame_shock) or buffstacks(maelstrom_weapon) >= 5 and enemies() == 3 and spell(elemental_blast)
 {
  #fae_transfusion
  spell(fae_transfusion)
 }
}

AddFunction enhancementaoecdpostconditions
{
 buffpresent(hailstorm) and spell(frost_shock) or debuffcountonany(flame_shock) >= 3 and spell(fire_nova) or target.refreshable(flame_shock) and { hastalent(fire_nova_talent) or covenant(necrolord) } and spell(flame_shock) or not buffpresent(primordial_wave) and { not hastalent(stormkeeper_talent_enhancement) or buffpresent(stormkeeper_enhancement) } and spell(primordial_wave) or spell(vesper_totem) or buffpresent(primordial_wave) and buffstacks(maelstrom_weapon) >= 5 and spell(lightning_bolt) or spell(crash_lightning) or buffpresent(stormkeeper_enhancement) and buffstacks(maelstrom_weapon) >= 5 and spell(chain_lightning) or buffstacks(maelstrom_weapon) >= 5 and spell(chain_harvest) or buffstacks(maelstrom_weapon) >= 5 and enemies() != 3 and spell(elemental_blast) or buffstacks(maelstrom_weapon) >= 5 and spell(stormkeeper_enhancement) or buffstacks(maelstrom_weapon) == 10 and spell(chain_lightning) or target.refreshable(flame_shock) and hastalent(fire_nova_talent) and spell(flame_shock) or spell(sundering) or spell(stormstrike) or spell(lava_lash) or target.refreshable(flame_shock) and spell(flame_shock) or buffstacks(maelstrom_weapon) >= 5 and enemies() == 3 and spell(elemental_blast) or spell(frost_shock) or spell(ice_strike) or buffstacks(maelstrom_weapon) >= 5 and spell(chain_lightning) or debuffcountonany(flame_shock) > 1 and spell(fire_nova) or spell(earthen_spike) or spell(earth_elemental) or buffremaining(windfury_totem) < 30 and spell(windfury_totem)
}

### actions.default

AddFunction enhancement_defaultmainactions
{
 #windstrike
 spell(windstrike)
 #heart_essence
 spell(296208)
 #berserking,if=!talent.ascendance.enabled|buff.ascendance.up
 if not hastalent(ascendance_talent_enhancement) or buffpresent(ascendance_enhancement) spell(berserking)
 #ascendance
 if buffexpires(ascendance_enhancement_buff) spell(ascendance_enhancement)
 #call_action_list,name=single,if=active_enemies=1
 if enemies() == 1 enhancementsinglemainactions()

 unless enemies() == 1 and enhancementsinglemainpostconditions()
 {
  #call_action_list,name=aoe,if=active_enemies>1
  if enemies() > 1 enhancementaoemainactions()
 }
}

AddFunction enhancement_defaultmainpostconditions
{
 enemies() == 1 and enhancementsinglemainpostconditions() or enemies() > 1 and enhancementaoemainpostconditions()
}

AddFunction enhancement_defaultshortcdactions
{
 #auto_attack
 enhancementgetinmeleerange()

 unless spell(windstrike) or spell(296208) or { not hastalent(ascendance_talent_enhancement) or buffpresent(ascendance_enhancement) } and spell(berserking)
 {
  #bag_of_tricks,if=!talent.ascendance.enabled|!buff.ascendance.up
  if not hastalent(ascendance_talent_enhancement) or not buffpresent(ascendance_enhancement) spell(bag_of_tricks)

  unless buffexpires(ascendance_enhancement_buff) and spell(ascendance_enhancement)
  {
   #call_action_list,name=single,if=active_enemies=1
   if enemies() == 1 enhancementsingleshortcdactions()

   unless enemies() == 1 and enhancementsingleshortcdpostconditions()
   {
    #call_action_list,name=aoe,if=active_enemies>1
    if enemies() > 1 enhancementaoeshortcdactions()
   }
  }
 }
}

AddFunction enhancement_defaultshortcdpostconditions
{
 spell(windstrike) or spell(296208) or { not hastalent(ascendance_talent_enhancement) or buffpresent(ascendance_enhancement) } and spell(berserking) or buffexpires(ascendance_enhancement_buff) and spell(ascendance_enhancement) or enemies() == 1 and enhancementsingleshortcdpostconditions() or enemies() > 1 and enhancementaoeshortcdpostconditions()
}

AddFunction enhancement_defaultcdactions
{
 #bloodlust
 enhancementbloodlust()
 #potion,if=expected_combat_length-time<60
 #wind_shear
 enhancementinterruptactions()

 unless spell(windstrike) or spell(296208)
 {
  #use_items
  enhancementuseitemactions()
  #blood_fury,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
  if not hastalent(ascendance_talent_enhancement) or buffpresent(ascendance_enhancement) or spellcooldown(ascendance_enhancement) > 50 spell(blood_fury)

  unless { not hastalent(ascendance_talent_enhancement) or buffpresent(ascendance_enhancement) } and spell(berserking)
  {
   #fireblood,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
   if not hastalent(ascendance_talent_enhancement) or buffpresent(ascendance_enhancement) or spellcooldown(ascendance_enhancement) > 50 spell(fireblood)
   #ancestral_call,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
   if not hastalent(ascendance_talent_enhancement) or buffpresent(ascendance_enhancement) or spellcooldown(ascendance_enhancement) > 50 spell(ancestral_call)

   unless { not hastalent(ascendance_talent_enhancement) or not buffpresent(ascendance_enhancement) } and spell(bag_of_tricks)
   {
    #feral_spirit
    spell(feral_spirit)

    unless buffexpires(ascendance_enhancement_buff) and spell(ascendance_enhancement)
    {
     #call_action_list,name=single,if=active_enemies=1
     if enemies() == 1 enhancementsinglecdactions()

     unless enemies() == 1 and enhancementsinglecdpostconditions()
     {
      #call_action_list,name=aoe,if=active_enemies>1
      if enemies() > 1 enhancementaoecdactions()
     }
    }
   }
  }
 }
}

AddFunction enhancement_defaultcdpostconditions
{
 spell(windstrike) or spell(296208) or { not hastalent(ascendance_talent_enhancement) or buffpresent(ascendance_enhancement) } and spell(berserking) or { not hastalent(ascendance_talent_enhancement) or not buffpresent(ascendance_enhancement) } and spell(bag_of_tricks) or buffexpires(ascendance_enhancement_buff) and spell(ascendance_enhancement) or enemies() == 1 and enhancementsinglecdpostconditions() or enemies() > 1 and enhancementaoecdpostconditions()
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
# ascendance_enhancement
# ascendance_enhancement_buff
# ascendance_talent_enhancement
# bag_of_tricks
# berserking
# blood_fury
# bloodlust
# capacitor_totem
# chain_harvest
# chain_lightning
# crash_lightning
# earth_elemental
# earthen_spike
# elemental_blast
# fae_transfusion
# feral_lunge
# feral_spirit
# fire_nova
# fire_nova_talent
# fireblood
# flame_shock
# flametongue_weapon
# frost_shock
# hailstorm
# heroism
# hex
# hot_hand_buff
# ice_strike
# lava_lash
# lightning_bolt
# lightning_shield
# maelstrom_weapon
# necrolord
# primordial_wave
# quaking_palm
# stormkeeper_enhancement
# stormkeeper_talent_enhancement
# stormstrike
# sundering
# vesper_totem
# war_stomp
# wind_shear
# windfury_totem
# windfury_weapon
# windstrike
]]
        OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
    end
    do
        local name = "sc_t25_shaman_restoration"
        local desc = "[9.0] Simulationcraft: T25_Shaman_Restoration"
        local code = [[
# Based on SimulationCraft profile "T25_Shaman_Restoration".
#	class=shaman
#	spec=restoration
#	talents=1111111

Include(ovale_common)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=restoration)

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
 #use_item,name=azsharas_font_of_power
 restorationuseitemactions()
}

AddFunction restorationprecombatcdpostconditions
{
 spell(lava_burst)
}

### actions.default

AddFunction restoration_defaultmainactions
{
 #flame_shock,target_if=(!ticking|dot.flame_shock.remains<=gcd)|refreshable
 if not buffpresent(flame_shock) or target.debuffremaining(flame_shock) <= gcd() or target.refreshable(flame_shock) spell(flame_shock)
 #berserking
 spell(berserking)
 #worldvein_resonance
 spell(worldvein_resonance)
 #lava_burst,if=dot.flame_shock.remains>cast_time&cooldown_react
 if target.debuffremaining(flame_shock) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 spell(lava_burst)
 #concentrated_flame,if=dot.concentrated_flame_burn.remains=0
 if not target.debuffremaining(concentrated_flame_burn_debuff) > 0 spell(concentrated_flame)
 #ripple_in_space
 spell(ripple_in_space)
 #earth_elemental
 spell(earth_elemental)
 #lightning_bolt,if=spell_targets.chain_lightning<2
 if enemies() < 2 spell(lightning_bolt)
 #chain_lightning,if=spell_targets.chain_lightning>1
 if enemies() > 1 spell(chain_lightning)
 #flame_shock,moving=1
 if speed() > 0 spell(flame_shock)
}

AddFunction restoration_defaultmainpostconditions
{
}

AddFunction restoration_defaultshortcdactions
{
 unless { not buffpresent(flame_shock) or target.debuffremaining(flame_shock) <= gcd() or target.refreshable(flame_shock) } and spell(flame_shock) or spell(berserking) or spell(worldvein_resonance) or target.debuffremaining(flame_shock) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame) or spell(ripple_in_space) or spell(earth_elemental)
 {
  #bag_of_tricks
  spell(bag_of_tricks)
 }
}

AddFunction restoration_defaultshortcdpostconditions
{
 { not buffpresent(flame_shock) or target.debuffremaining(flame_shock) <= gcd() or target.refreshable(flame_shock) } and spell(flame_shock) or spell(berserking) or spell(worldvein_resonance) or target.debuffremaining(flame_shock) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame) or spell(ripple_in_space) or spell(earth_elemental) or enemies() < 2 and spell(lightning_bolt) or enemies() > 1 and spell(chain_lightning) or speed() > 0 and spell(flame_shock)
}

AddFunction restoration_defaultcdactions
{
 #potion
 #wind_shear
 restorationinterruptactions()
 #spiritwalkers_grace,moving=1,if=movement.distance>6
 if speed() > 0 and target.distance() > 6 spell(spiritwalkers_grace)

 unless { not buffpresent(flame_shock) or target.debuffremaining(flame_shock) <= gcd() or target.refreshable(flame_shock) } and spell(flame_shock)
 {
  #use_items
  restorationuseitemactions()
  #blood_fury
  spell(blood_fury)

  unless spell(berserking)
  {
   #fireblood
   spell(fireblood)
   #ancestral_call
   spell(ancestral_call)

   unless spell(worldvein_resonance) or target.debuffremaining(flame_shock) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame) or spell(ripple_in_space) or spell(earth_elemental) or spell(bag_of_tricks)
   {
    #fae_transfusion
    spell(fae_transfusion)
   }
  }
 }
}

AddFunction restoration_defaultcdpostconditions
{
 { not buffpresent(flame_shock) or target.debuffremaining(flame_shock) <= gcd() or target.refreshable(flame_shock) } and spell(flame_shock) or spell(berserking) or spell(worldvein_resonance) or target.debuffremaining(flame_shock) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame) or spell(ripple_in_space) or spell(earth_elemental) or spell(bag_of_tricks) or enemies() < 2 and spell(lightning_bolt) or enemies() > 1 and spell(chain_lightning) or speed() > 0 and spell(flame_shock)
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
# bag_of_tricks
# berserking
# blood_fury
# capacitor_totem
# chain_lightning
# concentrated_flame
# concentrated_flame_burn_debuff
# earth_elemental
# fae_transfusion
# fireblood
# flame_shock
# hex
# lava_burst
# lightning_bolt
# quaking_palm
# ripple_in_space
# spiritwalkers_grace
# war_stomp
# wind_shear
# worldvein_resonance
]]
        OvaleScripts:RegisterScript("SHAMAN", "restoration", name, desc, code, "script")
    end
end
