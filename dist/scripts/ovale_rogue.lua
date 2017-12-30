local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_rogue_assassination_exsg_t19"
    local desc = "[7.0] Simulationcraft: Rogue_Assassination_Exsg_T19"
    local code = [[
# Based on SimulationCraft profile "Rogue_Assassination_Exsg_T19P".
#	class=rogue
#	spec=assassination
#	talents=2130131

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction energy_time_to_max_combined
{
 EnergyDeficit() / energy_regen_combined()
}

AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * { 7 + TalentPoints(venom_rush_talent) * 3 } / 2
}

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=assassination)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=assassination)
AddCheckBox(opt_vanish SpellName(vanish) default specialization=assassination)

AddFunction AssassinationUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction AssassinationGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
 {
  Spell(shadowstep)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.precombat

AddFunction AssassinationPrecombatMainActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #apply_poison
 #stealth
 Spell(stealth)
}

AddFunction AssassinationPrecombatMainPostConditions
{
}

AddFunction AssassinationPrecombatShortCdActions
{
 unless Spell(stealth)
 {
  #marked_for_death,if=raid_event.adds.in>40
  if 600 > 40 Spell(marked_for_death)
 }
}

AddFunction AssassinationPrecombatShortCdPostConditions
{
 Spell(stealth)
}

AddFunction AssassinationPrecombatCdActions
{
 unless Spell(stealth)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 }
}

AddFunction AssassinationPrecombatCdPostConditions
{
 Spell(stealth) or 600 > 40 and Spell(marked_for_death)
}

### actions.maintain

AddFunction AssassinationMaintainMainActions
{
 #rupture,if=talent.nightstalker.enabled&stealthed.rogue&(!equipped.mantle_of_the_master_assassin|!set_bonus.tier19_4pc)&(talent.exsanguinate.enabled|target.time_to_die-remains>4)
 if Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } Spell(rupture)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&stealthed.rogue&combo_points.deficit>=1&set_bonus.tier20_4pc&((dot.garrote.remains<=13&!debuff.toxic_blade.up)|pmultiplier<=1)&!exsanguinated
 if Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) Spell(garrote)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&stealthed.rogue&combo_points.deficit>=1&!set_bonus.tier20_4pc&refreshable&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&stealthed.rogue&combo_points.deficit>=1&!set_bonus.tier20_4pc&remains<=10&pmultiplier<=1&!exsanguinated&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #rupture,if=!talent.exsanguinate.enabled&combo_points>=3&!ticking&mantle_duration<=0.2&target.time_to_die>6
 if not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 Spell(rupture)
 #rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2+artifact.urge_to_kill.enabled)))
 if Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } Spell(rupture)
 #rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time)&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>6
 if ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 Spell(rupture)
 #call_action_list,name=kb,if=combo_points.deficit>=1+(mantle_duration>=0.2)&(!talent.exsanguinate.enabled|!cooldown.exanguinate.up|time>9)
 if ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } AssassinationKbMainActions()

 unless ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } and AssassinationKbMainPostConditions()
 {
  #pool_resource,for_next=1
  #garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time)&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>4
  if { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 Spell(garrote)
  unless { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
  {
   #garrote,if=set_bonus.tier20_4pc&talent.exsanguinate.enabled&prev_gcd.1.rupture&cooldown.exsanguinate.remains<1&(!cooldown.vanish.up|time>12)
   if ArmorSetBonus(T20 4) and Talent(exsanguinate_talent) and PreviousGCDSpell(rupture) and SpellCooldown(exsanguinate) < 1 and { not { not SpellCooldown(vanish) > 0 } or TimeInCombat() > 12 } Spell(garrote)
  }
 }
}

AddFunction AssassinationMaintainMainPostConditions
{
 ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } and AssassinationKbMainPostConditions()
}

AddFunction AssassinationMaintainShortCdActions
{
 unless Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } and Spell(rupture) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 and Spell(rupture) or Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } and Spell(rupture) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture)
 {
  #call_action_list,name=kb,if=combo_points.deficit>=1+(mantle_duration>=0.2)&(!talent.exsanguinate.enabled|!cooldown.exanguinate.up|time>9)
  if ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } AssassinationKbShortCdActions()
 }
}

AddFunction AssassinationMaintainShortCdPostConditions
{
 Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } and Spell(rupture) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 and Spell(rupture) or Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } and Spell(rupture) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } and AssassinationKbShortCdPostConditions() or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and ArmorSetBonus(T20 4) and Talent(exsanguinate_talent) and PreviousGCDSpell(rupture) and SpellCooldown(exsanguinate) < 1 and { not { not SpellCooldown(vanish) > 0 } or TimeInCombat() > 12 } and Spell(garrote)
}

AddFunction AssassinationMaintainCdActions
{
 unless Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } and Spell(rupture) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 and Spell(rupture) or Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } and Spell(rupture) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture)
 {
  #call_action_list,name=kb,if=combo_points.deficit>=1+(mantle_duration>=0.2)&(!talent.exsanguinate.enabled|!cooldown.exanguinate.up|time>9)
  if ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } AssassinationKbCdActions()
 }
}

AddFunction AssassinationMaintainCdPostConditions
{
 Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } and Spell(rupture) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 and Spell(rupture) or Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } and Spell(rupture) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } and AssassinationKbCdPostConditions() or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and ArmorSetBonus(T20 4) and Talent(exsanguinate_talent) and PreviousGCDSpell(rupture) and SpellCooldown(exsanguinate) < 1 and { not { not SpellCooldown(vanish) > 0 } or TimeInCombat() > 12 } and Spell(garrote)
}

### actions.kb

AddFunction AssassinationKbMainActions
{
 #kingsbane,if=artifact.sinister_circulation.enabled&!(equipped.duskwalkers_footpads&equipped.convergence_of_fates&artifact.master_assassin.rank>=6)&(time>25|!equipped.mantle_of_the_master_assassin|(debuff.vendetta.up&debuff.surge_of_toxins.up))&(talent.subterfuge.enabled|!stealthed.rogue|(talent.nightstalker.enabled&(!equipped.mantle_of_the_master_assassin|!set_bonus.tier19_4pc)))
 if HasArtifactTrait(sinister_circulation) and not { HasEquippedItem(duskwalkers_footpads) and HasEquippedItem(convergence_of_fates) and ArtifactTraitRank(master_assassin) >= 6 } and { TimeInCombat() > 25 or not HasEquippedItem(mantle_of_the_master_assassin) or target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) } and { Talent(subterfuge_talent) or not Stealthed() or Talent(nightstalker_talent) and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } } Spell(kingsbane)
 #kingsbane,if=buff.envenom.up&((debuff.vendetta.up&debuff.surge_of_toxins.up)|cooldown.vendetta.remains<=5.8|cooldown.vendetta.remains>=10)
 if BuffPresent(envenom_buff) and { target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) or SpellCooldown(vendetta) <= 5 or SpellCooldown(vendetta) >= 10 } Spell(kingsbane)
}

AddFunction AssassinationKbMainPostConditions
{
}

AddFunction AssassinationKbShortCdActions
{
}

AddFunction AssassinationKbShortCdPostConditions
{
 HasArtifactTrait(sinister_circulation) and not { HasEquippedItem(duskwalkers_footpads) and HasEquippedItem(convergence_of_fates) and ArtifactTraitRank(master_assassin) >= 6 } and { TimeInCombat() > 25 or not HasEquippedItem(mantle_of_the_master_assassin) or target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) } and { Talent(subterfuge_talent) or not Stealthed() or Talent(nightstalker_talent) and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } } and Spell(kingsbane) or BuffPresent(envenom_buff) and { target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) or SpellCooldown(vendetta) <= 5 or SpellCooldown(vendetta) >= 10 } and Spell(kingsbane)
}

AddFunction AssassinationKbCdActions
{
}

AddFunction AssassinationKbCdPostConditions
{
 HasArtifactTrait(sinister_circulation) and not { HasEquippedItem(duskwalkers_footpads) and HasEquippedItem(convergence_of_fates) and ArtifactTraitRank(master_assassin) >= 6 } and { TimeInCombat() > 25 or not HasEquippedItem(mantle_of_the_master_assassin) or target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) } and { Talent(subterfuge_talent) or not Stealthed() or Talent(nightstalker_talent) and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } } and Spell(kingsbane) or BuffPresent(envenom_buff) and { target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) or SpellCooldown(vendetta) <= 5 or SpellCooldown(vendetta) >= 10 } and Spell(kingsbane)
}

### actions.finish

AddFunction AssassinationFinishMainActions
{
 #death_from_above,if=combo_points>=5
 if ComboPoints() >= 5 Spell(death_from_above)
 #envenom,if=combo_points>=4+(talent.deeper_stratagem.enabled&!set_bonus.tier19_4pc)&(debuff.vendetta.up|mantle_duration>=0.2|debuff.surge_of_toxins.remains<0.2|energy.deficit<=25+variable.energy_regen_combined)
 if ComboPoints() >= 4 + { Talent(deeper_stratagem_talent) and not ArmorSetBonus(T19 4) } and { target.DebuffPresent(vendetta_debuff) or BuffRemaining(master_assassins_initiative) >= 0 or target.DebuffRemaining(surge_of_toxins_debuff) < 0 or EnergyDeficit() <= 25 + energy_regen_combined() } Spell(envenom)
 #envenom,if=talent.elaborate_planning.enabled&combo_points>=3+!talent.exsanguinate.enabled&buff.elaborate_planning.remains<0.2
 if Talent(elaborate_planning_talent) and ComboPoints() >= 3 + Talent(exsanguinate_talent no) and BuffRemaining(elaborate_planning_buff) < 0 Spell(envenom)
}

AddFunction AssassinationFinishMainPostConditions
{
}

AddFunction AssassinationFinishShortCdActions
{
}

AddFunction AssassinationFinishShortCdPostConditions
{
 ComboPoints() >= 5 and Spell(death_from_above) or ComboPoints() >= 4 + { Talent(deeper_stratagem_talent) and not ArmorSetBonus(T19 4) } and { target.DebuffPresent(vendetta_debuff) or BuffRemaining(master_assassins_initiative) >= 0 or target.DebuffRemaining(surge_of_toxins_debuff) < 0 or EnergyDeficit() <= 25 + energy_regen_combined() } and Spell(envenom) or Talent(elaborate_planning_talent) and ComboPoints() >= 3 + Talent(exsanguinate_talent no) and BuffRemaining(elaborate_planning_buff) < 0 and Spell(envenom)
}

AddFunction AssassinationFinishCdActions
{
}

AddFunction AssassinationFinishCdPostConditions
{
 ComboPoints() >= 5 and Spell(death_from_above) or ComboPoints() >= 4 + { Talent(deeper_stratagem_talent) and not ArmorSetBonus(T19 4) } and { target.DebuffPresent(vendetta_debuff) or BuffRemaining(master_assassins_initiative) >= 0 or target.DebuffRemaining(surge_of_toxins_debuff) < 0 or EnergyDeficit() <= 25 + energy_regen_combined() } and Spell(envenom) or Talent(elaborate_planning_talent) and ComboPoints() >= 3 + Talent(exsanguinate_talent no) and BuffRemaining(elaborate_planning_buff) < 0 and Spell(envenom)
}

### actions.cds

AddFunction AssassinationCdsMainActions
{
 #exsanguinate,if=!set_bonus.tier20_4pc&(prev_gcd.1.rupture&dot.rupture.remains>4+4*cp_max_spend&!stealthed.rogue|dot.garrote.pmultiplier>1&!cooldown.vanish.up&buff.subterfuge.up)
 if not ArmorSetBonus(T20 4) and { PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not Stealthed() or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and not { not SpellCooldown(vanish) > 0 } and BuffPresent(subterfuge_buff) } Spell(exsanguinate)
 #exsanguinate,if=set_bonus.tier20_4pc&dot.garrote.remains>20&dot.rupture.remains>4+4*cp_max_spend
 if ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) > 20 and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() Spell(exsanguinate)
 #toxic_blade,if=combo_points.deficit>=1+(mantle_duration>=0.2)&dot.rupture.remains>8&cooldown.vendetta.remains>10
 if ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and target.DebuffRemaining(rupture_debuff) > 8 and SpellCooldown(vendetta) > 10 Spell(toxic_blade)
}

AddFunction AssassinationCdsMainPostConditions
{
}

AddFunction AssassinationCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit*1.5|(raid_event.adds.in>40&combo_points.deficit>=cp_max_spend)
 if target.TimeToDie() < ComboPointsDeficit() * 1 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)

 unless not ArmorSetBonus(T20 4) and { PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not Stealthed() or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and not { not SpellCooldown(vanish) > 0 } and BuffPresent(subterfuge_buff) } and Spell(exsanguinate) or ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) > 20 and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and Spell(exsanguinate)
 {
  #vanish,if=talent.nightstalker.enabled&combo_points>=cp_max_spend&!talent.exsanguinate.enabled&mantle_duration=0&((equipped.mantle_of_the_master_assassin&set_bonus.tier19_4pc)|((!equipped.mantle_of_the_master_assassin|!set_bonus.tier19_4pc)&(dot.rupture.refreshable|debuff.vendetta.up)))
  if Talent(nightstalker_talent) and ComboPoints() >= MaxComboPoints() and not Talent(exsanguinate_talent) and BuffRemaining(master_assassins_initiative) == 0 and { HasEquippedItem(mantle_of_the_master_assassin) and ArmorSetBonus(T19 4) or { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { target.DebuffRefreshable(rupture_debuff) or target.DebuffPresent(vendetta_debuff) } } and CheckBoxOn(opt_vanish) Spell(vanish)
  #vanish,if=talent.nightstalker.enabled&combo_points>=cp_max_spend&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&(dot.rupture.ticking|time>10)
  if Talent(nightstalker_talent) and ComboPoints() >= MaxComboPoints() and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and { target.DebuffPresent(rupture_debuff) or TimeInCombat() > 10 } and CheckBoxOn(opt_vanish) Spell(vanish)
  #vanish,if=talent.subterfuge.enabled&equipped.mantle_of_the_master_assassin&(debuff.vendetta.up|target.time_to_die<10)&mantle_duration=0
  if Talent(subterfuge_talent) and HasEquippedItem(mantle_of_the_master_assassin) and { target.DebuffPresent(vendetta_debuff) or target.TimeToDie() < 10 } and BuffRemaining(master_assassins_initiative) == 0 and CheckBoxOn(opt_vanish) Spell(vanish)
  #vanish,if=talent.subterfuge.enabled&!equipped.mantle_of_the_master_assassin&!stealthed.rogue&dot.garrote.refreshable&((spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives)|(spell_targets.fan_of_knives>=4&combo_points.deficit>=4))
  if Talent(subterfuge_talent) and not HasEquippedItem(mantle_of_the_master_assassin) and not Stealthed() and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) Spell(vanish)
  #vanish,if=talent.shadow_focus.enabled&variable.energy_time_to_max_combined>=2&combo_points.deficit>=4
  if Talent(shadow_focus_talent) and energy_time_to_max_combined() >= 2 and ComboPointsDeficit() >= 4 and CheckBoxOn(opt_vanish) Spell(vanish)
 }
}

AddFunction AssassinationCdsShortCdPostConditions
{
 not ArmorSetBonus(T20 4) and { PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not Stealthed() or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and not { not SpellCooldown(vanish) > 0 } and BuffPresent(subterfuge_buff) } and Spell(exsanguinate) or ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) > 20 and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and Spell(exsanguinate) or ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and target.DebuffRemaining(rupture_debuff) > 8 and SpellCooldown(vendetta) > 10 and Spell(toxic_blade)
}

AddFunction AssassinationCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|debuff.vendetta.up&cooldown.vanish.remains<5
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or target.DebuffPresent(vendetta_debuff) and SpellCooldown(vanish) < 5 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 #use_item,name=tirathons_betrayal
 AssassinationUseItemActions()
 #blood_fury,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(blood_fury_ap)
 #berserking,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(berserking)
 #arcane_torrent,if=dot.kingsbane.ticking&!buff.envenom.up&energy.deficit>=15+variable.energy_regen_combined*gcd.remains*1.1
 if target.DebuffPresent(kingsbane_debuff) and not BuffPresent(envenom_buff) and EnergyDeficit() >= 15 + energy_regen_combined() * GCDRemaining() * 1 Spell(arcane_torrent_energy)

 unless { target.TimeToDie() < ComboPointsDeficit() * 1 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death)
 {
  #vendetta,if=!talent.exsanguinate.enabled|dot.rupture.ticking
  if not Talent(exsanguinate_talent) or target.DebuffPresent(rupture_debuff) Spell(vendetta)
 }
}

AddFunction AssassinationCdsCdPostConditions
{
 { target.TimeToDie() < ComboPointsDeficit() * 1 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or not ArmorSetBonus(T20 4) and { PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not Stealthed() or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and not { not SpellCooldown(vanish) > 0 } and BuffPresent(subterfuge_buff) } and Spell(exsanguinate) or ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) > 20 and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and Spell(exsanguinate) or Talent(nightstalker_talent) and ComboPoints() >= MaxComboPoints() and not Talent(exsanguinate_talent) and BuffRemaining(master_assassins_initiative) == 0 and { HasEquippedItem(mantle_of_the_master_assassin) and ArmorSetBonus(T19 4) or { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { target.DebuffRefreshable(rupture_debuff) or target.DebuffPresent(vendetta_debuff) } } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(nightstalker_talent) and ComboPoints() >= MaxComboPoints() and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and { target.DebuffPresent(rupture_debuff) or TimeInCombat() > 10 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and HasEquippedItem(mantle_of_the_master_assassin) and { target.DebuffPresent(vendetta_debuff) or target.TimeToDie() < 10 } and BuffRemaining(master_assassins_initiative) == 0 and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and not HasEquippedItem(mantle_of_the_master_assassin) and not Stealthed() and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(shadow_focus_talent) and energy_time_to_max_combined() >= 2 and ComboPointsDeficit() >= 4 and CheckBoxOn(opt_vanish) and Spell(vanish) or ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and target.DebuffRemaining(rupture_debuff) > 8 and SpellCooldown(vendetta) > 10 and Spell(toxic_blade)
}

### actions.build

AddFunction AssassinationBuildMainActions
{
 #hemorrhage,if=refreshable
 if target.Refreshable(hemorrhage_debuff) Spell(hemorrhage)
 #hemorrhage,cycle_targets=1,if=refreshable&dot.rupture.ticking&spell_targets.fan_of_knives<2+equipped.insignia_of_ravenholdt
 if target.Refreshable(hemorrhage_debuff) and target.DebuffPresent(rupture_debuff) and Enemies() < 2 + HasEquippedItem(insignia_of_ravenholdt) Spell(hemorrhage)
 #fan_of_knives,if=spell_targets>=2+equipped.insignia_of_ravenholdt|buff.the_dreadlords_deceit.stack>=29
 if Enemies() >= 2 + HasEquippedItem(insignia_of_ravenholdt) or BuffStacks(the_dreadlords_deceit_buff) >= 29 Spell(fan_of_knives)
 #mutilate,cycle_targets=1,if=dot.deadly_poison_dot.refreshable
 if target.DebuffRefreshable(deadly_poison_dot_debuff) Spell(mutilate)
 #mutilate
 Spell(mutilate)
}

AddFunction AssassinationBuildMainPostConditions
{
}

AddFunction AssassinationBuildShortCdActions
{
}

AddFunction AssassinationBuildShortCdPostConditions
{
 target.Refreshable(hemorrhage_debuff) and Spell(hemorrhage) or target.Refreshable(hemorrhage_debuff) and target.DebuffPresent(rupture_debuff) and Enemies() < 2 + HasEquippedItem(insignia_of_ravenholdt) and Spell(hemorrhage) or { Enemies() >= 2 + HasEquippedItem(insignia_of_ravenholdt) or BuffStacks(the_dreadlords_deceit_buff) >= 29 } and Spell(fan_of_knives) or target.DebuffRefreshable(deadly_poison_dot_debuff) and Spell(mutilate) or Spell(mutilate)
}

AddFunction AssassinationBuildCdActions
{
}

AddFunction AssassinationBuildCdPostConditions
{
 target.Refreshable(hemorrhage_debuff) and Spell(hemorrhage) or target.Refreshable(hemorrhage_debuff) and target.DebuffPresent(rupture_debuff) and Enemies() < 2 + HasEquippedItem(insignia_of_ravenholdt) and Spell(hemorrhage) or { Enemies() >= 2 + HasEquippedItem(insignia_of_ravenholdt) or BuffStacks(the_dreadlords_deceit_buff) >= 29 } and Spell(fan_of_knives) or target.DebuffRefreshable(deadly_poison_dot_debuff) and Spell(mutilate) or Spell(mutilate)
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*(7+talent.venom_rush.enabled*3)%2
 #variable,name=energy_time_to_max_combined,value=energy.deficit%variable.energy_regen_combined
 #call_action_list,name=cds
 AssassinationCdsMainActions()

 unless AssassinationCdsMainPostConditions()
 {
  #call_action_list,name=maintain
  AssassinationMaintainMainActions()

  unless AssassinationMaintainMainPostConditions()
  {
   #call_action_list,name=finish,if=(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)&(!dot.rupture.refreshable|(dot.rupture.exsanguinated&dot.rupture.remains>=3.5)|target.time_to_die-dot.rupture.remains<=6)&active_dot.rupture>=spell_targets.rupture
   if { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() AssassinationFinishMainActions()

   unless { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishMainPostConditions()
   {
    #call_action_list,name=build,if=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined
    if ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() AssassinationBuildMainActions()
   }
  }
 }
}

AddFunction AssassinationDefaultMainPostConditions
{
 AssassinationCdsMainPostConditions() or AssassinationMaintainMainPostConditions() or { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishMainPostConditions() or { ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() } and AssassinationBuildMainPostConditions()
}

AddFunction AssassinationDefaultShortCdActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*(7+talent.venom_rush.enabled*3)%2
 #variable,name=energy_time_to_max_combined,value=energy.deficit%variable.energy_regen_combined
 #call_action_list,name=cds
 AssassinationCdsShortCdActions()

 unless AssassinationCdsShortCdPostConditions()
 {
  #call_action_list,name=maintain
  AssassinationMaintainShortCdActions()

  unless AssassinationMaintainShortCdPostConditions()
  {
   #call_action_list,name=finish,if=(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)&(!dot.rupture.refreshable|(dot.rupture.exsanguinated&dot.rupture.remains>=3.5)|target.time_to_die-dot.rupture.remains<=6)&active_dot.rupture>=spell_targets.rupture
   if { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() AssassinationFinishShortCdActions()

   unless { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishShortCdPostConditions()
   {
    #call_action_list,name=build,if=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined
    if ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() AssassinationBuildShortCdActions()
   }
  }
 }
}

AddFunction AssassinationDefaultShortCdPostConditions
{
 AssassinationCdsShortCdPostConditions() or AssassinationMaintainShortCdPostConditions() or { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishShortCdPostConditions() or { ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() } and AssassinationBuildShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*(7+talent.venom_rush.enabled*3)%2
 #variable,name=energy_time_to_max_combined,value=energy.deficit%variable.energy_regen_combined
 #call_action_list,name=cds
 AssassinationCdsCdActions()

 unless AssassinationCdsCdPostConditions()
 {
  #call_action_list,name=maintain
  AssassinationMaintainCdActions()

  unless AssassinationMaintainCdPostConditions()
  {
   #call_action_list,name=finish,if=(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)&(!dot.rupture.refreshable|(dot.rupture.exsanguinated&dot.rupture.remains>=3.5)|target.time_to_die-dot.rupture.remains<=6)&active_dot.rupture>=spell_targets.rupture
   if { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() AssassinationFinishCdActions()

   unless { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishCdPostConditions()
   {
    #call_action_list,name=build,if=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined
    if ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() AssassinationBuildCdActions()
   }
  }
 }
}

AddFunction AssassinationDefaultCdPostConditions
{
 AssassinationCdsCdPostConditions() or AssassinationMaintainCdPostConditions() or { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishCdPostConditions() or { ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() } and AssassinationBuildCdPostConditions()
}

### Assassination icons.

AddCheckBox(opt_rogue_assassination_aoe L(AOE) default specialization=assassination)

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=shortcd specialization=assassination
{
 if not InCombat() AssassinationPrecombatShortCdActions()
 unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
 {
  AssassinationDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=shortcd specialization=assassination
{
 if not InCombat() AssassinationPrecombatShortCdActions()
 unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
 {
  AssassinationDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=assassination
{
 if not InCombat() AssassinationPrecombatMainActions()
 unless not InCombat() and AssassinationPrecombatMainPostConditions()
 {
  AssassinationDefaultMainActions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=aoe specialization=assassination
{
 if not InCombat() AssassinationPrecombatMainActions()
 unless not InCombat() and AssassinationPrecombatMainPostConditions()
 {
  AssassinationDefaultMainActions()
 }
}

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=cd specialization=assassination
{
 if not InCombat() AssassinationPrecombatCdActions()
 unless not InCombat() and AssassinationPrecombatCdPostConditions()
 {
  AssassinationDefaultCdActions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=cd specialization=assassination
{
 if not InCombat() AssassinationPrecombatCdActions()
 unless not InCombat() and AssassinationPrecombatCdPostConditions()
 {
  AssassinationDefaultCdActions()
 }
}

### Required symbols
# stealth
# prolonged_power_potion
# marked_for_death
# rupture
# nightstalker_talent
# mantle_of_the_master_assassin
# exsanguinate_talent
# rupture_debuff
# garrote
# subterfuge_talent
# garrote_debuff
# toxic_blade_debuff
# exsanguinated
# master_assassins_initiative
# exsanguinate
# urge_to_kill
# vanish
# vendetta
# kingsbane
# sinister_circulation
# duskwalkers_footpads
# convergence_of_fates
# master_assassin
# vendetta_debuff
# surge_of_toxins_debuff
# envenom_buff
# death_from_above
# envenom
# deeper_stratagem_talent
# elaborate_planning_talent
# elaborate_planning_buff
# blood_fury_ap
# berserking
# arcane_torrent_energy
# kingsbane_debuff
# subterfuge_buff
# shadow_focus_talent
# toxic_blade
# hemorrhage
# hemorrhage_debuff
# insignia_of_ravenholdt
# fan_of_knives
# the_dreadlords_deceit_buff
# mutilate
# deadly_poison_dot_debuff
# internal_bleeding_talent
# internal_bleeding_debuff
# venom_rush_talent
# kick
# shadowstep
]]
    OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
end
do
    local name = "sc_rogue_assassination_t19"
    local desc = "[7.0] Simulationcraft: Rogue_Assassination_T19"
    local code = [[
# Based on SimulationCraft profile "Rogue_Assassination_T19P".
#	class=rogue
#	spec=assassination
#	talents=1130111

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction energy_time_to_max_combined
{
 EnergyDeficit() / energy_regen_combined()
}

AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * { 7 + TalentPoints(venom_rush_talent) * 3 } / 2
}

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=assassination)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=assassination)
AddCheckBox(opt_vanish SpellName(vanish) default specialization=assassination)

AddFunction AssassinationUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction AssassinationGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
 {
  Spell(shadowstep)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.precombat

AddFunction AssassinationPrecombatMainActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #apply_poison
 #stealth
 Spell(stealth)
}

AddFunction AssassinationPrecombatMainPostConditions
{
}

AddFunction AssassinationPrecombatShortCdActions
{
 unless Spell(stealth)
 {
  #marked_for_death,if=raid_event.adds.in>40
  if 600 > 40 Spell(marked_for_death)
 }
}

AddFunction AssassinationPrecombatShortCdPostConditions
{
 Spell(stealth)
}

AddFunction AssassinationPrecombatCdActions
{
 unless Spell(stealth)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 }
}

AddFunction AssassinationPrecombatCdPostConditions
{
 Spell(stealth) or 600 > 40 and Spell(marked_for_death)
}

### actions.maintain

AddFunction AssassinationMaintainMainActions
{
 #rupture,if=talent.nightstalker.enabled&stealthed.rogue&(!equipped.mantle_of_the_master_assassin|!set_bonus.tier19_4pc)&(talent.exsanguinate.enabled|target.time_to_die-remains>4)
 if Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } Spell(rupture)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&stealthed.rogue&combo_points.deficit>=1&set_bonus.tier20_4pc&((dot.garrote.remains<=13&!debuff.toxic_blade.up)|pmultiplier<=1)&!exsanguinated
 if Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) Spell(garrote)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&stealthed.rogue&combo_points.deficit>=1&!set_bonus.tier20_4pc&refreshable&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&stealthed.rogue&combo_points.deficit>=1&!set_bonus.tier20_4pc&remains<=10&pmultiplier<=1&!exsanguinated&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #rupture,if=!talent.exsanguinate.enabled&combo_points>=3&!ticking&mantle_duration<=0.2&target.time_to_die>6
 if not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 Spell(rupture)
 #rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2+artifact.urge_to_kill.enabled)))
 if Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } Spell(rupture)
 #rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time)&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>6
 if ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 Spell(rupture)
 #call_action_list,name=kb,if=combo_points.deficit>=1+(mantle_duration>=0.2)&(!talent.exsanguinate.enabled|!cooldown.exanguinate.up|time>9)
 if ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } AssassinationKbMainActions()

 unless ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } and AssassinationKbMainPostConditions()
 {
  #pool_resource,for_next=1
  #garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time)&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>4
  if { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 Spell(garrote)
  unless { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
  {
   #garrote,if=set_bonus.tier20_4pc&talent.exsanguinate.enabled&prev_gcd.1.rupture&cooldown.exsanguinate.remains<1&(!cooldown.vanish.up|time>12)
   if ArmorSetBonus(T20 4) and Talent(exsanguinate_talent) and PreviousGCDSpell(rupture) and SpellCooldown(exsanguinate) < 1 and { not { not SpellCooldown(vanish) > 0 } or TimeInCombat() > 12 } Spell(garrote)
  }
 }
}

AddFunction AssassinationMaintainMainPostConditions
{
 ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } and AssassinationKbMainPostConditions()
}

AddFunction AssassinationMaintainShortCdActions
{
 unless Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } and Spell(rupture) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 and Spell(rupture) or Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } and Spell(rupture) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture)
 {
  #call_action_list,name=kb,if=combo_points.deficit>=1+(mantle_duration>=0.2)&(!talent.exsanguinate.enabled|!cooldown.exanguinate.up|time>9)
  if ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } AssassinationKbShortCdActions()
 }
}

AddFunction AssassinationMaintainShortCdPostConditions
{
 Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } and Spell(rupture) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 and Spell(rupture) or Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } and Spell(rupture) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } and AssassinationKbShortCdPostConditions() or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and ArmorSetBonus(T20 4) and Talent(exsanguinate_talent) and PreviousGCDSpell(rupture) and SpellCooldown(exsanguinate) < 1 and { not { not SpellCooldown(vanish) > 0 } or TimeInCombat() > 12 } and Spell(garrote)
}

AddFunction AssassinationMaintainCdActions
{
 unless Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } and Spell(rupture) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 and Spell(rupture) or Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } and Spell(rupture) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture)
 {
  #call_action_list,name=kb,if=combo_points.deficit>=1+(mantle_duration>=0.2)&(!talent.exsanguinate.enabled|!cooldown.exanguinate.up|time>9)
  if ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } AssassinationKbCdActions()
 }
}

AddFunction AssassinationMaintainCdPostConditions
{
 Talent(nightstalker_talent) and Stealthed() and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { Talent(exsanguinate_talent) or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 } and Spell(rupture) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and ArmorSetBonus(T20 4) and { target.DebuffRemaining(garrote_debuff) <= 13 and not target.DebuffPresent(toxic_blade_debuff) or PersistentMultiplier(garrote_debuff) <= 1 } and not target.DebuffPresent(exsanguinated) and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Stealthed() and ComboPointsDeficit() >= 1 and not ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not Talent(exsanguinate_talent) and ComboPoints() >= 3 and not target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassins_initiative) <= 0 and target.TimeToDie() > 6 and Spell(rupture) or Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 + HasArtifactTrait(urge_to_kill) } } and Spell(rupture) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and { not Talent(exsanguinate_talent) or not { not SpellCooldown(exsanguinate) > 0 } or TimeInCombat() > 9 } and AssassinationKbCdPostConditions() or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and ArmorSetBonus(T20 4) and Talent(exsanguinate_talent) and PreviousGCDSpell(rupture) and SpellCooldown(exsanguinate) < 1 and { not { not SpellCooldown(vanish) > 0 } or TimeInCombat() > 12 } and Spell(garrote)
}

### actions.kb

AddFunction AssassinationKbMainActions
{
 #kingsbane,if=artifact.sinister_circulation.enabled&!(equipped.duskwalkers_footpads&equipped.convergence_of_fates&artifact.master_assassin.rank>=6)&(time>25|!equipped.mantle_of_the_master_assassin|(debuff.vendetta.up&debuff.surge_of_toxins.up))&(talent.subterfuge.enabled|!stealthed.rogue|(talent.nightstalker.enabled&(!equipped.mantle_of_the_master_assassin|!set_bonus.tier19_4pc)))
 if HasArtifactTrait(sinister_circulation) and not { HasEquippedItem(duskwalkers_footpads) and HasEquippedItem(convergence_of_fates) and ArtifactTraitRank(master_assassin) >= 6 } and { TimeInCombat() > 25 or not HasEquippedItem(mantle_of_the_master_assassin) or target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) } and { Talent(subterfuge_talent) or not Stealthed() or Talent(nightstalker_talent) and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } } Spell(kingsbane)
 #kingsbane,if=buff.envenom.up&((debuff.vendetta.up&debuff.surge_of_toxins.up)|cooldown.vendetta.remains<=5.8|cooldown.vendetta.remains>=10)
 if BuffPresent(envenom_buff) and { target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) or SpellCooldown(vendetta) <= 5 or SpellCooldown(vendetta) >= 10 } Spell(kingsbane)
}

AddFunction AssassinationKbMainPostConditions
{
}

AddFunction AssassinationKbShortCdActions
{
}

AddFunction AssassinationKbShortCdPostConditions
{
 HasArtifactTrait(sinister_circulation) and not { HasEquippedItem(duskwalkers_footpads) and HasEquippedItem(convergence_of_fates) and ArtifactTraitRank(master_assassin) >= 6 } and { TimeInCombat() > 25 or not HasEquippedItem(mantle_of_the_master_assassin) or target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) } and { Talent(subterfuge_talent) or not Stealthed() or Talent(nightstalker_talent) and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } } and Spell(kingsbane) or BuffPresent(envenom_buff) and { target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) or SpellCooldown(vendetta) <= 5 or SpellCooldown(vendetta) >= 10 } and Spell(kingsbane)
}

AddFunction AssassinationKbCdActions
{
}

AddFunction AssassinationKbCdPostConditions
{
 HasArtifactTrait(sinister_circulation) and not { HasEquippedItem(duskwalkers_footpads) and HasEquippedItem(convergence_of_fates) and ArtifactTraitRank(master_assassin) >= 6 } and { TimeInCombat() > 25 or not HasEquippedItem(mantle_of_the_master_assassin) or target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) } and { Talent(subterfuge_talent) or not Stealthed() or Talent(nightstalker_talent) and { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } } and Spell(kingsbane) or BuffPresent(envenom_buff) and { target.DebuffPresent(vendetta_debuff) and target.DebuffPresent(surge_of_toxins_debuff) or SpellCooldown(vendetta) <= 5 or SpellCooldown(vendetta) >= 10 } and Spell(kingsbane)
}

### actions.finish

AddFunction AssassinationFinishMainActions
{
 #death_from_above,if=combo_points>=5
 if ComboPoints() >= 5 Spell(death_from_above)
 #envenom,if=combo_points>=4+(talent.deeper_stratagem.enabled&!set_bonus.tier19_4pc)&(debuff.vendetta.up|mantle_duration>=0.2|debuff.surge_of_toxins.remains<0.2|energy.deficit<=25+variable.energy_regen_combined)
 if ComboPoints() >= 4 + { Talent(deeper_stratagem_talent) and not ArmorSetBonus(T19 4) } and { target.DebuffPresent(vendetta_debuff) or BuffRemaining(master_assassins_initiative) >= 0 or target.DebuffRemaining(surge_of_toxins_debuff) < 0 or EnergyDeficit() <= 25 + energy_regen_combined() } Spell(envenom)
 #envenom,if=talent.elaborate_planning.enabled&combo_points>=3+!talent.exsanguinate.enabled&buff.elaborate_planning.remains<0.2
 if Talent(elaborate_planning_talent) and ComboPoints() >= 3 + Talent(exsanguinate_talent no) and BuffRemaining(elaborate_planning_buff) < 0 Spell(envenom)
}

AddFunction AssassinationFinishMainPostConditions
{
}

AddFunction AssassinationFinishShortCdActions
{
}

AddFunction AssassinationFinishShortCdPostConditions
{
 ComboPoints() >= 5 and Spell(death_from_above) or ComboPoints() >= 4 + { Talent(deeper_stratagem_talent) and not ArmorSetBonus(T19 4) } and { target.DebuffPresent(vendetta_debuff) or BuffRemaining(master_assassins_initiative) >= 0 or target.DebuffRemaining(surge_of_toxins_debuff) < 0 or EnergyDeficit() <= 25 + energy_regen_combined() } and Spell(envenom) or Talent(elaborate_planning_talent) and ComboPoints() >= 3 + Talent(exsanguinate_talent no) and BuffRemaining(elaborate_planning_buff) < 0 and Spell(envenom)
}

AddFunction AssassinationFinishCdActions
{
}

AddFunction AssassinationFinishCdPostConditions
{
 ComboPoints() >= 5 and Spell(death_from_above) or ComboPoints() >= 4 + { Talent(deeper_stratagem_talent) and not ArmorSetBonus(T19 4) } and { target.DebuffPresent(vendetta_debuff) or BuffRemaining(master_assassins_initiative) >= 0 or target.DebuffRemaining(surge_of_toxins_debuff) < 0 or EnergyDeficit() <= 25 + energy_regen_combined() } and Spell(envenom) or Talent(elaborate_planning_talent) and ComboPoints() >= 3 + Talent(exsanguinate_talent no) and BuffRemaining(elaborate_planning_buff) < 0 and Spell(envenom)
}

### actions.cds

AddFunction AssassinationCdsMainActions
{
 #exsanguinate,if=!set_bonus.tier20_4pc&(prev_gcd.1.rupture&dot.rupture.remains>4+4*cp_max_spend&!stealthed.rogue|dot.garrote.pmultiplier>1&!cooldown.vanish.up&buff.subterfuge.up)
 if not ArmorSetBonus(T20 4) and { PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not Stealthed() or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and not { not SpellCooldown(vanish) > 0 } and BuffPresent(subterfuge_buff) } Spell(exsanguinate)
 #exsanguinate,if=set_bonus.tier20_4pc&dot.garrote.remains>20&dot.rupture.remains>4+4*cp_max_spend
 if ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) > 20 and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() Spell(exsanguinate)
 #toxic_blade,if=combo_points.deficit>=1+(mantle_duration>=0.2)&dot.rupture.remains>8&cooldown.vendetta.remains>10
 if ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and target.DebuffRemaining(rupture_debuff) > 8 and SpellCooldown(vendetta) > 10 Spell(toxic_blade)
}

AddFunction AssassinationCdsMainPostConditions
{
}

AddFunction AssassinationCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit*1.5|(raid_event.adds.in>40&combo_points.deficit>=cp_max_spend)
 if target.TimeToDie() < ComboPointsDeficit() * 1 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)

 unless not ArmorSetBonus(T20 4) and { PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not Stealthed() or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and not { not SpellCooldown(vanish) > 0 } and BuffPresent(subterfuge_buff) } and Spell(exsanguinate) or ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) > 20 and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and Spell(exsanguinate)
 {
  #vanish,if=talent.nightstalker.enabled&combo_points>=cp_max_spend&!talent.exsanguinate.enabled&mantle_duration=0&((equipped.mantle_of_the_master_assassin&set_bonus.tier19_4pc)|((!equipped.mantle_of_the_master_assassin|!set_bonus.tier19_4pc)&(dot.rupture.refreshable|debuff.vendetta.up)))
  if Talent(nightstalker_talent) and ComboPoints() >= MaxComboPoints() and not Talent(exsanguinate_talent) and BuffRemaining(master_assassins_initiative) == 0 and { HasEquippedItem(mantle_of_the_master_assassin) and ArmorSetBonus(T19 4) or { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { target.DebuffRefreshable(rupture_debuff) or target.DebuffPresent(vendetta_debuff) } } and CheckBoxOn(opt_vanish) Spell(vanish)
  #vanish,if=talent.nightstalker.enabled&combo_points>=cp_max_spend&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&(dot.rupture.ticking|time>10)
  if Talent(nightstalker_talent) and ComboPoints() >= MaxComboPoints() and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and { target.DebuffPresent(rupture_debuff) or TimeInCombat() > 10 } and CheckBoxOn(opt_vanish) Spell(vanish)
  #vanish,if=talent.subterfuge.enabled&equipped.mantle_of_the_master_assassin&(debuff.vendetta.up|target.time_to_die<10)&mantle_duration=0
  if Talent(subterfuge_talent) and HasEquippedItem(mantle_of_the_master_assassin) and { target.DebuffPresent(vendetta_debuff) or target.TimeToDie() < 10 } and BuffRemaining(master_assassins_initiative) == 0 and CheckBoxOn(opt_vanish) Spell(vanish)
  #vanish,if=talent.subterfuge.enabled&!equipped.mantle_of_the_master_assassin&!stealthed.rogue&dot.garrote.refreshable&((spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives)|(spell_targets.fan_of_knives>=4&combo_points.deficit>=4))
  if Talent(subterfuge_talent) and not HasEquippedItem(mantle_of_the_master_assassin) and not Stealthed() and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) Spell(vanish)
  #vanish,if=talent.shadow_focus.enabled&variable.energy_time_to_max_combined>=2&combo_points.deficit>=4
  if Talent(shadow_focus_talent) and energy_time_to_max_combined() >= 2 and ComboPointsDeficit() >= 4 and CheckBoxOn(opt_vanish) Spell(vanish)
 }
}

AddFunction AssassinationCdsShortCdPostConditions
{
 not ArmorSetBonus(T20 4) and { PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not Stealthed() or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and not { not SpellCooldown(vanish) > 0 } and BuffPresent(subterfuge_buff) } and Spell(exsanguinate) or ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) > 20 and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and Spell(exsanguinate) or ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and target.DebuffRemaining(rupture_debuff) > 8 and SpellCooldown(vendetta) > 10 and Spell(toxic_blade)
}

AddFunction AssassinationCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|debuff.vendetta.up&cooldown.vanish.remains<5
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or target.DebuffPresent(vendetta_debuff) and SpellCooldown(vanish) < 5 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 #use_item,name=faulty_countermeasure
 AssassinationUseItemActions()
 #use_item,name=tirathons_betrayal
 AssassinationUseItemActions()
 #blood_fury,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(blood_fury_ap)
 #berserking,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(berserking)
 #arcane_torrent,if=dot.kingsbane.ticking&!buff.envenom.up&energy.deficit>=15+variable.energy_regen_combined*gcd.remains*1.1
 if target.DebuffPresent(kingsbane_debuff) and not BuffPresent(envenom_buff) and EnergyDeficit() >= 15 + energy_regen_combined() * GCDRemaining() * 1 Spell(arcane_torrent_energy)

 unless { target.TimeToDie() < ComboPointsDeficit() * 1 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death)
 {
  #vendetta,if=!talent.exsanguinate.enabled|dot.rupture.ticking
  if not Talent(exsanguinate_talent) or target.DebuffPresent(rupture_debuff) Spell(vendetta)
 }
}

AddFunction AssassinationCdsCdPostConditions
{
 { target.TimeToDie() < ComboPointsDeficit() * 1 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or not ArmorSetBonus(T20 4) and { PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not Stealthed() or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and not { not SpellCooldown(vanish) > 0 } and BuffPresent(subterfuge_buff) } and Spell(exsanguinate) or ArmorSetBonus(T20 4) and target.DebuffRemaining(garrote_debuff) > 20 and target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and Spell(exsanguinate) or Talent(nightstalker_talent) and ComboPoints() >= MaxComboPoints() and not Talent(exsanguinate_talent) and BuffRemaining(master_assassins_initiative) == 0 and { HasEquippedItem(mantle_of_the_master_assassin) and ArmorSetBonus(T19 4) or { not HasEquippedItem(mantle_of_the_master_assassin) or not ArmorSetBonus(T19 4) } and { target.DebuffRefreshable(rupture_debuff) or target.DebuffPresent(vendetta_debuff) } } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(nightstalker_talent) and ComboPoints() >= MaxComboPoints() and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and { target.DebuffPresent(rupture_debuff) or TimeInCombat() > 10 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and HasEquippedItem(mantle_of_the_master_assassin) and { target.DebuffPresent(vendetta_debuff) or target.TimeToDie() < 10 } and BuffRemaining(master_assassins_initiative) == 0 and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and not HasEquippedItem(mantle_of_the_master_assassin) and not Stealthed() and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(shadow_focus_talent) and energy_time_to_max_combined() >= 2 and ComboPointsDeficit() >= 4 and CheckBoxOn(opt_vanish) and Spell(vanish) or ComboPointsDeficit() >= 1 + { BuffRemaining(master_assassins_initiative) >= 0 } and target.DebuffRemaining(rupture_debuff) > 8 and SpellCooldown(vendetta) > 10 and Spell(toxic_blade)
}

### actions.build

AddFunction AssassinationBuildMainActions
{
 #hemorrhage,if=refreshable
 if target.Refreshable(hemorrhage_debuff) Spell(hemorrhage)
 #hemorrhage,cycle_targets=1,if=refreshable&dot.rupture.ticking&spell_targets.fan_of_knives<2+equipped.insignia_of_ravenholdt
 if target.Refreshable(hemorrhage_debuff) and target.DebuffPresent(rupture_debuff) and Enemies() < 2 + HasEquippedItem(insignia_of_ravenholdt) Spell(hemorrhage)
 #fan_of_knives,if=spell_targets>=2+equipped.insignia_of_ravenholdt|buff.the_dreadlords_deceit.stack>=29
 if Enemies() >= 2 + HasEquippedItem(insignia_of_ravenholdt) or BuffStacks(the_dreadlords_deceit_buff) >= 29 Spell(fan_of_knives)
 #mutilate,cycle_targets=1,if=dot.deadly_poison_dot.refreshable
 if target.DebuffRefreshable(deadly_poison_dot_debuff) Spell(mutilate)
 #mutilate
 Spell(mutilate)
}

AddFunction AssassinationBuildMainPostConditions
{
}

AddFunction AssassinationBuildShortCdActions
{
}

AddFunction AssassinationBuildShortCdPostConditions
{
 target.Refreshable(hemorrhage_debuff) and Spell(hemorrhage) or target.Refreshable(hemorrhage_debuff) and target.DebuffPresent(rupture_debuff) and Enemies() < 2 + HasEquippedItem(insignia_of_ravenholdt) and Spell(hemorrhage) or { Enemies() >= 2 + HasEquippedItem(insignia_of_ravenholdt) or BuffStacks(the_dreadlords_deceit_buff) >= 29 } and Spell(fan_of_knives) or target.DebuffRefreshable(deadly_poison_dot_debuff) and Spell(mutilate) or Spell(mutilate)
}

AddFunction AssassinationBuildCdActions
{
}

AddFunction AssassinationBuildCdPostConditions
{
 target.Refreshable(hemorrhage_debuff) and Spell(hemorrhage) or target.Refreshable(hemorrhage_debuff) and target.DebuffPresent(rupture_debuff) and Enemies() < 2 + HasEquippedItem(insignia_of_ravenholdt) and Spell(hemorrhage) or { Enemies() >= 2 + HasEquippedItem(insignia_of_ravenholdt) or BuffStacks(the_dreadlords_deceit_buff) >= 29 } and Spell(fan_of_knives) or target.DebuffRefreshable(deadly_poison_dot_debuff) and Spell(mutilate) or Spell(mutilate)
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*(7+talent.venom_rush.enabled*3)%2
 #variable,name=energy_time_to_max_combined,value=energy.deficit%variable.energy_regen_combined
 #call_action_list,name=cds
 AssassinationCdsMainActions()

 unless AssassinationCdsMainPostConditions()
 {
  #call_action_list,name=maintain
  AssassinationMaintainMainActions()

  unless AssassinationMaintainMainPostConditions()
  {
   #call_action_list,name=finish,if=(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)&(!dot.rupture.refreshable|(dot.rupture.exsanguinated&dot.rupture.remains>=3.5)|target.time_to_die-dot.rupture.remains<=6)&active_dot.rupture>=spell_targets.rupture
   if { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() AssassinationFinishMainActions()

   unless { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishMainPostConditions()
   {
    #call_action_list,name=build,if=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined
    if ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() AssassinationBuildMainActions()
   }
  }
 }
}

AddFunction AssassinationDefaultMainPostConditions
{
 AssassinationCdsMainPostConditions() or AssassinationMaintainMainPostConditions() or { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishMainPostConditions() or { ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() } and AssassinationBuildMainPostConditions()
}

AddFunction AssassinationDefaultShortCdActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*(7+talent.venom_rush.enabled*3)%2
 #variable,name=energy_time_to_max_combined,value=energy.deficit%variable.energy_regen_combined
 #call_action_list,name=cds
 AssassinationCdsShortCdActions()

 unless AssassinationCdsShortCdPostConditions()
 {
  #call_action_list,name=maintain
  AssassinationMaintainShortCdActions()

  unless AssassinationMaintainShortCdPostConditions()
  {
   #call_action_list,name=finish,if=(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)&(!dot.rupture.refreshable|(dot.rupture.exsanguinated&dot.rupture.remains>=3.5)|target.time_to_die-dot.rupture.remains<=6)&active_dot.rupture>=spell_targets.rupture
   if { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() AssassinationFinishShortCdActions()

   unless { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishShortCdPostConditions()
   {
    #call_action_list,name=build,if=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined
    if ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() AssassinationBuildShortCdActions()
   }
  }
 }
}

AddFunction AssassinationDefaultShortCdPostConditions
{
 AssassinationCdsShortCdPostConditions() or AssassinationMaintainShortCdPostConditions() or { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishShortCdPostConditions() or { ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() } and AssassinationBuildShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*(7+talent.venom_rush.enabled*3)%2
 #variable,name=energy_time_to_max_combined,value=energy.deficit%variable.energy_regen_combined
 #call_action_list,name=cds
 AssassinationCdsCdActions()

 unless AssassinationCdsCdPostConditions()
 {
  #call_action_list,name=maintain
  AssassinationMaintainCdActions()

  unless AssassinationMaintainCdPostConditions()
  {
   #call_action_list,name=finish,if=(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)&(!dot.rupture.refreshable|(dot.rupture.exsanguinated&dot.rupture.remains>=3.5)|target.time_to_die-dot.rupture.remains<=6)&active_dot.rupture>=spell_targets.rupture
   if { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() AssassinationFinishCdActions()

   unless { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishCdPostConditions()
   {
    #call_action_list,name=build,if=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined
    if ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() AssassinationBuildCdActions()
   }
  }
 }
}

AddFunction AssassinationDefaultCdPostConditions
{
 AssassinationCdsCdPostConditions() or AssassinationMaintainCdPostConditions() or { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and { not target.DebuffRefreshable(rupture_debuff) or target.DebuffRemaining(rupture_debuff_exsanguinated) and target.DebuffRemaining(rupture_debuff) >= 3 or target.TimeToDie() - target.DebuffRemaining(rupture_debuff) <= 6 } and DebuffCountOnAny(rupture_debuff) >= Enemies() and AssassinationFinishCdPostConditions() or { ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() } and AssassinationBuildCdPostConditions()
}

### Assassination icons.

AddCheckBox(opt_rogue_assassination_aoe L(AOE) default specialization=assassination)

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=shortcd specialization=assassination
{
 if not InCombat() AssassinationPrecombatShortCdActions()
 unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
 {
  AssassinationDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=shortcd specialization=assassination
{
 if not InCombat() AssassinationPrecombatShortCdActions()
 unless not InCombat() and AssassinationPrecombatShortCdPostConditions()
 {
  AssassinationDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=assassination
{
 if not InCombat() AssassinationPrecombatMainActions()
 unless not InCombat() and AssassinationPrecombatMainPostConditions()
 {
  AssassinationDefaultMainActions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=aoe specialization=assassination
{
 if not InCombat() AssassinationPrecombatMainActions()
 unless not InCombat() and AssassinationPrecombatMainPostConditions()
 {
  AssassinationDefaultMainActions()
 }
}

AddIcon checkbox=!opt_rogue_assassination_aoe enemies=1 help=cd specialization=assassination
{
 if not InCombat() AssassinationPrecombatCdActions()
 unless not InCombat() and AssassinationPrecombatCdPostConditions()
 {
  AssassinationDefaultCdActions()
 }
}

AddIcon checkbox=opt_rogue_assassination_aoe help=cd specialization=assassination
{
 if not InCombat() AssassinationPrecombatCdActions()
 unless not InCombat() and AssassinationPrecombatCdPostConditions()
 {
  AssassinationDefaultCdActions()
 }
}

### Required symbols
# stealth
# prolonged_power_potion
# marked_for_death
# rupture
# nightstalker_talent
# mantle_of_the_master_assassin
# exsanguinate_talent
# rupture_debuff
# garrote
# subterfuge_talent
# garrote_debuff
# toxic_blade_debuff
# exsanguinated
# master_assassins_initiative
# exsanguinate
# urge_to_kill
# vanish
# vendetta
# kingsbane
# sinister_circulation
# duskwalkers_footpads
# convergence_of_fates
# master_assassin
# vendetta_debuff
# surge_of_toxins_debuff
# envenom_buff
# death_from_above
# envenom
# deeper_stratagem_talent
# elaborate_planning_talent
# elaborate_planning_buff
# blood_fury_ap
# berserking
# arcane_torrent_energy
# kingsbane_debuff
# subterfuge_buff
# shadow_focus_talent
# toxic_blade
# hemorrhage
# hemorrhage_debuff
# insignia_of_ravenholdt
# fan_of_knives
# the_dreadlords_deceit_buff
# mutilate
# deadly_poison_dot_debuff
# internal_bleeding_talent
# internal_bleeding_debuff
# venom_rush_talent
# kick
# shadowstep
]]
    OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
end
do
    local name = "sc_rogue_outlaw_t19"
    local desc = "[7.0] Simulationcraft: Rogue_Outlaw_T19"
    local code = [[
# Based on SimulationCraft profile "Rogue_Outlaw_T19P".
#	class=rogue
#	spec=outlaw
#	talents=1310022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction ss_useable
{
 Talent(anticipation_talent) and ComboPoints() < 5 or not Talent(anticipation_talent) and { rtb_reroll() and ComboPoints() < 4 + TalentPoints(deeper_stratagem_talent) or not rtb_reroll() and ss_useable_noreroll() }
}

AddFunction ss_useable_noreroll
{
 ComboPoints() < 5 + TalentPoints(deeper_stratagem_talent) - { BuffPresent(broadsides_buff) or BuffPresent(jolly_roger_buff) } - { Talent(alacrity_talent) and BuffStacks(alacrity_buff) <= 4 }
}

AddFunction rtb_reroll
{
 not Talent(slice_and_dice_talent) and BuffPresent(loaded_dice_buff) and { BuffCount(roll_the_bones_buff) < 2 or BuffCount(roll_the_bones_buff) == 2 and not BuffPresent(true_bearing_buff) }
}

AddFunction ambush_condition
{
 ComboPointsDeficit() >= 2 + 2 * { Talent(ghostly_strike_talent) and not target.DebuffPresent(ghostly_strike_debuff) } + BuffPresent(broadsides_buff) and Energy() > 60 and not BuffPresent(jolly_roger_buff) and not BuffPresent(hidden_blade_buff)
}

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=outlaw)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=outlaw)
AddCheckBox(opt_blade_flurry SpellName(blade_flurry) default specialization=outlaw)

AddFunction OutlawUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction OutlawGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
 {
  Spell(shadowstep)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.stealth

AddFunction OutlawStealthMainActions
{
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&!debuff.ghostly_strike.up)+buff.broadsides.up&energy>60&!buff.jolly_roger.up&!buff.hidden_blade.up
 #ambush,if=variable.ambush_condition
 if ambush_condition() Spell(ambush)
}

AddFunction OutlawStealthMainPostConditions
{
}

AddFunction OutlawStealthShortCdActions
{
 unless ambush_condition() and Spell(ambush)
 {
  #vanish,if=(variable.ambush_condition|equipped.mantle_of_the_master_assassin&!variable.rtb_reroll&!variable.ss_useable)&mantle_duration=0
  if { ambush_condition() or HasEquippedItem(mantle_of_the_master_assassin) and not rtb_reroll() and not ss_useable() } and BuffRemaining(master_assassins_initiative) == 0 Spell(vanish)
 }
}

AddFunction OutlawStealthShortCdPostConditions
{
 ambush_condition() and Spell(ambush)
}

AddFunction OutlawStealthCdActions
{
 unless ambush_condition() and Spell(ambush) or { ambush_condition() or HasEquippedItem(mantle_of_the_master_assassin) and not rtb_reroll() and not ss_useable() } and BuffRemaining(master_assassins_initiative) == 0 and Spell(vanish)
 {
  #shadowmeld,if=variable.ambush_condition
  if ambush_condition() Spell(shadowmeld)
 }
}

AddFunction OutlawStealthCdPostConditions
{
 ambush_condition() and Spell(ambush) or { ambush_condition() or HasEquippedItem(mantle_of_the_master_assassin) and not rtb_reroll() and not ss_useable() } and BuffRemaining(master_assassins_initiative) == 0 and Spell(vanish)
}

### actions.precombat

AddFunction OutlawPrecombatMainActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #stealth
 Spell(stealth)
 #roll_the_bones,if=!talent.slice_and_dice.enabled
 if not Talent(slice_and_dice_talent) Spell(roll_the_bones)
}

AddFunction OutlawPrecombatMainPostConditions
{
}

AddFunction OutlawPrecombatShortCdActions
{
 unless Spell(stealth)
 {
  #marked_for_death,if=raid_event.adds.in>40
  if 600 > 40 Spell(marked_for_death)
 }
}

AddFunction OutlawPrecombatShortCdPostConditions
{
 Spell(stealth) or not Talent(slice_and_dice_talent) and Spell(roll_the_bones)
}

AddFunction OutlawPrecombatCdActions
{
 unless Spell(stealth)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)

  unless 600 > 40 and Spell(marked_for_death) or not Talent(slice_and_dice_talent) and Spell(roll_the_bones)
  {
   #curse_of_the_dreadblades,if=combo_points.deficit>=4
   if ComboPointsDeficit() >= 4 Spell(curse_of_the_dreadblades)
  }
 }
}

AddFunction OutlawPrecombatCdPostConditions
{
 Spell(stealth) or 600 > 40 and Spell(marked_for_death) or not Talent(slice_and_dice_talent) and Spell(roll_the_bones)
}

### actions.finish

AddFunction OutlawFinishMainActions
{
 #between_the_eyes,if=(mantle_duration>=0.2&!equipped.thraxis_tricksy_treads)|(equipped.greenskins_waterlogged_wristcuffs&!buff.greenskins_waterlogged_wristcuffs.up)
 if BuffRemaining(master_assassins_initiative) >= 0 and not HasEquippedItem(thraxis_tricksy_treads) or HasEquippedItem(greenskins_waterlogged_wristcuffs) and not BuffPresent(greenskins_waterlogged_wristcuffs_buff) Spell(between_the_eyes text=BTE)
 #run_through,if=!talent.death_from_above.enabled|energy.time_to_max<cooldown.death_from_above.remains+3.5
 if not Talent(death_from_above_talent) or TimeToMaxEnergy() < SpellCooldown(death_from_above) + 3 Spell(run_through)
}

AddFunction OutlawFinishMainPostConditions
{
}

AddFunction OutlawFinishShortCdActions
{
}

AddFunction OutlawFinishShortCdPostConditions
{
 { BuffRemaining(master_assassins_initiative) >= 0 and not HasEquippedItem(thraxis_tricksy_treads) or HasEquippedItem(greenskins_waterlogged_wristcuffs) and not BuffPresent(greenskins_waterlogged_wristcuffs_buff) } and Spell(between_the_eyes text=BTE) or { not Talent(death_from_above_talent) or TimeToMaxEnergy() < SpellCooldown(death_from_above) + 3 } and Spell(run_through)
}

AddFunction OutlawFinishCdActions
{
}

AddFunction OutlawFinishCdPostConditions
{
 { BuffRemaining(master_assassins_initiative) >= 0 and not HasEquippedItem(thraxis_tricksy_treads) or HasEquippedItem(greenskins_waterlogged_wristcuffs) and not BuffPresent(greenskins_waterlogged_wristcuffs_buff) } and Spell(between_the_eyes text=BTE) or { not Talent(death_from_above_talent) or TimeToMaxEnergy() < SpellCooldown(death_from_above) + 3 } and Spell(run_through)
}

### actions.cds

AddFunction OutlawCdsMainActions
{
}

AddFunction OutlawCdsMainPostConditions
{
}

AddFunction OutlawCdsShortCdActions
{
 #cannonball_barrage,if=spell_targets.cannonball_barrage>=1
 if Enemies() >= 1 Spell(cannonball_barrage)
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit|((raid_event.adds.in>40|buff.true_bearing.remains>15-buff.adrenaline_rush.up*5)&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
 if target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 Spell(marked_for_death)
 #sprint,if=equipped.thraxis_tricksy_treads&!variable.ss_useable
 if HasEquippedItem(thraxis_tricksy_treads) and not ss_useable() Spell(sprint)
}

AddFunction OutlawCdsShortCdPostConditions
{
}

AddFunction OutlawCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|buff.adrenaline_rush.up
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or BuffPresent(adrenaline_rush_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 #use_item,name=tirathons_betrayal,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
 if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 20 or ComboPointsDeficit() <= 2 OutlawUseItemActions()
 #blood_fury
 Spell(blood_fury_ap)
 #berserking
 Spell(berserking)
 #arcane_torrent,if=energy.deficit>40
 if EnergyDeficit() > 40 Spell(arcane_torrent_energy)

 unless Enemies() >= 1 and Spell(cannonball_barrage)
 {
  #adrenaline_rush,if=!buff.adrenaline_rush.up&energy.deficit>0
  if not BuffPresent(adrenaline_rush_buff) and EnergyDeficit() > 0 and EnergyDeficit() > 1 Spell(adrenaline_rush)

  unless { target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or HasEquippedItem(thraxis_tricksy_treads) and not ss_useable() and Spell(sprint)
  {
   #darkflight,if=equipped.thraxis_tricksy_treads&!variable.ss_useable&buff.sprint.down
   if HasEquippedItem(thraxis_tricksy_treads) and not ss_useable() and BuffExpires(sprint_buff) Spell(darkflight)
   #curse_of_the_dreadblades,if=combo_points.deficit>=4&(!talent.ghostly_strike.enabled|debuff.ghostly_strike.up)
   if ComboPointsDeficit() >= 4 and { not Talent(ghostly_strike_talent) or target.DebuffPresent(ghostly_strike_debuff) } Spell(curse_of_the_dreadblades)
  }
 }
}

AddFunction OutlawCdsCdPostConditions
{
 Enemies() >= 1 and Spell(cannonball_barrage) or { target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or HasEquippedItem(thraxis_tricksy_treads) and not ss_useable() and Spell(sprint)
}

### actions.build

AddFunction OutlawBuildMainActions
{
 #ghostly_strike,if=combo_points.deficit>=1+buff.broadsides.up&!buff.curse_of_the_dreadblades.up&(debuff.ghostly_strike.remains<debuff.ghostly_strike.duration*0.3|(cooldown.curse_of_the_dreadblades.remains<3&debuff.ghostly_strike.remains<14))&(combo_points>=3|(variable.rtb_reroll&time>=10))
 if ComboPointsDeficit() >= 1 + BuffPresent(broadsides_buff) and not BuffPresent(curse_of_the_dreadblades_buff) and { target.DebuffRemaining(ghostly_strike_debuff) < BaseDuration(ghostly_strike_debuff) * 0 or SpellCooldown(curse_of_the_dreadblades) < 3 and target.DebuffRemaining(ghostly_strike_debuff) < 14 } and { ComboPoints() >= 3 or rtb_reroll() and TimeInCombat() >= 10 } Spell(ghostly_strike)
 #pistol_shot,if=combo_points.deficit>=1+buff.broadsides.up&buff.opportunity.up&(energy.time_to_max>2-talent.quick_draw.enabled|(buff.blunderbuss.up&buff.greenskins_waterlogged_wristcuffs.up))
 if ComboPointsDeficit() >= 1 + BuffPresent(broadsides_buff) and BuffPresent(opportunity_buff) and { TimeToMaxEnergy() > 2 - TalentPoints(quick_draw_talent) or BuffPresent(blunderbuss_buff) and BuffPresent(greenskins_waterlogged_wristcuffs_buff) } Spell(pistol_shot text=PS)
 #saber_slash,if=variable.ss_useable
 if ss_useable() Spell(saber_slash)
}

AddFunction OutlawBuildMainPostConditions
{
}

AddFunction OutlawBuildShortCdActions
{
}

AddFunction OutlawBuildShortCdPostConditions
{
 ComboPointsDeficit() >= 1 + BuffPresent(broadsides_buff) and not BuffPresent(curse_of_the_dreadblades_buff) and { target.DebuffRemaining(ghostly_strike_debuff) < BaseDuration(ghostly_strike_debuff) * 0 or SpellCooldown(curse_of_the_dreadblades) < 3 and target.DebuffRemaining(ghostly_strike_debuff) < 14 } and { ComboPoints() >= 3 or rtb_reroll() and TimeInCombat() >= 10 } and Spell(ghostly_strike) or ComboPointsDeficit() >= 1 + BuffPresent(broadsides_buff) and BuffPresent(opportunity_buff) and { TimeToMaxEnergy() > 2 - TalentPoints(quick_draw_talent) or BuffPresent(blunderbuss_buff) and BuffPresent(greenskins_waterlogged_wristcuffs_buff) } and Spell(pistol_shot text=PS) or ss_useable() and Spell(saber_slash)
}

AddFunction OutlawBuildCdActions
{
}

AddFunction OutlawBuildCdPostConditions
{
 ComboPointsDeficit() >= 1 + BuffPresent(broadsides_buff) and not BuffPresent(curse_of_the_dreadblades_buff) and { target.DebuffRemaining(ghostly_strike_debuff) < BaseDuration(ghostly_strike_debuff) * 0 or SpellCooldown(curse_of_the_dreadblades) < 3 and target.DebuffRemaining(ghostly_strike_debuff) < 14 } and { ComboPoints() >= 3 or rtb_reroll() and TimeInCombat() >= 10 } and Spell(ghostly_strike) or ComboPointsDeficit() >= 1 + BuffPresent(broadsides_buff) and BuffPresent(opportunity_buff) and { TimeToMaxEnergy() > 2 - TalentPoints(quick_draw_talent) or BuffPresent(blunderbuss_buff) and BuffPresent(greenskins_waterlogged_wristcuffs_buff) } and Spell(pistol_shot text=PS) or ss_useable() and Spell(saber_slash)
}

### actions.bf

AddFunction OutlawBfMainActions
{
 #cancel_buff,name=blade_flurry,if=spell_targets.blade_flurry<2&buff.blade_flurry.up
 if Enemies() < 2 and BuffPresent(blade_flurry_buff) and BuffPresent(blade_flurry_buff) Texture(blade_flurry text=cancel)
 #cancel_buff,name=blade_flurry,if=equipped.shivarran_symmetry&cooldown.blade_flurry.up&buff.blade_flurry.up&spell_targets.blade_flurry>=2
 if HasEquippedItem(shivarran_symmetry) and not SpellCooldown(blade_flurry) > 0 and BuffPresent(blade_flurry_buff) and Enemies() >= 2 and BuffPresent(blade_flurry_buff) Texture(blade_flurry text=cancel)
 #blade_flurry,if=spell_targets.blade_flurry>=2&!buff.blade_flurry.up
 if Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and CheckBoxOn(opt_blade_flurry) Spell(blade_flurry)
}

AddFunction OutlawBfMainPostConditions
{
}

AddFunction OutlawBfShortCdActions
{
}

AddFunction OutlawBfShortCdPostConditions
{
 Enemies() < 2 and BuffPresent(blade_flurry_buff) and BuffPresent(blade_flurry_buff) and Texture(blade_flurry text=cancel) or HasEquippedItem(shivarran_symmetry) and not SpellCooldown(blade_flurry) > 0 and BuffPresent(blade_flurry_buff) and Enemies() >= 2 and BuffPresent(blade_flurry_buff) and Texture(blade_flurry text=cancel) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
}

AddFunction OutlawBfCdActions
{
}

AddFunction OutlawBfCdPostConditions
{
 Enemies() < 2 and BuffPresent(blade_flurry_buff) and BuffPresent(blade_flurry_buff) and Texture(blade_flurry text=cancel) or HasEquippedItem(shivarran_symmetry) and not SpellCooldown(blade_flurry) > 0 and BuffPresent(blade_flurry_buff) and Enemies() >= 2 and BuffPresent(blade_flurry_buff) and Texture(blade_flurry text=cancel) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
}

### actions.default

AddFunction OutlawDefaultMainActions
{
 #variable,name=rtb_reroll,value=!talent.slice_and_dice.enabled&buff.loaded_dice.up&(rtb_buffs<2|rtb_buffs=2&!buff.true_bearing.up)
 #variable,name=ss_useable_noreroll,value=(combo_points<5+talent.deeper_stratagem.enabled-(buff.broadsides.up|buff.jolly_roger.up)-(talent.alacrity.enabled&buff.alacrity.stack<=4))
 #variable,name=ss_useable,value=(talent.anticipation.enabled&combo_points<5)|(!talent.anticipation.enabled&((variable.rtb_reroll&combo_points<4+talent.deeper_stratagem.enabled)|(!variable.rtb_reroll&variable.ss_useable_noreroll)))
 #call_action_list,name=bf
 OutlawBfMainActions()

 unless OutlawBfMainPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsMainActions()

  unless OutlawCdsMainPostConditions()
  {
   #call_action_list,name=stealth,if=stealthed.rogue|cooldown.vanish.up|cooldown.shadowmeld.up
   if Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 OutlawStealthMainActions()

   unless { Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 } and OutlawStealthMainPostConditions()
   {
    #death_from_above,if=energy.time_to_max>2&!variable.ss_useable_noreroll
    if TimeToMaxEnergy() > 2 and not ss_useable_noreroll() Spell(death_from_above)
    #slice_and_dice,if=!variable.ss_useable&buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8&!buff.slice_and_dice.improved&!buff.loaded_dice.up
    if not ss_useable() and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1 and not BuffImproved(slice_and_dice_buffundefined) and not BuffPresent(loaded_dice_buff) Spell(slice_and_dice)
    #slice_and_dice,if=buff.loaded_dice.up&combo_points>=cp_max_spend&(!buff.slice_and_dice.improved|buff.slice_and_dice.remains<4)
    if BuffPresent(loaded_dice_buff) and ComboPoints() >= MaxComboPoints() and { not BuffImproved(slice_and_dice_buffundefined) or BuffRemaining(slice_and_dice_buff) < 4 } Spell(slice_and_dice)
    #slice_and_dice,if=buff.slice_and_dice.improved&buff.slice_and_dice.remains<=2&combo_points>=2&!buff.loaded_dice.up
    if BuffImproved(slice_and_dice_buffundefined) and BuffRemaining(slice_and_dice_buff) <= 2 and ComboPoints() >= 2 and not BuffPresent(loaded_dice_buff) Spell(slice_and_dice)
    #roll_the_bones,if=!variable.ss_useable&(target.time_to_die>20|buff.roll_the_bones.remains<target.time_to_die)&(buff.roll_the_bones.remains<=3|variable.rtb_reroll)
    if not ss_useable() and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } Spell(roll_the_bones)
    #call_action_list,name=build
    OutlawBuildMainActions()

    unless OutlawBuildMainPostConditions()
    {
     #call_action_list,name=finish,if=!variable.ss_useable
     if not ss_useable() OutlawFinishMainActions()

     unless not ss_useable() and OutlawFinishMainPostConditions()
     {
      #gouge,if=talent.dirty_tricks.enabled&combo_points.deficit>=1
      if Talent(dirty_tricks_talent) and ComboPointsDeficit() >= 1 Spell(gouge)
     }
    }
   }
  }
 }
}

AddFunction OutlawDefaultMainPostConditions
{
 OutlawBfMainPostConditions() or OutlawCdsMainPostConditions() or { Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 } and OutlawStealthMainPostConditions() or OutlawBuildMainPostConditions() or not ss_useable() and OutlawFinishMainPostConditions()
}

AddFunction OutlawDefaultShortCdActions
{
 #variable,name=rtb_reroll,value=!talent.slice_and_dice.enabled&buff.loaded_dice.up&(rtb_buffs<2|rtb_buffs=2&!buff.true_bearing.up)
 #variable,name=ss_useable_noreroll,value=(combo_points<5+talent.deeper_stratagem.enabled-(buff.broadsides.up|buff.jolly_roger.up)-(talent.alacrity.enabled&buff.alacrity.stack<=4))
 #variable,name=ss_useable,value=(talent.anticipation.enabled&combo_points<5)|(!talent.anticipation.enabled&((variable.rtb_reroll&combo_points<4+talent.deeper_stratagem.enabled)|(!variable.rtb_reroll&variable.ss_useable_noreroll)))
 #call_action_list,name=bf
 OutlawBfShortCdActions()

 unless OutlawBfShortCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsShortCdActions()

  unless OutlawCdsShortCdPostConditions()
  {
   #call_action_list,name=stealth,if=stealthed.rogue|cooldown.vanish.up|cooldown.shadowmeld.up
   if Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 OutlawStealthShortCdActions()

   unless { Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 } and OutlawStealthShortCdPostConditions() or TimeToMaxEnergy() > 2 and not ss_useable_noreroll() and Spell(death_from_above) or not ss_useable() and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1 and not BuffImproved(slice_and_dice_buffundefined) and not BuffPresent(loaded_dice_buff) and Spell(slice_and_dice) or BuffPresent(loaded_dice_buff) and ComboPoints() >= MaxComboPoints() and { not BuffImproved(slice_and_dice_buffundefined) or BuffRemaining(slice_and_dice_buff) < 4 } and Spell(slice_and_dice) or BuffImproved(slice_and_dice_buffundefined) and BuffRemaining(slice_and_dice_buff) <= 2 and ComboPoints() >= 2 and not BuffPresent(loaded_dice_buff) and Spell(slice_and_dice) or not ss_useable() and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones)
   {
    #call_action_list,name=build
    OutlawBuildShortCdActions()

    unless OutlawBuildShortCdPostConditions()
    {
     #call_action_list,name=finish,if=!variable.ss_useable
     if not ss_useable() OutlawFinishShortCdActions()
    }
   }
  }
 }
}

AddFunction OutlawDefaultShortCdPostConditions
{
 OutlawBfShortCdPostConditions() or OutlawCdsShortCdPostConditions() or { Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 } and OutlawStealthShortCdPostConditions() or TimeToMaxEnergy() > 2 and not ss_useable_noreroll() and Spell(death_from_above) or not ss_useable() and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1 and not BuffImproved(slice_and_dice_buffundefined) and not BuffPresent(loaded_dice_buff) and Spell(slice_and_dice) or BuffPresent(loaded_dice_buff) and ComboPoints() >= MaxComboPoints() and { not BuffImproved(slice_and_dice_buffundefined) or BuffRemaining(slice_and_dice_buff) < 4 } and Spell(slice_and_dice) or BuffImproved(slice_and_dice_buffundefined) and BuffRemaining(slice_and_dice_buff) <= 2 and ComboPoints() >= 2 and not BuffPresent(loaded_dice_buff) and Spell(slice_and_dice) or not ss_useable() and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or OutlawBuildShortCdPostConditions() or not ss_useable() and OutlawFinishShortCdPostConditions() or Talent(dirty_tricks_talent) and ComboPointsDeficit() >= 1 and Spell(gouge)
}

AddFunction OutlawDefaultCdActions
{
 #variable,name=rtb_reroll,value=!talent.slice_and_dice.enabled&buff.loaded_dice.up&(rtb_buffs<2|rtb_buffs=2&!buff.true_bearing.up)
 #variable,name=ss_useable_noreroll,value=(combo_points<5+talent.deeper_stratagem.enabled-(buff.broadsides.up|buff.jolly_roger.up)-(talent.alacrity.enabled&buff.alacrity.stack<=4))
 #variable,name=ss_useable,value=(talent.anticipation.enabled&combo_points<5)|(!talent.anticipation.enabled&((variable.rtb_reroll&combo_points<4+talent.deeper_stratagem.enabled)|(!variable.rtb_reroll&variable.ss_useable_noreroll)))
 #call_action_list,name=bf
 OutlawBfCdActions()

 unless OutlawBfCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsCdActions()

  unless OutlawCdsCdPostConditions()
  {
   #call_action_list,name=stealth,if=stealthed.rogue|cooldown.vanish.up|cooldown.shadowmeld.up
   if Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 OutlawStealthCdActions()

   unless { Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 } and OutlawStealthCdPostConditions() or TimeToMaxEnergy() > 2 and not ss_useable_noreroll() and Spell(death_from_above) or not ss_useable() and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1 and not BuffImproved(slice_and_dice_buffundefined) and not BuffPresent(loaded_dice_buff) and Spell(slice_and_dice) or BuffPresent(loaded_dice_buff) and ComboPoints() >= MaxComboPoints() and { not BuffImproved(slice_and_dice_buffundefined) or BuffRemaining(slice_and_dice_buff) < 4 } and Spell(slice_and_dice) or BuffImproved(slice_and_dice_buffundefined) and BuffRemaining(slice_and_dice_buff) <= 2 and ComboPoints() >= 2 and not BuffPresent(loaded_dice_buff) and Spell(slice_and_dice) or not ss_useable() and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones)
   {
    #killing_spree,if=energy.time_to_max>5|energy<15
    if TimeToMaxEnergy() > 5 or Energy() < 15 Spell(killing_spree)
    #call_action_list,name=build
    OutlawBuildCdActions()

    unless OutlawBuildCdPostConditions()
    {
     #call_action_list,name=finish,if=!variable.ss_useable
     if not ss_useable() OutlawFinishCdActions()
    }
   }
  }
 }
}

AddFunction OutlawDefaultCdPostConditions
{
 OutlawBfCdPostConditions() or OutlawCdsCdPostConditions() or { Stealthed() or not SpellCooldown(vanish) > 0 or not SpellCooldown(shadowmeld) > 0 } and OutlawStealthCdPostConditions() or TimeToMaxEnergy() > 2 and not ss_useable_noreroll() and Spell(death_from_above) or not ss_useable() and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1 and not BuffImproved(slice_and_dice_buffundefined) and not BuffPresent(loaded_dice_buff) and Spell(slice_and_dice) or BuffPresent(loaded_dice_buff) and ComboPoints() >= MaxComboPoints() and { not BuffImproved(slice_and_dice_buffundefined) or BuffRemaining(slice_and_dice_buff) < 4 } and Spell(slice_and_dice) or BuffImproved(slice_and_dice_buffundefined) and BuffRemaining(slice_and_dice_buff) <= 2 and ComboPoints() >= 2 and not BuffPresent(loaded_dice_buff) and Spell(slice_and_dice) or not ss_useable() and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or OutlawBuildCdPostConditions() or not ss_useable() and OutlawFinishCdPostConditions() or Talent(dirty_tricks_talent) and ComboPointsDeficit() >= 1 and Spell(gouge)
}

### Outlaw icons.

AddCheckBox(opt_rogue_outlaw_aoe L(AOE) default specialization=outlaw)

AddIcon checkbox=!opt_rogue_outlaw_aoe enemies=1 help=shortcd specialization=outlaw
{
 if not InCombat() OutlawPrecombatShortCdActions()
 unless not InCombat() and OutlawPrecombatShortCdPostConditions()
 {
  OutlawDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_rogue_outlaw_aoe help=shortcd specialization=outlaw
{
 if not InCombat() OutlawPrecombatShortCdActions()
 unless not InCombat() and OutlawPrecombatShortCdPostConditions()
 {
  OutlawDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=outlaw
{
 if not InCombat() OutlawPrecombatMainActions()
 unless not InCombat() and OutlawPrecombatMainPostConditions()
 {
  OutlawDefaultMainActions()
 }
}

AddIcon checkbox=opt_rogue_outlaw_aoe help=aoe specialization=outlaw
{
 if not InCombat() OutlawPrecombatMainActions()
 unless not InCombat() and OutlawPrecombatMainPostConditions()
 {
  OutlawDefaultMainActions()
 }
}

AddIcon checkbox=!opt_rogue_outlaw_aoe enemies=1 help=cd specialization=outlaw
{
 if not InCombat() OutlawPrecombatCdActions()
 unless not InCombat() and OutlawPrecombatCdPostConditions()
 {
  OutlawDefaultCdActions()
 }
}

AddIcon checkbox=opt_rogue_outlaw_aoe help=cd specialization=outlaw
{
 if not InCombat() OutlawPrecombatCdActions()
 unless not InCombat() and OutlawPrecombatCdPostConditions()
 {
  OutlawDefaultCdActions()
 }
}

### Required symbols
# ghostly_strike_talent
# ghostly_strike_debuff
# broadsides_buff
# jolly_roger_buff
# hidden_blade_buff
# ambush
# vanish
# mantle_of_the_master_assassin
# master_assassins_initiative
# shadowmeld
# stealth
# prolonged_power_potion
# marked_for_death
# roll_the_bones
# slice_and_dice_talent
# curse_of_the_dreadblades
# between_the_eyes
# thraxis_tricksy_treads
# greenskins_waterlogged_wristcuffs
# greenskins_waterlogged_wristcuffs_buff
# run_through
# death_from_above_talent
# death_from_above
# adrenaline_rush_buff
# blood_fury_ap
# berserking
# arcane_torrent_energy
# cannonball_barrage
# adrenaline_rush
# true_bearing_buff
# sprint
# darkflight
# sprint_buff
# ghostly_strike
# curse_of_the_dreadblades_buff
# pistol_shot
# opportunity_buff
# quick_draw_talent
# blunderbuss_buff
# saber_slash
# blade_flurry
# blade_flurry_buff
# shivarran_symmetry
# loaded_dice_buff
# deeper_stratagem_talent
# alacrity_talent
# alacrity_buff
# anticipation_talent
# slice_and_dice
# slice_and_dice_buff
# roll_the_bones_buff
# killing_spree
# gouge
# dirty_tricks_talent
# kick
# shadowstep
]]
    OvaleScripts:RegisterScript("ROGUE", "outlaw", name, desc, code, "script")
end
do
    local name = "sc_rogue_subtlety_t19"
    local desc = "[7.0] Simulationcraft: Rogue_Subtlety_T19"
    local code = [[
# Based on SimulationCraft profile "Rogue_Subtlety_T19P".
#	class=rogue
#	spec=subtlety
#	talents=2310012

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction dsh_dfa
{
 Talent(death_from_above_talent) and Talent(dark_shadow_talent) and Enemies() < 4
}

AddFunction shd_fractional
{
 1 + 0 * TalentPoints(enveloping_shadows_talent)
}

AddFunction stealth_threshold
{
 65 + TalentPoints(vigor_talent) * 35 + TalentPoints(master_of_shadows_talent) * 10 + ssw_refund()
}

AddFunction ssw_refund
{
 HasEquippedItem(shadow_satyrs_walk) * { 6 + { target.Distance() % 3 - 1 } }
}

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=subtlety)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=subtlety)

AddFunction SubtletyGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
 {
  Spell(shadowstep)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.stealthed

AddFunction SubtletyStealthedMainActions
{
 #shadowstrike,if=buff.stealth.up
 if BuffPresent(stealthed_buff any=1) Spell(shadowstrike)
 #call_action_list,name=finish,if=combo_points>=5+(talent.deeper_stratagem.enabled&buff.vanish.up)&(spell_targets.shuriken_storm>=3+equipped.shadow_satyrs_walk|(mantle_duration<=1.3&mantle_duration>=0.3))
 if ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } SubtletyFinishMainActions()

 unless ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } and SubtletyFinishMainPostConditions()
 {
  #shuriken_storm,if=buff.shadowmeld.down&((combo_points.deficit>=2+equipped.insignia_of_ravenholdt&spell_targets.shuriken_storm>=3+equipped.shadow_satyrs_walk)|(combo_points.deficit>=1&buff.the_dreadlords_deceit.stack>=29))
  if BuffExpires(shadowmeld_buff) and { ComboPointsDeficit() >= 2 + HasEquippedItem(insignia_of_ravenholdt) and Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or ComboPointsDeficit() >= 1 and BuffStacks(the_dreadlords_deceit_buff) >= 29 } Spell(shuriken_storm)
  #call_action_list,name=finish,if=combo_points>=5+(talent.deeper_stratagem.enabled&buff.vanish.up)&combo_points.deficit<3+buff.shadow_blades.up-equipped.mantle_of_the_master_assassin
  if ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and ComboPointsDeficit() < 3 + BuffPresent(shadow_blades_buff) - HasEquippedItem(mantle_of_the_master_assassin) SubtletyFinishMainActions()

  unless ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and ComboPointsDeficit() < 3 + BuffPresent(shadow_blades_buff) - HasEquippedItem(mantle_of_the_master_assassin) and SubtletyFinishMainPostConditions()
  {
   #shadowstrike
   Spell(shadowstrike)
  }
 }
}

AddFunction SubtletyStealthedMainPostConditions
{
 ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } and SubtletyFinishMainPostConditions() or ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and ComboPointsDeficit() < 3 + BuffPresent(shadow_blades_buff) - HasEquippedItem(mantle_of_the_master_assassin) and SubtletyFinishMainPostConditions()
}

AddFunction SubtletyStealthedShortCdActions
{
 unless BuffPresent(stealthed_buff any=1) and Spell(shadowstrike)
 {
  #call_action_list,name=finish,if=combo_points>=5+(talent.deeper_stratagem.enabled&buff.vanish.up)&(spell_targets.shuriken_storm>=3+equipped.shadow_satyrs_walk|(mantle_duration<=1.3&mantle_duration>=0.3))
  if ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } SubtletyFinishShortCdActions()

  unless ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } and SubtletyFinishShortCdPostConditions() or BuffExpires(shadowmeld_buff) and { ComboPointsDeficit() >= 2 + HasEquippedItem(insignia_of_ravenholdt) and Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or ComboPointsDeficit() >= 1 and BuffStacks(the_dreadlords_deceit_buff) >= 29 } and Spell(shuriken_storm)
  {
   #call_action_list,name=finish,if=combo_points>=5+(talent.deeper_stratagem.enabled&buff.vanish.up)&combo_points.deficit<3+buff.shadow_blades.up-equipped.mantle_of_the_master_assassin
   if ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and ComboPointsDeficit() < 3 + BuffPresent(shadow_blades_buff) - HasEquippedItem(mantle_of_the_master_assassin) SubtletyFinishShortCdActions()
  }
 }
}

AddFunction SubtletyStealthedShortCdPostConditions
{
 BuffPresent(stealthed_buff any=1) and Spell(shadowstrike) or ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } and SubtletyFinishShortCdPostConditions() or BuffExpires(shadowmeld_buff) and { ComboPointsDeficit() >= 2 + HasEquippedItem(insignia_of_ravenholdt) and Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or ComboPointsDeficit() >= 1 and BuffStacks(the_dreadlords_deceit_buff) >= 29 } and Spell(shuriken_storm) or ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and ComboPointsDeficit() < 3 + BuffPresent(shadow_blades_buff) - HasEquippedItem(mantle_of_the_master_assassin) and SubtletyFinishShortCdPostConditions() or Spell(shadowstrike)
}

AddFunction SubtletyStealthedCdActions
{
 unless BuffPresent(stealthed_buff any=1) and Spell(shadowstrike)
 {
  #call_action_list,name=finish,if=combo_points>=5+(talent.deeper_stratagem.enabled&buff.vanish.up)&(spell_targets.shuriken_storm>=3+equipped.shadow_satyrs_walk|(mantle_duration<=1.3&mantle_duration>=0.3))
  if ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } SubtletyFinishCdActions()

  unless ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } and SubtletyFinishCdPostConditions() or BuffExpires(shadowmeld_buff) and { ComboPointsDeficit() >= 2 + HasEquippedItem(insignia_of_ravenholdt) and Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or ComboPointsDeficit() >= 1 and BuffStacks(the_dreadlords_deceit_buff) >= 29 } and Spell(shuriken_storm)
  {
   #call_action_list,name=finish,if=combo_points>=5+(talent.deeper_stratagem.enabled&buff.vanish.up)&combo_points.deficit<3+buff.shadow_blades.up-equipped.mantle_of_the_master_assassin
   if ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and ComboPointsDeficit() < 3 + BuffPresent(shadow_blades_buff) - HasEquippedItem(mantle_of_the_master_assassin) SubtletyFinishCdActions()
  }
 }
}

AddFunction SubtletyStealthedCdPostConditions
{
 BuffPresent(stealthed_buff any=1) and Spell(shadowstrike) or ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and { Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or BuffRemaining(master_assassins_initiative) <= 1 and BuffRemaining(master_assassins_initiative) >= 0 } and SubtletyFinishCdPostConditions() or BuffExpires(shadowmeld_buff) and { ComboPointsDeficit() >= 2 + HasEquippedItem(insignia_of_ravenholdt) and Enemies() >= 3 + HasEquippedItem(shadow_satyrs_walk) or ComboPointsDeficit() >= 1 and BuffStacks(the_dreadlords_deceit_buff) >= 29 } and Spell(shuriken_storm) or ComboPoints() >= 5 + { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and ComboPointsDeficit() < 3 + BuffPresent(shadow_blades_buff) - HasEquippedItem(mantle_of_the_master_assassin) and SubtletyFinishCdPostConditions() or Spell(shadowstrike)
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
 #vanish,if=!variable.dsh_dfa&mantle_duration=0&cooldown.shadow_dance.charges_fractional<variable.shd_fractional+(equipped.mantle_of_the_master_assassin&time<30)*0.3&(!equipped.mantle_of_the_master_assassin|buff.symbols_of_death.up)
 if not dsh_dfa() and BuffRemaining(master_assassins_initiative) == 0 and SpellCharges(shadow_dance count=0) < shd_fractional() + { HasEquippedItem(mantle_of_the_master_assassin) and TimeInCombat() < 30 } * 0 and { not HasEquippedItem(mantle_of_the_master_assassin) or BuffPresent(symbols_of_death_buff) } Spell(vanish)
 #shadow_dance,if=charges_fractional>=variable.shd_fractional|target.time_to_die<cooldown.symbols_of_death.remains
 if Charges(shadow_dance count=0) >= shd_fractional() or target.TimeToDie() < SpellCooldown(symbols_of_death) Spell(shadow_dance)
 #pool_resource,for_next=1,extra_amount=40
 #shadowmeld,if=energy>=40&energy.deficit>=10+variable.ssw_refund
 unless True(pool_energy 40) and EnergyDeficit() >= 10 + ssw_refund() and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(40)
 {
  #shadow_dance,if=!variable.dsh_dfa&combo_points.deficit>=2+talent.subterfuge.enabled*2&(buff.symbols_of_death.remains>=1.2|cooldown.symbols_of_death.remains>=12+(talent.dark_shadow.enabled&set_bonus.tier20_4pc)*3-(!talent.dark_shadow.enabled&set_bonus.tier20_4pc)*4|mantle_duration>0)&(spell_targets.shuriken_storm>=4|!buff.the_first_of_the_dead.up)
  if not dsh_dfa() and ComboPointsDeficit() >= 2 + TalentPoints(subterfuge_talent) * 2 and { BuffRemaining(symbols_of_death_buff) >= 1 or SpellCooldown(symbols_of_death) >= 12 + { Talent(dark_shadow_talent) and ArmorSetBonus(T20 4) } * 3 - { not Talent(dark_shadow_talent) and ArmorSetBonus(T20 4) } * 4 or BuffRemaining(master_assassins_initiative) > 0 } and { Enemies() >= 4 or not BuffPresent(the_first_of_the_dead_buff) } Spell(shadow_dance)
 }
}

AddFunction SubtletyStealthcdsShortCdPostConditions
{
}

AddFunction SubtletyStealthcdsCdActions
{
 unless not dsh_dfa() and BuffRemaining(master_assassins_initiative) == 0 and SpellCharges(shadow_dance count=0) < shd_fractional() + { HasEquippedItem(mantle_of_the_master_assassin) and TimeInCombat() < 30 } * 0 and { not HasEquippedItem(mantle_of_the_master_assassin) or BuffPresent(symbols_of_death_buff) } and Spell(vanish) or { Charges(shadow_dance count=0) >= shd_fractional() or target.TimeToDie() < SpellCooldown(symbols_of_death) } and Spell(shadow_dance)
 {
  #pool_resource,for_next=1,extra_amount=40
  #shadowmeld,if=energy>=40&energy.deficit>=10+variable.ssw_refund
  if Energy() >= 40 and EnergyDeficit() >= 10 + ssw_refund() Spell(shadowmeld)
 }
}

AddFunction SubtletyStealthcdsCdPostConditions
{
 not dsh_dfa() and BuffRemaining(master_assassins_initiative) == 0 and SpellCharges(shadow_dance count=0) < shd_fractional() + { HasEquippedItem(mantle_of_the_master_assassin) and TimeInCombat() < 30 } * 0 and { not HasEquippedItem(mantle_of_the_master_assassin) or BuffPresent(symbols_of_death_buff) } and Spell(vanish) or { Charges(shadow_dance count=0) >= shd_fractional() or target.TimeToDie() < SpellCooldown(symbols_of_death) } and Spell(shadow_dance) or not { True(pool_energy 40) and EnergyDeficit() >= 10 + ssw_refund() and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(40) } and not dsh_dfa() and ComboPointsDeficit() >= 2 + TalentPoints(subterfuge_talent) * 2 and { BuffRemaining(symbols_of_death_buff) >= 1 or SpellCooldown(symbols_of_death) >= 12 + { Talent(dark_shadow_talent) and ArmorSetBonus(T20 4) } * 3 - { not Talent(dark_shadow_talent) and ArmorSetBonus(T20 4) } * 4 or BuffRemaining(master_assassins_initiative) > 0 } and { Enemies() >= 4 or not BuffPresent(the_first_of_the_dead_buff) } and Spell(shadow_dance)
}

### actions.stealth_als

AddFunction SubtletyStealthalsMainActions
{
 #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold-25*(!cooldown.goremaws_bite.up&!buff.feeding_frenzy.up)&(!equipped.shadow_satyrs_walk|cooldown.shadow_dance.charges_fractional>=variable.shd_fractional|energy.deficit>=10)
 if EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } SubtletyStealthcdsMainActions()

 unless EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } and SubtletyStealthcdsMainPostConditions()
 {
  #call_action_list,name=stealth_cds,if=mantle_duration>2.3
  if BuffRemaining(master_assassins_initiative) > 2 SubtletyStealthcdsMainActions()

  unless BuffRemaining(master_assassins_initiative) > 2 and SubtletyStealthcdsMainPostConditions()
  {
   #call_action_list,name=stealth_cds,if=spell_targets.shuriken_storm>=4
   if Enemies() >= 4 SubtletyStealthcdsMainActions()

   unless Enemies() >= 4 and SubtletyStealthcdsMainPostConditions()
   {
    #call_action_list,name=stealth_cds,if=(cooldown.shadowmeld.up&!cooldown.vanish.up&cooldown.shadow_dance.charges<=1)
    if not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 SubtletyStealthcdsMainActions()

    unless not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 and SubtletyStealthcdsMainPostConditions()
    {
     #call_action_list,name=stealth_cds,if=target.time_to_die<12*cooldown.shadow_dance.charges_fractional*(1+equipped.shadow_satyrs_walk*0.5)
     if target.TimeToDie() < 12 * SpellCharges(shadow_dance count=0) * { 1 + HasEquippedItem(shadow_satyrs_walk) * 0 } SubtletyStealthcdsMainActions()
    }
   }
  }
 }
}

AddFunction SubtletyStealthalsMainPostConditions
{
 EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } and SubtletyStealthcdsMainPostConditions() or BuffRemaining(master_assassins_initiative) > 2 and SubtletyStealthcdsMainPostConditions() or Enemies() >= 4 and SubtletyStealthcdsMainPostConditions() or not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 and SubtletyStealthcdsMainPostConditions() or target.TimeToDie() < 12 * SpellCharges(shadow_dance count=0) * { 1 + HasEquippedItem(shadow_satyrs_walk) * 0 } and SubtletyStealthcdsMainPostConditions()
}

AddFunction SubtletyStealthalsShortCdActions
{
 #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold-25*(!cooldown.goremaws_bite.up&!buff.feeding_frenzy.up)&(!equipped.shadow_satyrs_walk|cooldown.shadow_dance.charges_fractional>=variable.shd_fractional|energy.deficit>=10)
 if EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } SubtletyStealthcdsShortCdActions()

 unless EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } and SubtletyStealthcdsShortCdPostConditions()
 {
  #call_action_list,name=stealth_cds,if=mantle_duration>2.3
  if BuffRemaining(master_assassins_initiative) > 2 SubtletyStealthcdsShortCdActions()

  unless BuffRemaining(master_assassins_initiative) > 2 and SubtletyStealthcdsShortCdPostConditions()
  {
   #call_action_list,name=stealth_cds,if=spell_targets.shuriken_storm>=4
   if Enemies() >= 4 SubtletyStealthcdsShortCdActions()

   unless Enemies() >= 4 and SubtletyStealthcdsShortCdPostConditions()
   {
    #call_action_list,name=stealth_cds,if=(cooldown.shadowmeld.up&!cooldown.vanish.up&cooldown.shadow_dance.charges<=1)
    if not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 SubtletyStealthcdsShortCdActions()

    unless not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 and SubtletyStealthcdsShortCdPostConditions()
    {
     #call_action_list,name=stealth_cds,if=target.time_to_die<12*cooldown.shadow_dance.charges_fractional*(1+equipped.shadow_satyrs_walk*0.5)
     if target.TimeToDie() < 12 * SpellCharges(shadow_dance count=0) * { 1 + HasEquippedItem(shadow_satyrs_walk) * 0 } SubtletyStealthcdsShortCdActions()
    }
   }
  }
 }
}

AddFunction SubtletyStealthalsShortCdPostConditions
{
 EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } and SubtletyStealthcdsShortCdPostConditions() or BuffRemaining(master_assassins_initiative) > 2 and SubtletyStealthcdsShortCdPostConditions() or Enemies() >= 4 and SubtletyStealthcdsShortCdPostConditions() or not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 and SubtletyStealthcdsShortCdPostConditions() or target.TimeToDie() < 12 * SpellCharges(shadow_dance count=0) * { 1 + HasEquippedItem(shadow_satyrs_walk) * 0 } and SubtletyStealthcdsShortCdPostConditions()
}

AddFunction SubtletyStealthalsCdActions
{
 #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold-25*(!cooldown.goremaws_bite.up&!buff.feeding_frenzy.up)&(!equipped.shadow_satyrs_walk|cooldown.shadow_dance.charges_fractional>=variable.shd_fractional|energy.deficit>=10)
 if EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } SubtletyStealthcdsCdActions()

 unless EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } and SubtletyStealthcdsCdPostConditions()
 {
  #call_action_list,name=stealth_cds,if=mantle_duration>2.3
  if BuffRemaining(master_assassins_initiative) > 2 SubtletyStealthcdsCdActions()

  unless BuffRemaining(master_assassins_initiative) > 2 and SubtletyStealthcdsCdPostConditions()
  {
   #call_action_list,name=stealth_cds,if=spell_targets.shuriken_storm>=4
   if Enemies() >= 4 SubtletyStealthcdsCdActions()

   unless Enemies() >= 4 and SubtletyStealthcdsCdPostConditions()
   {
    #call_action_list,name=stealth_cds,if=(cooldown.shadowmeld.up&!cooldown.vanish.up&cooldown.shadow_dance.charges<=1)
    if not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 SubtletyStealthcdsCdActions()

    unless not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 and SubtletyStealthcdsCdPostConditions()
    {
     #call_action_list,name=stealth_cds,if=target.time_to_die<12*cooldown.shadow_dance.charges_fractional*(1+equipped.shadow_satyrs_walk*0.5)
     if target.TimeToDie() < 12 * SpellCharges(shadow_dance count=0) * { 1 + HasEquippedItem(shadow_satyrs_walk) * 0 } SubtletyStealthcdsCdActions()
    }
   }
  }
 }
}

AddFunction SubtletyStealthalsCdPostConditions
{
 EnergyDeficit() <= stealth_threshold() - 25 * { not { not SpellCooldown(goremaws_bite) > 0 } and not BuffPresent(feeding_frenzy_buff) } and { not HasEquippedItem(shadow_satyrs_walk) or SpellCharges(shadow_dance count=0) >= shd_fractional() or EnergyDeficit() >= 10 } and SubtletyStealthcdsCdPostConditions() or BuffRemaining(master_assassins_initiative) > 2 and SubtletyStealthcdsCdPostConditions() or Enemies() >= 4 and SubtletyStealthcdsCdPostConditions() or not SpellCooldown(shadowmeld) > 0 and not { not SpellCooldown(vanish) > 0 } and SpellCharges(shadow_dance) <= 1 and SubtletyStealthcdsCdPostConditions() or target.TimeToDie() < 12 * SpellCharges(shadow_dance count=0) * { 1 + HasEquippedItem(shadow_satyrs_walk) * 0 } and SubtletyStealthcdsCdPostConditions()
}

### actions.precombat

AddFunction SubtletyPrecombatMainActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #variable,name=ssw_refund,value=equipped.shadow_satyrs_walk*(6+ssw_refund_offset)
 #variable,name=stealth_threshold,value=(65+talent.vigor.enabled*35+talent.master_of_shadows.enabled*10+variable.ssw_refund)
 #variable,name=shd_fractional,value=1.725+0.725*talent.enveloping_shadows.enabled
 #stealth
 Spell(stealth)
}

AddFunction SubtletyPrecombatMainPostConditions
{
}

AddFunction SubtletyPrecombatShortCdActions
{
 unless Spell(stealth)
 {
  #marked_for_death,precombat=1
  if not InCombat() Spell(marked_for_death)
 }
}

AddFunction SubtletyPrecombatShortCdPostConditions
{
 Spell(stealth)
}

AddFunction SubtletyPrecombatCdActions
{
 unless Spell(stealth) or not InCombat() and Spell(marked_for_death)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 }
}

AddFunction SubtletyPrecombatCdPostConditions
{
 Spell(stealth) or not InCombat() and Spell(marked_for_death)
}

### actions.finish

AddFunction SubtletyFinishMainActions
{
 #nightblade,if=(!talent.dark_shadow.enabled|!buff.shadow_dance.up)&target.time_to_die-remains>6&(mantle_duration=0|remains<=mantle_duration)&((refreshable&(!finality|buff.finality_nightblade.up|variable.dsh_dfa))|remains<tick_time*2)&(spell_targets.shuriken_storm<4&!variable.dsh_dfa|!buff.symbols_of_death.up)
 if { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and { BuffRemaining(master_assassins_initiative) == 0 or target.DebuffRemaining(nightblade_debuff) <= BuffRemaining(master_assassins_initiative) } and { target.Refreshable(nightblade_debuff) and { not HasArtifactTrait(finality) or BuffPresent(finality_nightblade_buff) or dsh_dfa() } or target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 } and { Enemies() < 4 and not dsh_dfa() or not BuffPresent(symbols_of_death_buff) } Spell(nightblade)
 #nightblade,cycle_targets=1,if=(!talent.death_from_above.enabled|set_bonus.tier19_2pc)&(!talent.dark_shadow.enabled|!buff.shadow_dance.up)&target.time_to_die-remains>12&mantle_duration=0&((refreshable&(!finality|buff.finality_nightblade.up|variable.dsh_dfa))|remains<tick_time*2)&(spell_targets.shuriken_storm<4&!variable.dsh_dfa|!buff.symbols_of_death.up)
 if { not Talent(death_from_above_talent) or ArmorSetBonus(T19 2) } and { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 12 and BuffRemaining(master_assassins_initiative) == 0 and { target.Refreshable(nightblade_debuff) and { not HasArtifactTrait(finality) or BuffPresent(finality_nightblade_buff) or dsh_dfa() } or target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 } and { Enemies() < 4 and not dsh_dfa() or not BuffPresent(symbols_of_death_buff) } Spell(nightblade)
 #nightblade,if=remains<cooldown.symbols_of_death.remains+10&cooldown.symbols_of_death.remains<=5+(combo_points=6)&target.time_to_die-remains>cooldown.symbols_of_death.remains+5
 if target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 + { ComboPoints() == 6 } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 Spell(nightblade)
 #death_from_above,if=!talent.dark_shadow.enabled|(!buff.shadow_dance.up|spell_targets>=4)&(buff.symbols_of_death.up|cooldown.symbols_of_death.remains>=10+set_bonus.tier20_4pc*5)&buff.the_first_of_the_dead.remains<1&(buff.finality_eviscerate.up|spell_targets.shuriken_storm<4)
 if not Talent(dark_shadow_talent) or { not BuffPresent(shadow_dance_buff) or Enemies() >= 4 } and { BuffPresent(symbols_of_death_buff) or SpellCooldown(symbols_of_death) >= 10 + ArmorSetBonus(T20 4) * 5 } and BuffRemaining(the_first_of_the_dead_buff) < 1 and { BuffPresent(finality_eviscerate_buff) or Enemies() < 4 } Spell(death_from_above)
 #eviscerate
 Spell(eviscerate)
}

AddFunction SubtletyFinishMainPostConditions
{
}

AddFunction SubtletyFinishShortCdActions
{
}

AddFunction SubtletyFinishShortCdPostConditions
{
 { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and { BuffRemaining(master_assassins_initiative) == 0 or target.DebuffRemaining(nightblade_debuff) <= BuffRemaining(master_assassins_initiative) } and { target.Refreshable(nightblade_debuff) and { not HasArtifactTrait(finality) or BuffPresent(finality_nightblade_buff) or dsh_dfa() } or target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 } and { Enemies() < 4 and not dsh_dfa() or not BuffPresent(symbols_of_death_buff) } and Spell(nightblade) or { not Talent(death_from_above_talent) or ArmorSetBonus(T19 2) } and { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 12 and BuffRemaining(master_assassins_initiative) == 0 and { target.Refreshable(nightblade_debuff) and { not HasArtifactTrait(finality) or BuffPresent(finality_nightblade_buff) or dsh_dfa() } or target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 } and { Enemies() < 4 and not dsh_dfa() or not BuffPresent(symbols_of_death_buff) } and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 + { ComboPoints() == 6 } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade) or { not Talent(dark_shadow_talent) or { not BuffPresent(shadow_dance_buff) or Enemies() >= 4 } and { BuffPresent(symbols_of_death_buff) or SpellCooldown(symbols_of_death) >= 10 + ArmorSetBonus(T20 4) * 5 } and BuffRemaining(the_first_of_the_dead_buff) < 1 and { BuffPresent(finality_eviscerate_buff) or Enemies() < 4 } } and Spell(death_from_above) or Spell(eviscerate)
}

AddFunction SubtletyFinishCdActions
{
}

AddFunction SubtletyFinishCdPostConditions
{
 { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and { BuffRemaining(master_assassins_initiative) == 0 or target.DebuffRemaining(nightblade_debuff) <= BuffRemaining(master_assassins_initiative) } and { target.Refreshable(nightblade_debuff) and { not HasArtifactTrait(finality) or BuffPresent(finality_nightblade_buff) or dsh_dfa() } or target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 } and { Enemies() < 4 and not dsh_dfa() or not BuffPresent(symbols_of_death_buff) } and Spell(nightblade) or { not Talent(death_from_above_talent) or ArmorSetBonus(T19 2) } and { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 12 and BuffRemaining(master_assassins_initiative) == 0 and { target.Refreshable(nightblade_debuff) and { not HasArtifactTrait(finality) or BuffPresent(finality_nightblade_buff) or dsh_dfa() } or target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 } and { Enemies() < 4 and not dsh_dfa() or not BuffPresent(symbols_of_death_buff) } and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 + { ComboPoints() == 6 } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade) or { not Talent(dark_shadow_talent) or { not BuffPresent(shadow_dance_buff) or Enemies() >= 4 } and { BuffPresent(symbols_of_death_buff) or SpellCooldown(symbols_of_death) >= 10 + ArmorSetBonus(T20 4) * 5 } and BuffRemaining(the_first_of_the_dead_buff) < 1 and { BuffPresent(finality_eviscerate_buff) or Enemies() < 4 } } and Spell(death_from_above) or Spell(eviscerate)
}

### actions.cds

AddFunction SubtletyCdsMainActions
{
 #goremaws_bite,if=!stealthed.all&cooldown.shadow_dance.charges_fractional<=variable.shd_fractional&((combo_points.deficit>=4-(time<10)*2&energy.deficit>50+talent.vigor.enabled*25-(time>=10)*15)|(combo_points.deficit>=1&target.time_to_die<8))
 if not Stealthed() and SpellCharges(shadow_dance count=0) <= shd_fractional() and { ComboPointsDeficit() >= 4 - { TimeInCombat() < 10 } * 2 and EnergyDeficit() > 50 + TalentPoints(vigor_talent) * 25 - { TimeInCombat() >= 10 } * 15 or ComboPointsDeficit() >= 1 and target.TimeToDie() < 8 } Spell(goremaws_bite)
}

AddFunction SubtletyCdsMainPostConditions
{
}

AddFunction SubtletyCdsShortCdActions
{
 #symbols_of_death,if=!talent.death_from_above.enabled&((time>10&energy.deficit>=40-stealthed.all*30)|(time<10&dot.nightblade.ticking))
 if not Talent(death_from_above_talent) and { TimeInCombat() > 10 and EnergyDeficit() >= 40 - Stealthed() * 30 or TimeInCombat() < 10 and target.DebuffPresent(nightblade_debuff) } Spell(symbols_of_death)
 #symbols_of_death,if=(talent.death_from_above.enabled&cooldown.death_from_above.remains<=1&(dot.nightblade.remains>=cooldown.death_from_above.remains+3|target.time_to_die-dot.nightblade.remains<=6)&(time>=3|set_bonus.tier20_4pc|equipped.the_first_of_the_dead))|target.time_to_die-remains<=10
 if Talent(death_from_above_talent) and SpellCooldown(death_from_above) <= 1 and { target.DebuffRemaining(nightblade_debuff) >= SpellCooldown(death_from_above) + 3 or target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) <= 6 } and { TimeInCombat() >= 3 or ArmorSetBonus(T20 4) or HasEquippedItem(the_first_of_the_dead) } or target.TimeToDie() - BuffRemaining(symbols_of_death_buff) <= 10 Spell(symbols_of_death)
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit
 if target.TimeToDie() < ComboPointsDeficit() Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>40&!stealthed.all&combo_points.deficit>=cp_max_spend
 if 600 > 40 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)

 unless not Stealthed() and SpellCharges(shadow_dance count=0) <= shd_fractional() and { ComboPointsDeficit() >= 4 - { TimeInCombat() < 10 } * 2 and EnergyDeficit() > 50 + TalentPoints(vigor_talent) * 25 - { TimeInCombat() >= 10 } * 15 or ComboPointsDeficit() >= 1 and target.TimeToDie() < 8 } and Spell(goremaws_bite)
 {
  #pool_resource,for_next=1,extra_amount=55-talent.shadow_focus.enabled*10
  #vanish,if=energy>=55-talent.shadow_focus.enabled*10&variable.dsh_dfa&(!equipped.mantle_of_the_master_assassin|buff.symbols_of_death.up)&cooldown.shadow_dance.charges_fractional<=variable.shd_fractional&!buff.shadow_dance.up&!buff.stealth.up&mantle_duration=0&(dot.nightblade.remains>=cooldown.death_from_above.remains+6|target.time_to_die-dot.nightblade.remains<=6)&cooldown.death_from_above.remains<=1|target.time_to_die<=7
  if Energy() >= 55 - TalentPoints(shadow_focus_talent) * 10 and dsh_dfa() and { not HasEquippedItem(mantle_of_the_master_assassin) or BuffPresent(symbols_of_death_buff) } and SpellCharges(shadow_dance count=0) <= shd_fractional() and not BuffPresent(shadow_dance_buff) and not BuffPresent(stealthed_buff any=1) and BuffRemaining(master_assassins_initiative) == 0 and { target.DebuffRemaining(nightblade_debuff) >= SpellCooldown(death_from_above) + 6 or target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) <= 6 } and SpellCooldown(death_from_above) <= 1 or target.TimeToDie() <= 7 Spell(vanish)
  unless { True(pool_energy 55) - TalentPoints(shadow_focus_talent) * 10 and dsh_dfa() and { not HasEquippedItem(mantle_of_the_master_assassin) or BuffPresent(symbols_of_death_buff) } and SpellCharges(shadow_dance count=0) <= shd_fractional() and not BuffPresent(shadow_dance_buff) and not BuffPresent(stealthed_buff any=1) and BuffRemaining(master_assassins_initiative) == 0 and { target.DebuffRemaining(nightblade_debuff) >= SpellCooldown(death_from_above) + 6 or target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) <= 6 } and SpellCooldown(death_from_above) <= 1 or target.TimeToDie() <= 7 } and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(55)
  {
   #shadow_dance,if=!buff.shadow_dance.up&target.time_to_die<=4+talent.subterfuge.enabled
   if not BuffPresent(shadow_dance_buff) and target.TimeToDie() <= 4 + TalentPoints(subterfuge_talent) Spell(shadow_dance)
  }
 }
}

AddFunction SubtletyCdsShortCdPostConditions
{
 not Stealthed() and SpellCharges(shadow_dance count=0) <= shd_fractional() and { ComboPointsDeficit() >= 4 - { TimeInCombat() < 10 } * 2 and EnergyDeficit() > 50 + TalentPoints(vigor_talent) * 25 - { TimeInCombat() >= 10 } * 15 or ComboPointsDeficit() >= 1 and target.TimeToDie() < 8 } and Spell(goremaws_bite)
}

AddFunction SubtletyCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|(buff.vanish.up&(buff.shadow_blades.up|cooldown.shadow_blades.remains<=30))
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or BuffPresent(vanish_buff) and { BuffPresent(shadow_blades_buff) or SpellCooldown(shadow_blades) <= 30 } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
 #blood_fury,if=stealthed.rogue
 if Stealthed() Spell(blood_fury_ap)
 #berserking,if=stealthed.rogue
 if Stealthed() Spell(berserking)
 #arcane_torrent,if=stealthed.rogue&energy.deficit>70
 if Stealthed() and EnergyDeficit() > 70 Spell(arcane_torrent_energy)

 unless not Talent(death_from_above_talent) and { TimeInCombat() > 10 and EnergyDeficit() >= 40 - Stealthed() * 30 or TimeInCombat() < 10 and target.DebuffPresent(nightblade_debuff) } and Spell(symbols_of_death) or { Talent(death_from_above_talent) and SpellCooldown(death_from_above) <= 1 and { target.DebuffRemaining(nightblade_debuff) >= SpellCooldown(death_from_above) + 3 or target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) <= 6 } and { TimeInCombat() >= 3 or ArmorSetBonus(T20 4) or HasEquippedItem(the_first_of_the_dead) } or target.TimeToDie() - BuffRemaining(symbols_of_death_buff) <= 10 } and Spell(symbols_of_death) or target.TimeToDie() < ComboPointsDeficit() and Spell(marked_for_death) or 600 > 40 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death)
 {
  #shadow_blades,if=(time>10&combo_points.deficit>=2+stealthed.all-equipped.mantle_of_the_master_assassin)|(time<10&(!talent.marked_for_death.enabled|combo_points.deficit>=3|dot.nightblade.ticking))
  if TimeInCombat() > 10 and ComboPointsDeficit() >= 2 + Stealthed() - HasEquippedItem(mantle_of_the_master_assassin) or TimeInCombat() < 10 and { not Talent(marked_for_death_talent) or ComboPointsDeficit() >= 3 or target.DebuffPresent(nightblade_debuff) } Spell(shadow_blades)
 }
}

AddFunction SubtletyCdsCdPostConditions
{
 not Talent(death_from_above_talent) and { TimeInCombat() > 10 and EnergyDeficit() >= 40 - Stealthed() * 30 or TimeInCombat() < 10 and target.DebuffPresent(nightblade_debuff) } and Spell(symbols_of_death) or { Talent(death_from_above_talent) and SpellCooldown(death_from_above) <= 1 and { target.DebuffRemaining(nightblade_debuff) >= SpellCooldown(death_from_above) + 3 or target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) <= 6 } and { TimeInCombat() >= 3 or ArmorSetBonus(T20 4) or HasEquippedItem(the_first_of_the_dead) } or target.TimeToDie() - BuffRemaining(symbols_of_death_buff) <= 10 } and Spell(symbols_of_death) or target.TimeToDie() < ComboPointsDeficit() and Spell(marked_for_death) or 600 > 40 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death) or not Stealthed() and SpellCharges(shadow_dance count=0) <= shd_fractional() and { ComboPointsDeficit() >= 4 - { TimeInCombat() < 10 } * 2 and EnergyDeficit() > 50 + TalentPoints(vigor_talent) * 25 - { TimeInCombat() >= 10 } * 15 or ComboPointsDeficit() >= 1 and target.TimeToDie() < 8 } and Spell(goremaws_bite) or { Energy() >= 55 - TalentPoints(shadow_focus_talent) * 10 and dsh_dfa() and { not HasEquippedItem(mantle_of_the_master_assassin) or BuffPresent(symbols_of_death_buff) } and SpellCharges(shadow_dance count=0) <= shd_fractional() and not BuffPresent(shadow_dance_buff) and not BuffPresent(stealthed_buff any=1) and BuffRemaining(master_assassins_initiative) == 0 and { target.DebuffRemaining(nightblade_debuff) >= SpellCooldown(death_from_above) + 6 or target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) <= 6 } and SpellCooldown(death_from_above) <= 1 or target.TimeToDie() <= 7 } and Spell(vanish) or not { { True(pool_energy 55) - TalentPoints(shadow_focus_talent) * 10 and dsh_dfa() and { not HasEquippedItem(mantle_of_the_master_assassin) or BuffPresent(symbols_of_death_buff) } and SpellCharges(shadow_dance count=0) <= shd_fractional() and not BuffPresent(shadow_dance_buff) and not BuffPresent(stealthed_buff any=1) and BuffRemaining(master_assassins_initiative) == 0 and { target.DebuffRemaining(nightblade_debuff) >= SpellCooldown(death_from_above) + 6 or target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) <= 6 } and SpellCooldown(death_from_above) <= 1 or target.TimeToDie() <= 7 } and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(55) } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() <= 4 + TalentPoints(subterfuge_talent) and Spell(shadow_dance)
}

### actions.build

AddFunction SubtletyBuildMainActions
{
 #shuriken_storm,if=spell_targets.shuriken_storm>=2+buff.the_first_of_the_dead.up
 if Enemies() >= 2 + BuffPresent(the_first_of_the_dead_buff) Spell(shuriken_storm)
 #gloomblade
 Spell(gloomblade)
 #backstab
 Spell(backstab)
}

AddFunction SubtletyBuildMainPostConditions
{
}

AddFunction SubtletyBuildShortCdActions
{
}

AddFunction SubtletyBuildShortCdPostConditions
{
 Enemies() >= 2 + BuffPresent(the_first_of_the_dead_buff) and Spell(shuriken_storm) or Spell(gloomblade) or Spell(backstab)
}

AddFunction SubtletyBuildCdActions
{
}

AddFunction SubtletyBuildCdPostConditions
{
 Enemies() >= 2 + BuffPresent(the_first_of_the_dead_buff) and Spell(shuriken_storm) or Spell(gloomblade) or Spell(backstab)
}

### actions.default

AddFunction SubtletyDefaultMainActions
{
 #wait,sec=0.1,if=buff.shadow_dance.up&gcd.remains>0
 unless BuffPresent(shadow_dance_buff) and GCDRemaining() > 0 and 0 > 0
 {
  #call_action_list,name=cds
  SubtletyCdsMainActions()

  unless SubtletyCdsMainPostConditions()
  {
   #run_action_list,name=stealthed,if=stealthed.all
   if Stealthed() SubtletyStealthedMainActions()

   unless Stealthed() and SubtletyStealthedMainPostConditions()
   {
    #nightblade,if=target.time_to_die>6&remains<gcd.max&combo_points>=4-(time<10)*2
    if target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 Spell(nightblade)
    #call_action_list,name=stealth_als,if=talent.dark_shadow.enabled&combo_points.deficit>=2+buff.shadow_blades.up&(dot.nightblade.remains>4+talent.subterfuge.enabled|cooldown.shadow_dance.charges_fractional>=1.9&(!equipped.denial_of_the_halfgiants|time>10))
    if Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } SubtletyStealthalsMainActions()

    unless Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } and SubtletyStealthalsMainPostConditions()
    {
     #call_action_list,name=stealth_als,if=!talent.dark_shadow.enabled&(combo_points.deficit>=2+buff.shadow_blades.up|cooldown.shadow_dance.charges_fractional>=1.9+talent.enveloping_shadows.enabled)
     if not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } SubtletyStealthalsMainActions()

     unless not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } and SubtletyStealthalsMainPostConditions()
     {
      #call_action_list,name=finish,if=combo_points>=5+3*(buff.the_first_of_the_dead.up&talent.anticipation.enabled)+(talent.deeper_stratagem.enabled&!buff.shadow_blades.up&(mantle_duration=0|set_bonus.tier20_4pc)&(!buff.the_first_of_the_dead.up|variable.dsh_dfa))|(combo_points>=4&combo_points.deficit<=2&spell_targets.shuriken_storm>=3&spell_targets.shuriken_storm<=4)|(target.time_to_die<=1&combo_points>=3)
      if ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishMainActions()

      unless { ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishMainPostConditions()
      {
       #call_action_list,name=finish,if=variable.dsh_dfa&cooldown.symbols_of_death.remains<=1&combo_points>=2&equipped.the_first_of_the_dead&spell_targets.shuriken_storm<2
       if dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 SubtletyFinishMainActions()

       unless dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 and SubtletyFinishMainPostConditions()
       {
        #wait,sec=time_to_sht.4,if=combo_points=5&time_to_sht.4<=1&energy.deficit>=30
        unless ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0
        {
         #wait,sec=time_to_sht.5,if=combo_points=5&time_to_sht.5<=1&energy.deficit>=30
         unless ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0
         {
          #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
          if EnergyDeficit() <= stealth_threshold() SubtletyBuildMainActions()
         }
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultMainPostConditions
{
 not { BuffPresent(shadow_dance_buff) and GCDRemaining() > 0 and 0 > 0 } and { SubtletyCdsMainPostConditions() or Stealthed() and SubtletyStealthedMainPostConditions() or Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } and SubtletyStealthalsMainPostConditions() or not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } and SubtletyStealthalsMainPostConditions() or { ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishMainPostConditions() or dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 and SubtletyFinishMainPostConditions() or not { ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0 } and not { ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0 } and EnergyDeficit() <= stealth_threshold() and SubtletyBuildMainPostConditions() }
}

AddFunction SubtletyDefaultShortCdActions
{
 #variable,name=dsh_dfa,value=talent.death_from_above.enabled&talent.dark_shadow.enabled&spell_targets.death_from_above<4
 #shadow_dance,if=talent.dark_shadow.enabled&(!stealthed.all|buff.subterfuge.up)&buff.death_from_above.up&buff.death_from_above.remains<=0.15
 if Talent(dark_shadow_talent) and { not Stealthed() or BuffPresent(subterfuge_buff) } and BuffPresent(death_from_above_buff) and BuffRemaining(death_from_above_buff) <= 0 Spell(shadow_dance)
 #wait,sec=0.1,if=buff.shadow_dance.up&gcd.remains>0
 unless BuffPresent(shadow_dance_buff) and GCDRemaining() > 0 and 0 > 0
 {
  #call_action_list,name=cds
  SubtletyCdsShortCdActions()

  unless SubtletyCdsShortCdPostConditions()
  {
   #run_action_list,name=stealthed,if=stealthed.all
   if Stealthed() SubtletyStealthedShortCdActions()

   unless Stealthed() and SubtletyStealthedShortCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade)
   {
    #call_action_list,name=stealth_als,if=talent.dark_shadow.enabled&combo_points.deficit>=2+buff.shadow_blades.up&(dot.nightblade.remains>4+talent.subterfuge.enabled|cooldown.shadow_dance.charges_fractional>=1.9&(!equipped.denial_of_the_halfgiants|time>10))
    if Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } SubtletyStealthalsShortCdActions()

    unless Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } and SubtletyStealthalsShortCdPostConditions()
    {
     #call_action_list,name=stealth_als,if=!talent.dark_shadow.enabled&(combo_points.deficit>=2+buff.shadow_blades.up|cooldown.shadow_dance.charges_fractional>=1.9+talent.enveloping_shadows.enabled)
     if not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } SubtletyStealthalsShortCdActions()

     unless not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } and SubtletyStealthalsShortCdPostConditions()
     {
      #call_action_list,name=finish,if=combo_points>=5+3*(buff.the_first_of_the_dead.up&talent.anticipation.enabled)+(talent.deeper_stratagem.enabled&!buff.shadow_blades.up&(mantle_duration=0|set_bonus.tier20_4pc)&(!buff.the_first_of_the_dead.up|variable.dsh_dfa))|(combo_points>=4&combo_points.deficit<=2&spell_targets.shuriken_storm>=3&spell_targets.shuriken_storm<=4)|(target.time_to_die<=1&combo_points>=3)
      if ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishShortCdActions()

      unless { ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishShortCdPostConditions()
      {
       #call_action_list,name=finish,if=variable.dsh_dfa&cooldown.symbols_of_death.remains<=1&combo_points>=2&equipped.the_first_of_the_dead&spell_targets.shuriken_storm<2
       if dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 SubtletyFinishShortCdActions()

       unless dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 and SubtletyFinishShortCdPostConditions()
       {
        #wait,sec=time_to_sht.4,if=combo_points=5&time_to_sht.4<=1&energy.deficit>=30
        unless ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0
        {
         #wait,sec=time_to_sht.5,if=combo_points=5&time_to_sht.5<=1&energy.deficit>=30
         unless ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0
         {
          #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
          if EnergyDeficit() <= stealth_threshold() SubtletyBuildShortCdActions()
         }
        }
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
 not { BuffPresent(shadow_dance_buff) and GCDRemaining() > 0 and 0 > 0 } and { SubtletyCdsShortCdPostConditions() or Stealthed() and SubtletyStealthedShortCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade) or Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } and SubtletyStealthalsShortCdPostConditions() or not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } and SubtletyStealthalsShortCdPostConditions() or { ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishShortCdPostConditions() or dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 and SubtletyFinishShortCdPostConditions() or not { ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0 } and not { ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0 } and EnergyDeficit() <= stealth_threshold() and SubtletyBuildShortCdPostConditions() }
}

AddFunction SubtletyDefaultCdActions
{
 unless Talent(dark_shadow_talent) and { not Stealthed() or BuffPresent(subterfuge_buff) } and BuffPresent(death_from_above_buff) and BuffRemaining(death_from_above_buff) <= 0 and Spell(shadow_dance)
 {
  #wait,sec=0.1,if=buff.shadow_dance.up&gcd.remains>0
  unless BuffPresent(shadow_dance_buff) and GCDRemaining() > 0 and 0 > 0
  {
   #call_action_list,name=cds
   SubtletyCdsCdActions()

   unless SubtletyCdsCdPostConditions()
   {
    #run_action_list,name=stealthed,if=stealthed.all
    if Stealthed() SubtletyStealthedCdActions()

    unless Stealthed() and SubtletyStealthedCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade)
    {
     #call_action_list,name=stealth_als,if=talent.dark_shadow.enabled&combo_points.deficit>=2+buff.shadow_blades.up&(dot.nightblade.remains>4+talent.subterfuge.enabled|cooldown.shadow_dance.charges_fractional>=1.9&(!equipped.denial_of_the_halfgiants|time>10))
     if Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } SubtletyStealthalsCdActions()

     unless Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } and SubtletyStealthalsCdPostConditions()
     {
      #call_action_list,name=stealth_als,if=!talent.dark_shadow.enabled&(combo_points.deficit>=2+buff.shadow_blades.up|cooldown.shadow_dance.charges_fractional>=1.9+talent.enveloping_shadows.enabled)
      if not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } SubtletyStealthalsCdActions()

      unless not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } and SubtletyStealthalsCdPostConditions()
      {
       #call_action_list,name=finish,if=combo_points>=5+3*(buff.the_first_of_the_dead.up&talent.anticipation.enabled)+(talent.deeper_stratagem.enabled&!buff.shadow_blades.up&(mantle_duration=0|set_bonus.tier20_4pc)&(!buff.the_first_of_the_dead.up|variable.dsh_dfa))|(combo_points>=4&combo_points.deficit<=2&spell_targets.shuriken_storm>=3&spell_targets.shuriken_storm<=4)|(target.time_to_die<=1&combo_points>=3)
       if ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishCdActions()

       unless { ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishCdPostConditions()
       {
        #call_action_list,name=finish,if=variable.dsh_dfa&cooldown.symbols_of_death.remains<=1&combo_points>=2&equipped.the_first_of_the_dead&spell_targets.shuriken_storm<2
        if dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 SubtletyFinishCdActions()

        unless dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 and SubtletyFinishCdPostConditions()
        {
         #wait,sec=time_to_sht.4,if=combo_points=5&time_to_sht.4<=1&energy.deficit>=30
         unless ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0
         {
          #wait,sec=time_to_sht.5,if=combo_points=5&time_to_sht.5<=1&energy.deficit>=30
          unless ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0
          {
           #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
           if EnergyDeficit() <= stealth_threshold() SubtletyBuildCdActions()
          }
         }
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
 Talent(dark_shadow_talent) and { not Stealthed() or BuffPresent(subterfuge_buff) } and BuffPresent(death_from_above_buff) and BuffRemaining(death_from_above_buff) <= 0 and Spell(shadow_dance) or not { BuffPresent(shadow_dance_buff) and GCDRemaining() > 0 and 0 > 0 } and { SubtletyCdsCdPostConditions() or Stealthed() and SubtletyStealthedCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade) or Talent(dark_shadow_talent) and ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) and { target.DebuffRemaining(nightblade_debuff) > 4 + TalentPoints(subterfuge_talent) or SpellCharges(shadow_dance count=0) >= 1 and { not HasEquippedItem(denial_of_the_halfgiants) or TimeInCombat() > 10 } } and SubtletyStealthalsCdPostConditions() or not Talent(dark_shadow_talent) and { ComboPointsDeficit() >= 2 + BuffPresent(shadow_blades_buff) or SpellCharges(shadow_dance count=0) >= 1 + TalentPoints(enveloping_shadows_talent) } and SubtletyStealthalsCdPostConditions() or { ComboPoints() >= 5 + 3 * { BuffPresent(the_first_of_the_dead_buff) and Talent(anticipation_talent) } + { Talent(deeper_stratagem_talent) and not BuffPresent(shadow_blades_buff) and { BuffRemaining(master_assassins_initiative) == 0 or ArmorSetBonus(T20 4) } and { not BuffPresent(the_first_of_the_dead_buff) or dsh_dfa() } } or ComboPoints() >= 4 and ComboPointsDeficit() <= 2 and Enemies() >= 3 and Enemies() <= 4 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishCdPostConditions() or dsh_dfa() and SpellCooldown(symbols_of_death) <= 1 and ComboPoints() >= 2 and HasEquippedItem(the_first_of_the_dead) and Enemies() < 2 and SubtletyFinishCdPostConditions() or not { ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0 } and not { ComboPoints() == 5 and 100 <= 1 and EnergyDeficit() >= 30 and 100 > 0 } and EnergyDeficit() <= stealth_threshold() and SubtletyBuildCdPostConditions() }
}

### Subtlety icons.

AddCheckBox(opt_rogue_subtlety_aoe L(AOE) default specialization=subtlety)

AddIcon checkbox=!opt_rogue_subtlety_aoe enemies=1 help=shortcd specialization=subtlety
{
 if not InCombat() SubtletyPrecombatShortCdActions()
 unless not InCombat() and SubtletyPrecombatShortCdPostConditions()
 {
  SubtletyDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=shortcd specialization=subtlety
{
 if not InCombat() SubtletyPrecombatShortCdActions()
 unless not InCombat() and SubtletyPrecombatShortCdPostConditions()
 {
  SubtletyDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=subtlety
{
 if not InCombat() SubtletyPrecombatMainActions()
 unless not InCombat() and SubtletyPrecombatMainPostConditions()
 {
  SubtletyDefaultMainActions()
 }
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=aoe specialization=subtlety
{
 if not InCombat() SubtletyPrecombatMainActions()
 unless not InCombat() and SubtletyPrecombatMainPostConditions()
 {
  SubtletyDefaultMainActions()
 }
}

AddIcon checkbox=!opt_rogue_subtlety_aoe enemies=1 help=cd specialization=subtlety
{
 if not InCombat() SubtletyPrecombatCdActions()
 unless not InCombat() and SubtletyPrecombatCdPostConditions()
 {
  SubtletyDefaultCdActions()
 }
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=cd specialization=subtlety
{
 if not InCombat() SubtletyPrecombatCdActions()
 unless not InCombat() and SubtletyPrecombatCdPostConditions()
 {
  SubtletyDefaultCdActions()
 }
}

### Required symbols
# shadowstrike
# deeper_stratagem_talent
# vanish_buff
# shadow_satyrs_walk
# master_assassins_initiative
# shuriken_storm
# shadowmeld_buff
# insignia_of_ravenholdt
# the_dreadlords_deceit_buff
# shadow_blades_buff
# mantle_of_the_master_assassin
# vanish
# shadow_dance
# symbols_of_death_buff
# symbols_of_death
# shadowmeld
# subterfuge_talent
# dark_shadow_talent
# the_first_of_the_dead_buff
# goremaws_bite
# feeding_frenzy_buff
# vigor_talent
# master_of_shadows_talent
# enveloping_shadows_talent
# stealth
# marked_for_death
# prolonged_power_potion
# nightblade
# shadow_dance_buff
# nightblade_debuff
# finality_nightblade_buff
# death_from_above_talent
# death_from_above
# finality_eviscerate_buff
# eviscerate
# shadow_blades
# blood_fury_ap
# berserking
# arcane_torrent_energy
# the_first_of_the_dead
# marked_for_death_talent
# shadow_focus_talent
# gloomblade
# backstab
# subterfuge_buff
# death_from_above_buff
# denial_of_the_halfgiants
# anticipation_talent
# kick
# shadowstep
]]
    OvaleScripts:RegisterScript("ROGUE", "subtlety", name, desc, code, "script")
end
