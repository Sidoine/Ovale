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

### actions.precombat

AddFunction balanceprecombatmainactions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #moonkin_form
 spell(moonkin_form)
}

AddFunction balanceprecombatmainpostconditions
{
}

AddFunction balanceprecombatshortcdactions
{
}

AddFunction balanceprecombatshortcdpostconditions
{
 spell(moonkin_form)
}

AddFunction balanceprecombatcdactions
{
}

AddFunction balanceprecombatcdpostconditions
{
 spell(moonkin_form)
}

### actions.default

AddFunction balance_defaultmainactions
{
 #wrath
 spell(wrath)
}

AddFunction balance_defaultmainpostconditions
{
}

AddFunction balance_defaultshortcdactions
{
}

AddFunction balance_defaultshortcdpostconditions
{
 spell(wrath)
}

AddFunction balance_defaultcdactions
{
 balanceinterruptactions()
}

AddFunction balance_defaultcdpostconditions
{
 spell(wrath)
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
# mighty_bash
# moonkin_form
# solar_beam
# typhoon
# war_stomp
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
 #cat_form
 spell(cat_form)
}

AddFunction feralprecombatmainpostconditions
{
}

AddFunction feralprecombatshortcdactions
{
}

AddFunction feralprecombatshortcdpostconditions
{
 spell(cat_form)
}

AddFunction feralprecombatcdactions
{
}

AddFunction feralprecombatcdpostconditions
{
 spell(cat_form)
}

### actions.default

AddFunction feral_defaultmainactions
{
 #shred
 spell(shred)
}

AddFunction feral_defaultmainpostconditions
{
}

AddFunction feral_defaultshortcdactions
{
 #auto_attack
 feralgetinmeleerange()
}

AddFunction feral_defaultshortcdpostconditions
{
 spell(shred)
}

AddFunction feral_defaultcdactions
{
 feralinterruptactions()
}

AddFunction feral_defaultcdpostconditions
{
 spell(shred)
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
# cat_form
# maim
# mangle
# mighty_bash
# shred
# skull_bash
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
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
 #flask
 #food
 #augmentation
 #snapshot_stats
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
}

AddFunction guardianprecombatcdpostconditions
{
 spell(bear_form)
}

### actions.default

AddFunction guardian_defaultmainactions
{
 #adaptive_swarm
 spell(adaptive_swarm)
 #potion,if=buff.berserk_bear.up|buff.incarnation_guardian_of_ursoc.up
 if { buffpresent(berserk_bear_buff) or buffpresent(incarnation_guardian_of_ursoc) } and checkboxon(opt_use_consumables) and target.classification(worldboss) item(disabled_item usable=1)
 #berserk_bear,if=buff.ravenous_frenzy.up|!covenant.venthyr
 if buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") spell(berserk_bear)
 #incarnation,if=buff.ravenous_frenzy.up|!covenant.venthyr
 if buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") spell(incarnation)
 #thrash_bear,if=spell_targets>3
 if enemies() > 3 spell(thrash_bear)
 #moonfire,target_if=refreshable
 if target.refreshable(moonfire) spell(moonfire)
 #moonfire,if=buff.galactic_guardian.up&buff.galactic_guardian.remains<1.5
 if buffpresent(galactic_guardian) and buffremaining(galactic_guardian) < 1.5 spell(moonfire)
 #thrash_bear,target_if=refreshable|dot.thrash_bear.stack<3|dot.thrash_bear.stack<4&runeforge.luffainfused_embrace.equipped
 if target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and message("runeforge.luffainfused_embrace.equipped is not implemented") spell(thrash_bear)
 #mangle,if=talent.soul_of_the_forest.enabled|rage<80|!buff.berserk_bear.up&!buff.incarnation_guardian_of_ursoc.up
 if hastalent(soul_of_the_forest_talent_guardian) or rage() < 80 or not buffpresent(berserk_bear_buff) and not buffpresent(incarnation_guardian_of_ursoc) spell(mangle)
 #thrash_bear
 spell(thrash_bear)
 #maul,if=buff.tooth_and_claw.up&buff.tooth_and_claw.remains<1.5
 if buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 spell(maul)
 #maul,if=rage>=80
 if rage() >= 80 spell(maul)
 #swipe_bear
 spell(swipe_bear)
}

AddFunction guardian_defaultmainpostconditions
{
}

AddFunction guardian_defaultshortcdactions
{
 #auto_attack
 guardiangetinmeleerange()
 #empower_bond
 spell(empower_bond)

 unless spell(adaptive_swarm) or { buffpresent(berserk_bear_buff) or buffpresent(incarnation_guardian_of_ursoc) } and checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(berserk_bear) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(incarnation)
 {
  #pulverize,target_if=dot.thrash_bear.stack>2
  if target.debuffstacks(thrash_bear_debuff) > 2 and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) spell(pulverize)
 }
}

AddFunction guardian_defaultshortcdpostconditions
{
 spell(adaptive_swarm) or { buffpresent(berserk_bear_buff) or buffpresent(incarnation_guardian_of_ursoc) } and checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(berserk_bear) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(incarnation) or enemies() > 3 and spell(thrash_bear) or target.refreshable(moonfire) and spell(moonfire) or buffpresent(galactic_guardian) and buffremaining(galactic_guardian) < 1.5 and spell(moonfire) or { target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and message("runeforge.luffainfused_embrace.equipped is not implemented") } and spell(thrash_bear) or { hastalent(soul_of_the_forest_talent_guardian) or rage() < 80 or not buffpresent(berserk_bear_buff) and not buffpresent(incarnation_guardian_of_ursoc) } and spell(mangle) or spell(thrash_bear) or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 and spell(maul) or rage() >= 80 and spell(maul) or spell(swipe_bear)
}

AddFunction guardian_defaultcdactions
{
 guardianinterruptactions()
 #ravenous_frenzy
 spell(ravenous_frenzy)

 unless spell(empower_bond) or spell(adaptive_swarm) or { buffpresent(berserk_bear_buff) or buffpresent(incarnation_guardian_of_ursoc) } and checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1)
 {
  #use_items
  guardianuseitemactions()
 }
}

AddFunction guardian_defaultcdpostconditions
{
 spell(empower_bond) or spell(adaptive_swarm) or { buffpresent(berserk_bear_buff) or buffpresent(incarnation_guardian_of_ursoc) } and checkboxon(opt_use_consumables) and target.classification(worldboss) and item(disabled_item usable=1) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(berserk_bear) or { buffpresent(ravenous_frenzy) or not message("covenant.venthyr is not implemented") } and spell(incarnation) or target.debuffstacks(thrash_bear_debuff) > 2 and target.debuffgain(thrash_bear_debuff) <= baseduration(thrash_bear_debuff) and spell(pulverize) or enemies() > 3 and spell(thrash_bear) or target.refreshable(moonfire) and spell(moonfire) or buffpresent(galactic_guardian) and buffremaining(galactic_guardian) < 1.5 and spell(moonfire) or { target.refreshable(thrash_bear_debuff) or target.debuffstacks(thrash_bear_debuff) < 3 or target.debuffstacks(thrash_bear_debuff) < 4 and message("runeforge.luffainfused_embrace.equipped is not implemented") } and spell(thrash_bear) or { hastalent(soul_of_the_forest_talent_guardian) or rage() < 80 or not buffpresent(berserk_bear_buff) and not buffpresent(incarnation_guardian_of_ursoc) } and spell(mangle) or spell(thrash_bear) or buffpresent(tooth_and_claw_buff) and buffremaining(tooth_and_claw_buff) < 1.5 and spell(maul) or rage() >= 80 and spell(maul) or spell(swipe_bear)
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
# bear_form
# berserk_bear
# berserk_bear_buff
# disabled_item
# empower_bond
# galactic_guardian
# incapacitating_roar
# incarnation
# incarnation_guardian_of_ursoc
# mangle
# maul
# mighty_bash
# moonfire
# pulverize
# ravenous_frenzy
# shred
# skull_bash
# soul_of_the_forest_talent_guardian
# swipe_bear
# thrash_bear
# thrash_bear_debuff
# tooth_and_claw_buff
# typhoon
# war_stomp
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
        OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
    end
end
