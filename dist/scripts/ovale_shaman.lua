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

AddFunction elementalbloodlust
{
 if checkboxon(opt_bloodlust) and debuffexpires(burst_haste_debuff any=1)
 {
  spell(bloodlust)
  spell(heroism)
 }
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

### actions.default

AddFunction elemental_defaultmainactions
{
 #lightning_bolt
 spell(lightning_bolt)
}

AddFunction elemental_defaultmainpostconditions
{
}

AddFunction elemental_defaultshortcdactions
{
}

AddFunction elemental_defaultshortcdpostconditions
{
 spell(lightning_bolt)
}

AddFunction elemental_defaultcdactions
{
 elementalinterruptactions()
 #bloodlust
 elementalbloodlust()
}

AddFunction elemental_defaultcdpostconditions
{
 spell(lightning_bolt)
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
# bloodlust
# capacitor_totem
# heroism
# hex
# lightning_bolt
# quaking_palm
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
#	talents=3202023

Include(ovale_common)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt l(interrupt) default specialization=enhancement)
AddCheckBox(opt_melee_range l(not_in_melee_range) specialization=enhancement)

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

AddFunction enhancementgetinmeleerange
{
 if checkboxon(opt_melee_range) and not target.inrange(stormstrike)
 {
  if target.inrange(feral_lunge) spell(feral_lunge)
  texture(misc_arrowlup help=l(not_in_melee_range))
 }
}

### actions.precombat

AddFunction enhancementprecombatmainactions
{
}

AddFunction enhancementprecombatmainpostconditions
{
}

AddFunction enhancementprecombatshortcdactions
{
}

AddFunction enhancementprecombatshortcdpostconditions
{
}

AddFunction enhancementprecombatcdactions
{
}

AddFunction enhancementprecombatcdpostconditions
{
}

### actions.default

AddFunction enhancement_defaultmainactions
{
 #windstrike
 spell(windstrike)
 #earth_elemental
 spell(earth_elemental)
 #lava_lash
 spell(lava_lash)
 #stormstrike
 spell(stormstrike)
 #crash_lightning
 spell(crash_lightning)
 #flame_shock
 spell(flame_shock)
 #frost_shock
 spell(frost_shock)
 #lightning_bolt
 spell(lightning_bolt)
 #chain_lightning
 spell(chain_lightning)
}

AddFunction enhancement_defaultmainpostconditions
{
}

AddFunction enhancement_defaultshortcdactions
{
 #auto_attack
 enhancementgetinmeleerange()
}

AddFunction enhancement_defaultshortcdpostconditions
{
 spell(windstrike) or spell(earth_elemental) or spell(lava_lash) or spell(stormstrike) or spell(crash_lightning) or spell(flame_shock) or spell(frost_shock) or spell(lightning_bolt) or spell(chain_lightning)
}

AddFunction enhancement_defaultcdactions
{
 #wind_shear
 enhancementinterruptactions()

 unless spell(windstrike)
 {
  #feral_spirit
  spell(feral_spirit)
 }
}

AddFunction enhancement_defaultcdpostconditions
{
 spell(windstrike) or spell(earth_elemental) or spell(lava_lash) or spell(stormstrike) or spell(crash_lightning) or spell(flame_shock) or spell(frost_shock) or spell(lightning_bolt) or spell(chain_lightning)
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
# capacitor_totem
# chain_lightning
# crash_lightning
# earth_elemental
# feral_lunge
# feral_spirit
# flame_shock
# frost_shock
# hex
# lava_lash
# lightning_bolt
# quaking_palm
# stormstrike
# sundering
# war_stomp
# wind_shear
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
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(disabled_item usable=1)
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
 checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1) or spell(lava_burst)
}

AddFunction restorationprecombatcdactions
{
 unless checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1)
 {
  #use_item,name=azsharas_font_of_power
  restorationuseitemactions()
 }
}

AddFunction restorationprecombatcdpostconditions
{
 checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1) or spell(lava_burst)
}

### actions.default

AddFunction restoration_defaultmainactions
{
 #potion
 if checkboxon(opt_use_consumables) and target.classification(worldboss) item(disabled_item usable=1)
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
 unless checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1) or { not buffpresent(flame_shock) or target.debuffremaining(flame_shock) <= gcd() or target.refreshable(flame_shock) } and spell(flame_shock) or spell(berserking) or spell(worldvein_resonance) or target.debuffremaining(flame_shock) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame) or spell(ripple_in_space) or spell(earth_elemental)
 {
  #bag_of_tricks
  spell(bag_of_tricks)
 }
}

AddFunction restoration_defaultshortcdpostconditions
{
 checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1) or { not buffpresent(flame_shock) or target.debuffremaining(flame_shock) <= gcd() or target.refreshable(flame_shock) } and spell(flame_shock) or spell(berserking) or spell(worldvein_resonance) or target.debuffremaining(flame_shock) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame) or spell(ripple_in_space) or spell(earth_elemental) or enemies() < 2 and spell(lightning_bolt) or enemies() > 1 and spell(chain_lightning) or speed() > 0 and spell(flame_shock)
}

AddFunction restoration_defaultcdactions
{
 unless checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1)
 {
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
}

AddFunction restoration_defaultcdpostconditions
{
 checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1) or { not buffpresent(flame_shock) or target.debuffremaining(flame_shock) <= gcd() or target.refreshable(flame_shock) } and spell(flame_shock) or spell(berserking) or spell(worldvein_resonance) or target.debuffremaining(flame_shock) > casttime(lava_burst) and not spellcooldown(lava_burst) > 0 and spell(lava_burst) or not target.debuffremaining(concentrated_flame_burn_debuff) > 0 and spell(concentrated_flame) or spell(ripple_in_space) or spell(earth_elemental) or spell(bag_of_tricks) or enemies() < 2 and spell(lightning_bolt) or enemies() > 1 and spell(chain_lightning) or speed() > 0 and spell(flame_shock)
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
# disabled_item
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
