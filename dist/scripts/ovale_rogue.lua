local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_rogue_assassination"
    local desc = "[8.0] Simulationcraft: PR_Rogue_Assassination"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Assassination".
#	class=rogue
#	spec=assassination
#	talents=2210021

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * 7 / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } }
}

AddFunction use_filler
{
 ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() or Enemies() >= 2
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

### actions.stealthed

AddFunction AssassinationStealthedMainActions
{
 #rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&talent.exsanguinate.enabled&spell_targets.fan_of_knives<2|!ticking)&target.time_to_die-remains>6
 if ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and Enemies() < 2 or not target.DebuffPresent(rupture_debuff) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 Spell(rupture)
 #envenom,if=combo_points>=cp_max_spend
 if ComboPoints() >= MaxComboPoints() Spell(envenom)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&refreshable&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&remains<=10&pmultiplier<=1&!exsanguinated&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #pool_resource,for_next=1
 #garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&prev_gcd.1.rupture&dot.rupture.remains>5+4*cp_max_spend
 if Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() Spell(garrote)
}

AddFunction AssassinationStealthedMainPostConditions
{
}

AddFunction AssassinationStealthedShortCdActions
{
}

AddFunction AssassinationStealthedShortCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and Enemies() < 2 or not target.DebuffPresent(rupture_debuff) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or ComboPoints() >= MaxComboPoints() and Spell(envenom) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
}

AddFunction AssassinationStealthedCdActions
{
}

AddFunction AssassinationStealthedCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and Enemies() < 2 or not target.DebuffPresent(rupture_debuff) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or ComboPoints() >= MaxComboPoints() and Spell(envenom) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
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
  #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
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
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 }
}

AddFunction AssassinationPrecombatCdPostConditions
{
 Spell(stealth) or 600 > 40 and Spell(marked_for_death)
}

### actions.dot

AddFunction AssassinationDotMainActions
{
 #rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2)))
 if Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } Spell(rupture)
 #pool_resource,for_next=1
 #garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time)&(!exsanguinated|remains<=tick_time*2)&(target.time_to_die-remains>4&spell_targets.fan_of_knives<=1|target.time_to_die-remains>12)
 if { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } Spell(garrote)
 unless { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
 {
  #crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4
  if Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 Spell(crimson_tempest)
  #rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time)&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>4
  if ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 Spell(rupture)
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
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

AddFunction AssassinationDotCdActions
{
}

AddFunction AssassinationDotCdPostConditions
{
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

### actions.direct

AddFunction AssassinationDirectMainActions
{
 #envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|spell_targets.fan_of_knives>=2)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
 if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or Enemies() >= 2 } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } Spell(envenom)
 #variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|spell_targets.fan_of_knives>=2
 #poisoned_knife,if=variable.use_filler&buff.sharpened_blades.stack>=29&(azerite.sharpened_blades.rank>=2|spell_targets.fan_of_knives<=4)
 if use_filler() and BuffStacks(sharpened_blades_buff) >= 29 and { AzeriteTraitRank(sharpened_blades_trait) >= 2 or Enemies() <= 4 } Spell(poisoned_knife)
 #fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|spell_targets.fan_of_knives>=2+stealthed.rogue|buff.the_dreadlords_deceit.stack>=29)
 if use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 2 + Stealthed() or BuffStacks(the_dreadlords_deceit_assassination_buff) >= 29 } Spell(fan_of_knives)
 #blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled)
 if use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } Spell(blindside)
 #mutilate,if=variable.use_filler
 if use_filler() Spell(mutilate)
}

AddFunction AssassinationDirectMainPostConditions
{
}

AddFunction AssassinationDirectShortCdActions
{
}

AddFunction AssassinationDirectShortCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or Enemies() >= 2 } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and BuffStacks(sharpened_blades_buff) >= 29 and { AzeriteTraitRank(sharpened_blades_trait) >= 2 or Enemies() <= 4 } and Spell(poisoned_knife) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 2 + Stealthed() or BuffStacks(the_dreadlords_deceit_assassination_buff) >= 29 } and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } and Spell(blindside) or use_filler() and Spell(mutilate)
}

AddFunction AssassinationDirectCdActions
{
}

AddFunction AssassinationDirectCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or Enemies() >= 2 } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and BuffStacks(sharpened_blades_buff) >= 29 and { AzeriteTraitRank(sharpened_blades_trait) >= 2 or Enemies() <= 4 } and Spell(poisoned_knife) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 2 + Stealthed() or BuffStacks(the_dreadlords_deceit_assassination_buff) >= 29 } and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } and Spell(blindside) or use_filler() and Spell(mutilate)
}

### actions.cds

AddFunction AssassinationCdsMainActions
{
 #exsanguinate,if=dot.rupture.remains>4+4*cp_max_spend&!dot.garrote.refreshable
 if target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) Spell(exsanguinate)
 #toxic_blade,if=dot.rupture.ticking
 if target.DebuffPresent(rupture_debuff) Spell(toxic_blade)
}

AddFunction AssassinationCdsMainPostConditions
{
}

AddFunction AssassinationCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit*1.5|(raid_event.adds.in>40&combo_points.deficit>=cp_max_spend)
 if target.TimeToDie() < ComboPointsDeficit() * 1.5 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
 #vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&spell_targets.fan_of_knives<2)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1
 if Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Enemies() < 2 } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up
 if Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.subterfuge.enabled&(!talent.exsanguinate.enabled|spell_targets.fan_of_knives>=2)&!stealthed.rogue&cooldown.garrote.up&dot.garrote.refreshable&(spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives|spell_targets.fan_of_knives>=4&combo_points.deficit>=4)
 if Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or Enemies() >= 2 } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable
 if Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) Spell(vanish)
}

AddFunction AssassinationCdsShortCdPostConditions
{
 target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

AddFunction AssassinationCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|debuff.vendetta.up&cooldown.vanish.remains<5
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or target.DebuffPresent(vendetta_debuff) and SpellCooldown(vanish) < 5 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=galecallers_boon
 AssassinationUseItemActions()
 #blood_fury,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(blood_fury_ap)
 #berserking,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(berserking)
 #fireblood,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(fireblood)
 #ancestral_call,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(ancestral_call)

 unless { target.TimeToDie() < ComboPointsDeficit() * 1.5 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death)
 {
  #vendetta,if=dot.rupture.ticking
  if target.DebuffPresent(rupture_debuff) Spell(vendetta)
 }
}

AddFunction AssassinationCdsCdPostConditions
{
 { target.TimeToDie() < ComboPointsDeficit() * 1.5 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Enemies() < 2 } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or Enemies() >= 2 } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedMainActions()

 unless Stealthed() and AssassinationStealthedMainPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsMainActions()

  unless AssassinationCdsMainPostConditions()
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
 Stealthed() and AssassinationStealthedMainPostConditions() or AssassinationCdsMainPostConditions() or AssassinationDotMainPostConditions() or AssassinationDirectMainPostConditions()
}

AddFunction AssassinationDefaultShortCdActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedShortCdActions()

 unless Stealthed() and AssassinationStealthedShortCdPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsShortCdActions()

  unless AssassinationCdsShortCdPostConditions()
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

AddFunction AssassinationDefaultShortCdPostConditions
{
 Stealthed() and AssassinationStealthedShortCdPostConditions() or AssassinationCdsShortCdPostConditions() or AssassinationDotShortCdPostConditions() or AssassinationDirectShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedCdActions()

 unless Stealthed() and AssassinationStealthedCdPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsCdActions()

  unless AssassinationCdsCdPostConditions()
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
     if EnergyDeficit() >= 15 + energy_regen_combined() Spell(arcane_torrent_energy)
     #arcane_pulse
     Spell(arcane_pulse)
     #lights_judgment
     Spell(lights_judgment)
    }
   }
  }
 }
}

AddFunction AssassinationDefaultCdPostConditions
{
 Stealthed() and AssassinationStealthedCdPostConditions() or AssassinationCdsCdPostConditions() or AssassinationDotCdPostConditions() or AssassinationDirectCdPostConditions()
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
# ancestral_call
# arcane_pulse
# arcane_torrent_energy
# battle_potion_of_agility
# berserking
# blindside
# blindside_buff
# blood_fury_ap
# crimson_tempest
# crimson_tempest_debuff
# deeper_stratagem_talent
# envenom
# exsanguinate
# exsanguinate_talent
# exsanguinated
# fan_of_knives
# fireblood
# garrote
# garrote_debuff
# hidden_blades_buff
# internal_bleeding_debuff
# internal_bleeding_talent
# kick
# lights_judgment
# marked_for_death
# master_assassin_buff
# master_assassin_talent
# mutilate
# nightstalker_talent
# poisoned_knife
# rupture
# rupture_debuff
# shadowstep
# sharpened_blades_buff
# sharpened_blades_trait
# stealth
# subterfuge_talent
# the_dreadlords_deceit_assassination_buff
# toxic_blade
# toxic_blade_debuff
# vanish
# vendetta
# vendetta_debuff
# venom_rush_talent
]]
    OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
end
do
    local name = "sc_pr_rogue_assassination_exsg"
    local desc = "[8.0] Simulationcraft: PR_Rogue_Assassination_Exsg"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Assassination_Exsg".
#	class=rogue
#	spec=assassination
#	talents=2210031

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * 7 / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } }
}

AddFunction use_filler
{
 ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() or Enemies() >= 2
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

### actions.stealthed

AddFunction AssassinationStealthedMainActions
{
 #rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&talent.exsanguinate.enabled&spell_targets.fan_of_knives<2|!ticking)&target.time_to_die-remains>6
 if ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and Enemies() < 2 or not target.DebuffPresent(rupture_debuff) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 Spell(rupture)
 #envenom,if=combo_points>=cp_max_spend
 if ComboPoints() >= MaxComboPoints() Spell(envenom)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&refreshable&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&remains<=10&pmultiplier<=1&!exsanguinated&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #pool_resource,for_next=1
 #garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&prev_gcd.1.rupture&dot.rupture.remains>5+4*cp_max_spend
 if Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() Spell(garrote)
}

AddFunction AssassinationStealthedMainPostConditions
{
}

AddFunction AssassinationStealthedShortCdActions
{
}

AddFunction AssassinationStealthedShortCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and Enemies() < 2 or not target.DebuffPresent(rupture_debuff) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or ComboPoints() >= MaxComboPoints() and Spell(envenom) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
}

AddFunction AssassinationStealthedCdActions
{
}

AddFunction AssassinationStealthedCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and Enemies() < 2 or not target.DebuffPresent(rupture_debuff) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or ComboPoints() >= MaxComboPoints() and Spell(envenom) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and not target.DebuffPresent(exsanguinated) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
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
  #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
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
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 }
}

AddFunction AssassinationPrecombatCdPostConditions
{
 Spell(stealth) or 600 > 40 and Spell(marked_for_death)
}

### actions.dot

AddFunction AssassinationDotMainActions
{
 #rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2)))
 if Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } Spell(rupture)
 #pool_resource,for_next=1
 #garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time)&(!exsanguinated|remains<=tick_time*2)&(target.time_to_die-remains>4&spell_targets.fan_of_knives<=1|target.time_to_die-remains>12)
 if { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } Spell(garrote)
 unless { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
 {
  #crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4
  if Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 Spell(crimson_tempest)
  #rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time)&(!exsanguinated|remains<=tick_time*2)&target.time_to_die-remains>4
  if ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 Spell(rupture)
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
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

AddFunction AssassinationDotCdActions
{
}

AddFunction AssassinationDotCdPostConditions
{
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.TickTime(garrote_debuff) * 2 } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.TickTime(rupture_debuff) * 2 } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

### actions.direct

AddFunction AssassinationDirectMainActions
{
 #envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|spell_targets.fan_of_knives>=2)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
 if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or Enemies() >= 2 } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } Spell(envenom)
 #variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|spell_targets.fan_of_knives>=2
 #poisoned_knife,if=variable.use_filler&buff.sharpened_blades.stack>=29&(azerite.sharpened_blades.rank>=2|spell_targets.fan_of_knives<=4)
 if use_filler() and BuffStacks(sharpened_blades_buff) >= 29 and { AzeriteTraitRank(sharpened_blades_trait) >= 2 or Enemies() <= 4 } Spell(poisoned_knife)
 #fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|spell_targets.fan_of_knives>=2+stealthed.rogue|buff.the_dreadlords_deceit.stack>=29)
 if use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 2 + Stealthed() or BuffStacks(the_dreadlords_deceit_assassination_buff) >= 29 } Spell(fan_of_knives)
 #blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled)
 if use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } Spell(blindside)
 #mutilate,if=variable.use_filler
 if use_filler() Spell(mutilate)
}

AddFunction AssassinationDirectMainPostConditions
{
}

AddFunction AssassinationDirectShortCdActions
{
}

AddFunction AssassinationDirectShortCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or Enemies() >= 2 } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and BuffStacks(sharpened_blades_buff) >= 29 and { AzeriteTraitRank(sharpened_blades_trait) >= 2 or Enemies() <= 4 } and Spell(poisoned_knife) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 2 + Stealthed() or BuffStacks(the_dreadlords_deceit_assassination_buff) >= 29 } and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } and Spell(blindside) or use_filler() and Spell(mutilate)
}

AddFunction AssassinationDirectCdActions
{
}

AddFunction AssassinationDirectCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or Enemies() >= 2 } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and BuffStacks(sharpened_blades_buff) >= 29 and { AzeriteTraitRank(sharpened_blades_trait) >= 2 or Enemies() <= 4 } and Spell(poisoned_knife) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 2 + Stealthed() or BuffStacks(the_dreadlords_deceit_assassination_buff) >= 29 } and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } and Spell(blindside) or use_filler() and Spell(mutilate)
}

### actions.cds

AddFunction AssassinationCdsMainActions
{
 #exsanguinate,if=dot.rupture.remains>4+4*cp_max_spend&!dot.garrote.refreshable
 if target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) Spell(exsanguinate)
 #toxic_blade,if=dot.rupture.ticking
 if target.DebuffPresent(rupture_debuff) Spell(toxic_blade)
}

AddFunction AssassinationCdsMainPostConditions
{
}

AddFunction AssassinationCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit*1.5|(raid_event.adds.in>40&combo_points.deficit>=cp_max_spend)
 if target.TimeToDie() < ComboPointsDeficit() * 1.5 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
 #vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&spell_targets.fan_of_knives<2)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1
 if Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Enemies() < 2 } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up
 if Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.subterfuge.enabled&(!talent.exsanguinate.enabled|spell_targets.fan_of_knives>=2)&!stealthed.rogue&cooldown.garrote.up&dot.garrote.refreshable&(spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives|spell_targets.fan_of_knives>=4&combo_points.deficit>=4)
 if Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or Enemies() >= 2 } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable
 if Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) Spell(vanish)
}

AddFunction AssassinationCdsShortCdPostConditions
{
 target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

AddFunction AssassinationCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|debuff.vendetta.up&cooldown.vanish.remains<5
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or target.DebuffPresent(vendetta_debuff) and SpellCooldown(vanish) < 5 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=galecallers_boon
 AssassinationUseItemActions()
 #blood_fury,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(blood_fury_ap)
 #berserking,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(berserking)
 #fireblood,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(fireblood)
 #ancestral_call,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(ancestral_call)

 unless { target.TimeToDie() < ComboPointsDeficit() * 1.5 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death)
 {
  #vendetta,if=dot.rupture.ticking
  if target.DebuffPresent(rupture_debuff) Spell(vendetta)
 }
}

AddFunction AssassinationCdsCdPostConditions
{
 { target.TimeToDie() < ComboPointsDeficit() * 1.5 or 600 > 40 and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and Enemies() < 2 } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or Enemies() >= 2 } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedMainActions()

 unless Stealthed() and AssassinationStealthedMainPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsMainActions()

  unless AssassinationCdsMainPostConditions()
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
 Stealthed() and AssassinationStealthedMainPostConditions() or AssassinationCdsMainPostConditions() or AssassinationDotMainPostConditions() or AssassinationDirectMainPostConditions()
}

AddFunction AssassinationDefaultShortCdActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedShortCdActions()

 unless Stealthed() and AssassinationStealthedShortCdPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsShortCdActions()

  unless AssassinationCdsShortCdPostConditions()
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

AddFunction AssassinationDefaultShortCdPostConditions
{
 Stealthed() and AssassinationStealthedShortCdPostConditions() or AssassinationCdsShortCdPostConditions() or AssassinationDotShortCdPostConditions() or AssassinationDirectShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedCdActions()

 unless Stealthed() and AssassinationStealthedCdPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsCdActions()

  unless AssassinationCdsCdPostConditions()
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
     if EnergyDeficit() >= 15 + energy_regen_combined() Spell(arcane_torrent_energy)
     #arcane_pulse
     Spell(arcane_pulse)
     #lights_judgment
     Spell(lights_judgment)
    }
   }
  }
 }
}

AddFunction AssassinationDefaultCdPostConditions
{
 Stealthed() and AssassinationStealthedCdPostConditions() or AssassinationCdsCdPostConditions() or AssassinationDotCdPostConditions() or AssassinationDirectCdPostConditions()
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
# ancestral_call
# arcane_pulse
# arcane_torrent_energy
# battle_potion_of_agility
# berserking
# blindside
# blindside_buff
# blood_fury_ap
# crimson_tempest
# crimson_tempest_debuff
# deeper_stratagem_talent
# envenom
# exsanguinate
# exsanguinate_talent
# exsanguinated
# fan_of_knives
# fireblood
# garrote
# garrote_debuff
# hidden_blades_buff
# internal_bleeding_debuff
# internal_bleeding_talent
# kick
# lights_judgment
# marked_for_death
# master_assassin_buff
# master_assassin_talent
# mutilate
# nightstalker_talent
# poisoned_knife
# rupture
# rupture_debuff
# shadowstep
# sharpened_blades_buff
# sharpened_blades_trait
# stealth
# subterfuge_talent
# the_dreadlords_deceit_assassination_buff
# toxic_blade
# toxic_blade_debuff
# vanish
# vendetta
# vendetta_debuff
# venom_rush_talent
]]
    OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
end
do
    local name = "sc_pr_rogue_outlaw"
    local desc = "[8.0] Simulationcraft: PR_Rogue_Outlaw"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Outlaw".
#	class=rogue
#	spec=outlaw
#	talents=2310022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction blade_flurry_sync
{
 Enemies() < 2 and 600 > 20 or BuffPresent(blade_flurry_buff)
}

AddFunction ambush_condition
{
 ComboPointsDeficit() >= 2 + 2 * { Talent(ghostly_strike_talent) and SpellCooldown(ghostly_strike) < 1 } + BuffPresent(broadside_buff) and Energy() > 60 and not BuffPresent(skull_and_crossbones_buff)
}

AddFunction rtb_reroll
{
 BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or not BuffPresent(grand_melee_buff) and not BuffPresent(ruthless_precision_buff) }
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
 #ambush
 Spell(ambush)
}

AddFunction OutlawStealthMainPostConditions
{
}

AddFunction OutlawStealthShortCdActions
{
}

AddFunction OutlawStealthShortCdPostConditions
{
 Spell(ambush)
}

AddFunction OutlawStealthCdActions
{
}

AddFunction OutlawStealthCdPostConditions
{
 Spell(ambush)
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
 #roll_the_bones,precombat_seconds=2
 Spell(roll_the_bones)
 #slice_and_dice,precombat_seconds=2
 Spell(slice_and_dice)
}

AddFunction OutlawPrecombatMainPostConditions
{
}

AddFunction OutlawPrecombatShortCdActions
{
 unless Spell(stealth)
 {
  #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
  if 600 > 40 Spell(marked_for_death)
 }
}

AddFunction OutlawPrecombatShortCdPostConditions
{
 Spell(stealth) or Spell(roll_the_bones) or Spell(slice_and_dice)
}

AddFunction OutlawPrecombatCdActions
{
 unless Spell(stealth)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)

  unless 600 > 40 and Spell(marked_for_death) or Spell(roll_the_bones) or Spell(slice_and_dice)
  {
   #adrenaline_rush,precombat_seconds=1
   if EnergyDeficit() > 1 Spell(adrenaline_rush)
  }
 }
}

AddFunction OutlawPrecombatCdPostConditions
{
 Spell(stealth) or 600 > 40 and Spell(marked_for_death) or Spell(roll_the_bones) or Spell(slice_and_dice)
}

### actions.finish

AddFunction OutlawFinishMainActions
{
 #slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
 if BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 Spell(slice_and_dice)
 #roll_the_bones,if=(buff.roll_the_bones.remains<=3|variable.rtb_reroll)&(target.time_to_die>20|buff.roll_the_bones.remains<target.time_to_die)
 if { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } Spell(roll_the_bones)
 #dispatch
 Spell(dispatch)
}

AddFunction OutlawFinishMainPostConditions
{
}

AddFunction OutlawFinishShortCdActions
{
 #between_the_eyes,if=azerite.deadshot.rank>=2&buff.roll_the_bones.up
 if AzeriteTraitRank(deadshot_trait) >= 2 and DebuffPresent(roll_the_bones) Spell(between_the_eyes text=BTE)

 unless BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and Spell(roll_the_bones)
 {
  #between_the_eyes,if=buff.ruthless_precision.up|azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
  if BuffPresent(ruthless_precision_buff) or HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) Spell(between_the_eyes text=BTE)
 }
}

AddFunction OutlawFinishShortCdPostConditions
{
 BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and Spell(roll_the_bones) or Spell(dispatch)
}

AddFunction OutlawFinishCdActions
{
}

AddFunction OutlawFinishCdPostConditions
{
 AzeriteTraitRank(deadshot_trait) >= 2 and DebuffPresent(roll_the_bones) and Spell(between_the_eyes text=BTE) or BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and Spell(roll_the_bones) or { BuffPresent(ruthless_precision_buff) or HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) } and Spell(between_the_eyes text=BTE) or Spell(dispatch)
}

### actions.cds

AddFunction OutlawCdsMainActions
{
 #blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|cooldown.blade_flurry.charges=1&raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
 if Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) Spell(blade_flurry)
}

AddFunction OutlawCdsMainPostConditions
{
}

AddFunction OutlawCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit|((raid_event.adds.in>40|buff.true_bearing.remains>15-buff.adrenaline_rush.up*5)&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
 if target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 Spell(marked_for_death)

 unless Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
 {
  #ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up
  if blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) Spell(ghostly_strike)
  #blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1
  if blade_flurry_sync() and TimeToMaxEnergy() > 1 Spell(blade_rush)
  #vanish,if=!stealthed.all&variable.ambush_condition
  if not Stealthed() and ambush_condition() Spell(vanish)
 }
}

AddFunction OutlawCdsShortCdPostConditions
{
 Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
}

AddFunction OutlawCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|buff.adrenaline_rush.up
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or BuffPresent(adrenaline_rush_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=lustrous_golden_plumage,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
 if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 20 or ComboPointsDeficit() <= 2 OutlawUseItemActions()
 #blood_fury
 Spell(blood_fury_ap)
 #berserking
 Spell(berserking)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)
 #adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1
 if not BuffPresent(adrenaline_rush_buff) and TimeToMaxEnergy() > 1 and EnergyDeficit() > 1 Spell(adrenaline_rush)

 unless { target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
 {
  #killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
  if blade_flurry_sync() and { TimeToMaxEnergy() > 5 or Energy() < 15 } Spell(killing_spree)

  unless blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush) or not Stealthed() and ambush_condition() and Spell(vanish)
  {
   #shadowmeld,if=!stealthed.all&variable.ambush_condition
   if not Stealthed() and ambush_condition() Spell(shadowmeld)
  }
 }
}

AddFunction OutlawCdsCdPostConditions
{
 { target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike) or blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush) or not Stealthed() and ambush_condition() and Spell(vanish)
}

### actions.build

AddFunction OutlawBuildMainActions
{
 #pistol_shot,if=combo_points.deficit>=1+buff.broadside.up+talent.quick_draw.enabled&buff.opportunity.up
 if ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) Spell(pistol_shot text=PS)
 #sinister_strike
 Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildMainPostConditions
{
}

AddFunction OutlawBuildShortCdActions
{
}

AddFunction OutlawBuildShortCdPostConditions
{
 ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) and Spell(pistol_shot text=PS) or Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildCdActions
{
}

AddFunction OutlawBuildCdPostConditions
{
 ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) and Spell(pistol_shot text=PS) or Spell(sinister_strike_outlaw)
}

### actions.default

AddFunction OutlawDefaultMainActions
{
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthMainActions()

 unless Stealthed() and OutlawStealthMainPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsMainActions()

  unless OutlawCdsMainPostConditions()
  {
   #call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishMainActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishMainPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildMainActions()
   }
  }
 }
}

AddFunction OutlawDefaultMainPostConditions
{
 Stealthed() and OutlawStealthMainPostConditions() or OutlawCdsMainPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishMainPostConditions() or OutlawBuildMainPostConditions()
}

AddFunction OutlawDefaultShortCdActions
{
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthShortCdActions()

 unless Stealthed() and OutlawStealthShortCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsShortCdActions()

  unless OutlawCdsShortCdPostConditions()
  {
   #call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishShortCdActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishShortCdPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildShortCdActions()
   }
  }
 }
}

AddFunction OutlawDefaultShortCdPostConditions
{
 Stealthed() and OutlawStealthShortCdPostConditions() or OutlawCdsShortCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishShortCdPostConditions() or OutlawBuildShortCdPostConditions()
}

AddFunction OutlawDefaultCdActions
{
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthCdActions()

 unless Stealthed() and OutlawStealthCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsCdActions()

  unless OutlawCdsCdPostConditions()
  {
   #call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishCdActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishCdPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildCdActions()

    unless OutlawBuildCdPostConditions()
    {
     #arcane_torrent,if=energy.deficit>=15+energy.regen
     if EnergyDeficit() >= 15 + EnergyRegenRate() Spell(arcane_torrent_energy)
     #arcane_pulse
     Spell(arcane_pulse)
     #lights_judgment
     Spell(lights_judgment)
    }
   }
  }
 }
}

AddFunction OutlawDefaultCdPostConditions
{
 Stealthed() and OutlawStealthCdPostConditions() or OutlawCdsCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishCdPostConditions() or OutlawBuildCdPostConditions()
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
# ace_up_your_sleeve_trait
# adrenaline_rush
# adrenaline_rush_buff
# ambush
# ancestral_call
# arcane_pulse
# arcane_torrent_energy
# battle_potion_of_agility
# berserking
# between_the_eyes
# blade_flurry
# blade_flurry_buff
# blade_rush
# blood_fury_ap
# broadside_buff
# deadshot_trait
# dispatch
# fireblood
# ghostly_strike
# ghostly_strike_talent
# grand_melee_buff
# kick
# killing_spree
# lights_judgment
# loaded_dice_buff
# marked_for_death
# marked_for_death_talent
# opportunity_buff
# pistol_shot
# quick_draw_talent
# roll_the_bones
# roll_the_bones_buff
# ruthless_precision_buff
# shadowmeld
# shadowstep
# sinister_strike_outlaw
# skull_and_crossbones_buff
# slice_and_dice
# slice_and_dice_buff
# stealth
# true_bearing_buff
# vanish
]]
    OvaleScripts:RegisterScript("ROGUE", "outlaw", name, desc, code, "script")
end
do
    local name = "sc_pr_rogue_outlaw_snd"
    local desc = "[8.0] Simulationcraft: PR_Rogue_Outlaw_SnD"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Outlaw_SnD".
#	class=rogue
#	spec=outlaw
#	talents=2310032

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction blade_flurry_sync
{
 Enemies() < 2 and 600 > 20 or BuffPresent(blade_flurry_buff)
}

AddFunction ambush_condition
{
 ComboPointsDeficit() >= 2 + 2 * { Talent(ghostly_strike_talent) and SpellCooldown(ghostly_strike) < 1 } + BuffPresent(broadside_buff) and Energy() > 60 and not BuffPresent(skull_and_crossbones_buff)
}

AddFunction rtb_reroll
{
 BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or not BuffPresent(grand_melee_buff) and not BuffPresent(ruthless_precision_buff) }
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
 #ambush
 Spell(ambush)
}

AddFunction OutlawStealthMainPostConditions
{
}

AddFunction OutlawStealthShortCdActions
{
}

AddFunction OutlawStealthShortCdPostConditions
{
 Spell(ambush)
}

AddFunction OutlawStealthCdActions
{
}

AddFunction OutlawStealthCdPostConditions
{
 Spell(ambush)
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
 #roll_the_bones,precombat_seconds=2
 Spell(roll_the_bones)
 #slice_and_dice,precombat_seconds=2
 Spell(slice_and_dice)
}

AddFunction OutlawPrecombatMainPostConditions
{
}

AddFunction OutlawPrecombatShortCdActions
{
 unless Spell(stealth)
 {
  #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
  if 600 > 40 Spell(marked_for_death)
 }
}

AddFunction OutlawPrecombatShortCdPostConditions
{
 Spell(stealth) or Spell(roll_the_bones) or Spell(slice_and_dice)
}

AddFunction OutlawPrecombatCdActions
{
 unless Spell(stealth)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)

  unless 600 > 40 and Spell(marked_for_death) or Spell(roll_the_bones) or Spell(slice_and_dice)
  {
   #adrenaline_rush,precombat_seconds=1
   if EnergyDeficit() > 1 Spell(adrenaline_rush)
  }
 }
}

AddFunction OutlawPrecombatCdPostConditions
{
 Spell(stealth) or 600 > 40 and Spell(marked_for_death) or Spell(roll_the_bones) or Spell(slice_and_dice)
}

### actions.finish

AddFunction OutlawFinishMainActions
{
 #slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
 if BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 Spell(slice_and_dice)
 #roll_the_bones,if=(buff.roll_the_bones.remains<=3|variable.rtb_reroll)&(target.time_to_die>20|buff.roll_the_bones.remains<target.time_to_die)
 if { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } Spell(roll_the_bones)
 #dispatch
 Spell(dispatch)
}

AddFunction OutlawFinishMainPostConditions
{
}

AddFunction OutlawFinishShortCdActions
{
 #between_the_eyes,if=azerite.deadshot.rank>=2&buff.roll_the_bones.up
 if AzeriteTraitRank(deadshot_trait) >= 2 and DebuffPresent(roll_the_bones) Spell(between_the_eyes text=BTE)

 unless BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and Spell(roll_the_bones)
 {
  #between_the_eyes,if=buff.ruthless_precision.up|azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
  if BuffPresent(ruthless_precision_buff) or HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) Spell(between_the_eyes text=BTE)
 }
}

AddFunction OutlawFinishShortCdPostConditions
{
 BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and Spell(roll_the_bones) or Spell(dispatch)
}

AddFunction OutlawFinishCdActions
{
}

AddFunction OutlawFinishCdPostConditions
{
 AzeriteTraitRank(deadshot_trait) >= 2 and DebuffPresent(roll_the_bones) and Spell(between_the_eyes text=BTE) or BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and { target.TimeToDie() > 20 or BuffRemaining(roll_the_bones_buff) < target.TimeToDie() } and Spell(roll_the_bones) or { BuffPresent(ruthless_precision_buff) or HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) } and Spell(between_the_eyes text=BTE) or Spell(dispatch)
}

### actions.cds

AddFunction OutlawCdsMainActions
{
 #blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|cooldown.blade_flurry.charges=1&raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
 if Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) Spell(blade_flurry)
}

AddFunction OutlawCdsMainPostConditions
{
}

AddFunction OutlawCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit|((raid_event.adds.in>40|buff.true_bearing.remains>15-buff.adrenaline_rush.up*5)&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
 if target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 Spell(marked_for_death)

 unless Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
 {
  #ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up
  if blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) Spell(ghostly_strike)
  #blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1
  if blade_flurry_sync() and TimeToMaxEnergy() > 1 Spell(blade_rush)
  #vanish,if=!stealthed.all&variable.ambush_condition
  if not Stealthed() and ambush_condition() Spell(vanish)
 }
}

AddFunction OutlawCdsShortCdPostConditions
{
 Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
}

AddFunction OutlawCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|buff.adrenaline_rush.up
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or BuffPresent(adrenaline_rush_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=galecallers_boon,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
 if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 20 or ComboPointsDeficit() <= 2 OutlawUseItemActions()
 #use_item,name=lustrous_golden_plumage,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
 if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 20 or ComboPointsDeficit() <= 2 OutlawUseItemActions()
 #blood_fury
 Spell(blood_fury_ap)
 #berserking
 Spell(berserking)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)
 #adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1
 if not BuffPresent(adrenaline_rush_buff) and TimeToMaxEnergy() > 1 and EnergyDeficit() > 1 Spell(adrenaline_rush)

 unless { target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
 {
  #killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
  if blade_flurry_sync() and { TimeToMaxEnergy() > 5 or Energy() < 15 } Spell(killing_spree)

  unless blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush) or not Stealthed() and ambush_condition() and Spell(vanish)
  {
   #shadowmeld,if=!stealthed.all&variable.ambush_condition
   if not Stealthed() and ambush_condition() Spell(shadowmeld)
  }
 }
}

AddFunction OutlawCdsCdPostConditions
{
 { target.TimeToDie() < ComboPointsDeficit() or { 600 > 40 or BuffRemaining(true_bearing_buff) > 15 - BuffPresent(adrenaline_rush_buff) * 5 } and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or SpellCharges(blade_flurry) == 1 and 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike) or blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush) or not Stealthed() and ambush_condition() and Spell(vanish)
}

### actions.build

AddFunction OutlawBuildMainActions
{
 #pistol_shot,if=combo_points.deficit>=1+buff.broadside.up+talent.quick_draw.enabled&buff.opportunity.up
 if ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) Spell(pistol_shot text=PS)
 #sinister_strike
 Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildMainPostConditions
{
}

AddFunction OutlawBuildShortCdActions
{
}

AddFunction OutlawBuildShortCdPostConditions
{
 ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) and Spell(pistol_shot text=PS) or Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildCdActions
{
}

AddFunction OutlawBuildCdPostConditions
{
 ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) and Spell(pistol_shot text=PS) or Spell(sinister_strike_outlaw)
}

### actions.default

AddFunction OutlawDefaultMainActions
{
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthMainActions()

 unless Stealthed() and OutlawStealthMainPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsMainActions()

  unless OutlawCdsMainPostConditions()
  {
   #call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishMainActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishMainPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildMainActions()
   }
  }
 }
}

AddFunction OutlawDefaultMainPostConditions
{
 Stealthed() and OutlawStealthMainPostConditions() or OutlawCdsMainPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishMainPostConditions() or OutlawBuildMainPostConditions()
}

AddFunction OutlawDefaultShortCdActions
{
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthShortCdActions()

 unless Stealthed() and OutlawStealthShortCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsShortCdActions()

  unless OutlawCdsShortCdPostConditions()
  {
   #call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishShortCdActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishShortCdPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildShortCdActions()
   }
  }
 }
}

AddFunction OutlawDefaultShortCdPostConditions
{
 Stealthed() and OutlawStealthShortCdPostConditions() or OutlawCdsShortCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishShortCdPostConditions() or OutlawBuildShortCdPostConditions()
}

AddFunction OutlawDefaultCdActions
{
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthCdActions()

 unless Stealthed() and OutlawStealthCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsCdActions()

  unless OutlawCdsCdPostConditions()
  {
   #call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishCdActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishCdPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildCdActions()

    unless OutlawBuildCdPostConditions()
    {
     #arcane_torrent,if=energy.deficit>=15+energy.regen
     if EnergyDeficit() >= 15 + EnergyRegenRate() Spell(arcane_torrent_energy)
     #arcane_pulse
     Spell(arcane_pulse)
     #lights_judgment
     Spell(lights_judgment)
    }
   }
  }
 }
}

AddFunction OutlawDefaultCdPostConditions
{
 Stealthed() and OutlawStealthCdPostConditions() or OutlawCdsCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishCdPostConditions() or OutlawBuildCdPostConditions()
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
# ace_up_your_sleeve_trait
# adrenaline_rush
# adrenaline_rush_buff
# ambush
# ancestral_call
# arcane_pulse
# arcane_torrent_energy
# battle_potion_of_agility
# berserking
# between_the_eyes
# blade_flurry
# blade_flurry_buff
# blade_rush
# blood_fury_ap
# broadside_buff
# deadshot_trait
# dispatch
# fireblood
# ghostly_strike
# ghostly_strike_talent
# grand_melee_buff
# kick
# killing_spree
# lights_judgment
# loaded_dice_buff
# marked_for_death
# marked_for_death_talent
# opportunity_buff
# pistol_shot
# quick_draw_talent
# roll_the_bones
# roll_the_bones_buff
# ruthless_precision_buff
# shadowmeld
# shadowstep
# sinister_strike_outlaw
# skull_and_crossbones_buff
# slice_and_dice
# slice_and_dice_buff
# stealth
# true_bearing_buff
# vanish
]]
    OvaleScripts:RegisterScript("ROGUE", "outlaw", name, desc, code, "script")
end
do
    local name = "sc_pr_rogue_subtlety"
    local desc = "[8.0] Simulationcraft: PR_Rogue_Subtlety"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Subtlety".
#	class=rogue
#	spec=subtlety
#	talents=2330031

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction stealth_threshold
{
 60 + TalentPoints(vigor_talent) * 35 + TalentPoints(master_of_shadows_talent) * 10
}

AddFunction shd_threshold
{
 SpellCharges(shadow_dance count=0) >= 1.75
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
 #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&buff.vanish.up)
 if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } SubtletyFinishMainActions()

 unless ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and SubtletyFinishMainPostConditions()
 {
  #shadowstrike,cycle_targets=1,if=talent.secret_technique.enabled&talent.find_weakness.enabled&debuff.find_weakness.remains<1&spell_targets.shuriken_storm=2&target.time_to_die-remains>6
  if Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies() == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 Spell(shadowstrike)
  #shuriken_storm,if=spell_targets>=3
  if Enemies() >= 3 Spell(shuriken_storm)
  #shadowstrike
  Spell(shadowstrike)
 }
}

AddFunction SubtletyStealthedMainPostConditions
{
 ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and SubtletyFinishMainPostConditions()
}

AddFunction SubtletyStealthedShortCdActions
{
 unless BuffPresent(stealthed_buff any=1) and Spell(shadowstrike)
 {
  #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&buff.vanish.up)
  if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } SubtletyFinishShortCdActions()
 }
}

AddFunction SubtletyStealthedShortCdPostConditions
{
 BuffPresent(stealthed_buff any=1) and Spell(shadowstrike) or ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and SubtletyFinishShortCdPostConditions() or Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies() == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 and Spell(shadowstrike) or Enemies() >= 3 and Spell(shuriken_storm) or Spell(shadowstrike)
}

AddFunction SubtletyStealthedCdActions
{
 unless BuffPresent(stealthed_buff any=1) and Spell(shadowstrike)
 {
  #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&buff.vanish.up)
  if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } SubtletyFinishCdActions()
 }
}

AddFunction SubtletyStealthedCdPostConditions
{
 BuffPresent(stealthed_buff any=1) and Spell(shadowstrike) or ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and BuffPresent(vanish_buff) } and SubtletyFinishCdPostConditions() or Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies() == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 and Spell(shadowstrike) or Enemies() >= 3 and Spell(shuriken_storm) or Spell(shadowstrike)
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
 #vanish,if=!variable.shd_threshold&debuff.find_weakness.remains<1
 if not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 Spell(vanish)
 #pool_resource,for_next=1,extra_amount=40
 #shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&debuff.find_weakness.remains<1
 unless True(pool_energy 40) and EnergyDeficit() >= 10 and not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(40)
 {
  #shadow_dance,if=(!talent.dark_shadow.enabled|dot.nightblade.remains>=5+talent.subterfuge.enabled)&(variable.shd_threshold|buff.symbols_of_death.remains>=1.2|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10)
  if { not Talent(dark_shadow_talent) or target.DebuffRemaining(nightblade_debuff) >= 5 + TalentPoints(subterfuge_talent) } and { shd_threshold() or BuffRemaining(symbols_of_death_buff) >= 1.2 or Enemies() >= 4 and SpellCooldown(symbols_of_death) > 10 } Spell(shadow_dance)
  #shadow_dance,if=target.time_to_die<cooldown.symbols_of_death.remains
  if target.TimeToDie() < SpellCooldown(symbols_of_death) Spell(shadow_dance)
 }
}

AddFunction SubtletyStealthcdsShortCdPostConditions
{
}

AddFunction SubtletyStealthcdsCdActions
{
 unless not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and Spell(vanish)
 {
  #pool_resource,for_next=1,extra_amount=40
  #shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&debuff.find_weakness.remains<1
  if Energy() >= 40 and EnergyDeficit() >= 10 and not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 Spell(shadowmeld)
 }
}

AddFunction SubtletyStealthcdsCdPostConditions
{
 not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and Spell(vanish) or not { True(pool_energy 40) and EnergyDeficit() >= 10 and not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(40) } and { { not Talent(dark_shadow_talent) or target.DebuffRemaining(nightblade_debuff) >= 5 + TalentPoints(subterfuge_talent) } and { shd_threshold() or BuffRemaining(symbols_of_death_buff) >= 1.2 or Enemies() >= 4 and SpellCooldown(symbols_of_death) > 10 } and Spell(shadow_dance) or target.TimeToDie() < SpellCooldown(symbols_of_death) and Spell(shadow_dance) }
}

### actions.precombat

AddFunction SubtletyPrecombatMainActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #variable,name=stealth_threshold,value=60+talent.vigor.enabled*35+talent.master_of_shadows.enabled*10
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
  #marked_for_death,precombat_seconds=15
  Spell(marked_for_death)
 }
}

AddFunction SubtletyPrecombatShortCdPostConditions
{
 Spell(stealth)
}

AddFunction SubtletyPrecombatCdActions
{
 unless Spell(stealth) or Spell(marked_for_death)
 {
  #shadow_blades,precombat_seconds=1
  Spell(shadow_blades)
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 }
}

AddFunction SubtletyPrecombatCdPostConditions
{
 Spell(stealth) or Spell(marked_for_death)
}

### actions.finish

AddFunction SubtletyFinishMainActions
{
 #nightblade,if=(!talent.dark_shadow.enabled|!buff.shadow_dance.up)&target.time_to_die-remains>6&remains<tick_time*2&(spell_targets.shuriken_storm<4|!buff.symbols_of_death.up)
 if { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 and { Enemies() < 4 or not BuffPresent(symbols_of_death_buff) } Spell(nightblade)
 #nightblade,cycle_targets=1,if=spell_targets.shuriken_storm>=2&(spell_targets.shuriken_storm<=5|talent.secret_technique.enabled)&!buff.shadow_dance.up&target.time_to_die>=(5+(2*combo_points))&refreshable
 if Enemies() >= 2 and { Enemies() <= 5 or Talent(secret_technique_talent) } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) Spell(nightblade)
 #nightblade,if=remains<cooldown.symbols_of_death.remains+10&cooldown.symbols_of_death.remains<=5&target.time_to_die-remains>cooldown.symbols_of_death.remains+5
 if target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 Spell(nightblade)
 #eviscerate
 Spell(eviscerate)
}

AddFunction SubtletyFinishMainPostConditions
{
}

AddFunction SubtletyFinishShortCdActions
{
 unless { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 and { Enemies() < 4 or not BuffPresent(symbols_of_death_buff) } and Spell(nightblade) or Enemies() >= 2 and { Enemies() <= 5 or Talent(secret_technique_talent) } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade)
 {
  #secret_technique,if=buff.symbols_of_death.up&(!talent.dark_shadow.enabled|spell_targets.shuriken_storm<2|buff.shadow_dance.up)
  if BuffPresent(symbols_of_death_buff) and { not Talent(dark_shadow_talent) or Enemies() < 2 or BuffPresent(shadow_dance_buff) } Spell(secret_technique)
  #secret_technique,if=spell_targets.shuriken_storm>=2+talent.dark_shadow.enabled+talent.nightstalker.enabled
  if Enemies() >= 2 + TalentPoints(dark_shadow_talent) + TalentPoints(nightstalker_talent) Spell(secret_technique)
 }
}

AddFunction SubtletyFinishShortCdPostConditions
{
 { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 and { Enemies() < 4 or not BuffPresent(symbols_of_death_buff) } and Spell(nightblade) or Enemies() >= 2 and { Enemies() <= 5 or Talent(secret_technique_talent) } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade) or Spell(eviscerate)
}

AddFunction SubtletyFinishCdActions
{
}

AddFunction SubtletyFinishCdPostConditions
{
 { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.TickTime(nightblade_debuff) * 2 and { Enemies() < 4 or not BuffPresent(symbols_of_death_buff) } and Spell(nightblade) or Enemies() >= 2 and { Enemies() <= 5 or Talent(secret_technique_talent) } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade) or BuffPresent(symbols_of_death_buff) and { not Talent(dark_shadow_talent) or Enemies() < 2 or BuffPresent(shadow_dance_buff) } and Spell(secret_technique) or Enemies() >= 2 + TalentPoints(dark_shadow_talent) + TalentPoints(nightstalker_talent) and Spell(secret_technique) or Spell(eviscerate)
}

### actions.cds

AddFunction SubtletyCdsMainActions
{
}

AddFunction SubtletyCdsMainPostConditions
{
}

AddFunction SubtletyCdsShortCdActions
{
 #symbols_of_death,if=dot.nightblade.ticking
 if target.DebuffPresent(nightblade_debuff) Spell(symbols_of_death)
 #marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit
 if target.TimeToDie() < ComboPointsDeficit() Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30&!stealthed.all&combo_points.deficit>=cp_max_spend
 if 600 > 30 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
 #shuriken_tornado,if=spell_targets>=3&dot.nightblade.ticking&buff.symbols_of_death.up&buff.shadow_dance.up
 if Enemies() >= 3 and target.DebuffPresent(nightblade_debuff) and BuffPresent(symbols_of_death_buff) and BuffPresent(shadow_dance_buff) Spell(shuriken_tornado)
 #shadow_dance,if=!buff.shadow_dance.up&target.time_to_die<=5+talent.subterfuge.enabled
 if not BuffPresent(shadow_dance_buff) and target.TimeToDie() <= 5 + TalentPoints(subterfuge_talent) Spell(shadow_dance)
}

AddFunction SubtletyCdsShortCdPostConditions
{
}

AddFunction SubtletyCdsCdActions
{
 #potion,if=buff.bloodlust.react|target.time_to_die<=60|(buff.vanish.up&(buff.shadow_blades.up|cooldown.shadow_blades.remains<=30))
 if { BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 60 or BuffPresent(vanish_buff) and { BuffPresent(shadow_blades_buff) or SpellCooldown(shadow_blades) <= 30 } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #blood_fury,if=stealthed.rogue
 if Stealthed() Spell(blood_fury_ap)
 #berserking,if=stealthed.rogue
 if Stealthed() Spell(berserking)
 #fireblood,if=stealthed.rogue
 if Stealthed() Spell(fireblood)
 #ancestral_call,if=stealthed.rogue
 if Stealthed() Spell(ancestral_call)

 unless target.DebuffPresent(nightblade_debuff) and Spell(symbols_of_death) or target.TimeToDie() < ComboPointsDeficit() and Spell(marked_for_death) or 600 > 30 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death)
 {
  #shadow_blades,if=combo_points.deficit>=2+stealthed.all
  if ComboPointsDeficit() >= 2 + Stealthed() Spell(shadow_blades)
 }
}

AddFunction SubtletyCdsCdPostConditions
{
 target.DebuffPresent(nightblade_debuff) and Spell(symbols_of_death) or target.TimeToDie() < ComboPointsDeficit() and Spell(marked_for_death) or 600 > 30 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death) or Enemies() >= 3 and target.DebuffPresent(nightblade_debuff) and BuffPresent(symbols_of_death_buff) and BuffPresent(shadow_dance_buff) and Spell(shuriken_tornado) or not BuffPresent(shadow_dance_buff) and target.TimeToDie() <= 5 + TalentPoints(subterfuge_talent) and Spell(shadow_dance)
}

### actions.build

AddFunction SubtletyBuildMainActions
{
 #shuriken_toss,if=buff.sharpened_blades.stack>=29&spell_targets.shuriken_storm<=1+3*(azerite.sharpened_blades.rank=2)+4*(azerite.sharpened_blades.rank=3)
 if BuffStacks(sharpened_blades_buff) >= 29 and Enemies() <= 1 + 3 * { AzeriteTraitRank(sharpened_blades_trait) == 2 } + 4 * { AzeriteTraitRank(sharpened_blades_trait) == 3 } Spell(shuriken_toss)
 #shuriken_storm,if=spell_targets>=2|buff.the_dreadlords_deceit.stack>=29
 if Enemies() >= 2 or BuffStacks(the_dreadlords_deceit_subtlety_buff) >= 29 Spell(shuriken_storm)
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
 BuffStacks(sharpened_blades_buff) >= 29 and Enemies() <= 1 + 3 * { AzeriteTraitRank(sharpened_blades_trait) == 2 } + 4 * { AzeriteTraitRank(sharpened_blades_trait) == 3 } and Spell(shuriken_toss) or { Enemies() >= 2 or BuffStacks(the_dreadlords_deceit_subtlety_buff) >= 29 } and Spell(shuriken_storm) or Spell(gloomblade) or Spell(backstab)
}

AddFunction SubtletyBuildCdActions
{
}

AddFunction SubtletyBuildCdPostConditions
{
 BuffStacks(sharpened_blades_buff) >= 29 and Enemies() <= 1 + 3 * { AzeriteTraitRank(sharpened_blades_trait) == 2 } + 4 * { AzeriteTraitRank(sharpened_blades_trait) == 3 } and Spell(shuriken_toss) or { Enemies() >= 2 or BuffStacks(the_dreadlords_deceit_subtlety_buff) >= 29 } and Spell(shuriken_storm) or Spell(gloomblade) or Spell(backstab)
}

### actions.default

AddFunction SubtletyDefaultMainActions
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
   #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
   if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthcdsMainActions()

   unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsMainPostConditions()
   {
    #call_action_list,name=finish,if=combo_points>=4+talent.deeper_stratagem.enabled|target.time_to_die<=1&combo_points>=3
    if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishMainActions()

    unless { ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishMainPostConditions()
    {
     #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
     if Enemies() == 4 and ComboPoints() >= 4 SubtletyFinishMainActions()

     unless Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishMainPostConditions()
     {
      #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold-40*!(talent.alacrity.enabled|talent.shadow_focus.enabled|talent.master_of_shadows.enabled)
      if EnergyDeficit() <= stealth_threshold() - 40 * { not { Talent(alacrity_talent) or Talent(shadow_focus_talent) or Talent(master_of_shadows_talent) } } SubtletyBuildMainActions()
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultMainPostConditions
{
 SubtletyCdsMainPostConditions() or Stealthed() and SubtletyStealthedMainPostConditions() or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsMainPostConditions() or { ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishMainPostConditions() or Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishMainPostConditions() or EnergyDeficit() <= stealth_threshold() - 40 * { not { Talent(alacrity_talent) or Talent(shadow_focus_talent) or Talent(master_of_shadows_talent) } } and SubtletyBuildMainPostConditions()
}

AddFunction SubtletyDefaultShortCdActions
{
 #call_action_list,name=cds
 SubtletyCdsShortCdActions()

 unless SubtletyCdsShortCdPostConditions()
 {
  #run_action_list,name=stealthed,if=stealthed.all
  if Stealthed() SubtletyStealthedShortCdActions()

  unless Stealthed() and SubtletyStealthedShortCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade)
  {
   #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
   if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthcdsShortCdActions()

   unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsShortCdPostConditions()
   {
    #call_action_list,name=finish,if=combo_points>=4+talent.deeper_stratagem.enabled|target.time_to_die<=1&combo_points>=3
    if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishShortCdActions()

    unless { ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishShortCdPostConditions()
    {
     #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
     if Enemies() == 4 and ComboPoints() >= 4 SubtletyFinishShortCdActions()

     unless Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishShortCdPostConditions()
     {
      #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold-40*!(talent.alacrity.enabled|talent.shadow_focus.enabled|talent.master_of_shadows.enabled)
      if EnergyDeficit() <= stealth_threshold() - 40 * { not { Talent(alacrity_talent) or Talent(shadow_focus_talent) or Talent(master_of_shadows_talent) } } SubtletyBuildShortCdActions()
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultShortCdPostConditions
{
 SubtletyCdsShortCdPostConditions() or Stealthed() and SubtletyStealthedShortCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade) or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsShortCdPostConditions() or { ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishShortCdPostConditions() or Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishShortCdPostConditions() or EnergyDeficit() <= stealth_threshold() - 40 * { not { Talent(alacrity_talent) or Talent(shadow_focus_talent) or Talent(master_of_shadows_talent) } } and SubtletyBuildShortCdPostConditions()
}

AddFunction SubtletyDefaultCdActions
{
 #call_action_list,name=cds
 SubtletyCdsCdActions()

 unless SubtletyCdsCdPostConditions()
 {
  #run_action_list,name=stealthed,if=stealthed.all
  if Stealthed() SubtletyStealthedCdActions()

  unless Stealthed() and SubtletyStealthedCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade)
  {
   #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
   if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthcdsCdActions()

   unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsCdPostConditions()
   {
    #call_action_list,name=finish,if=combo_points>=4+talent.deeper_stratagem.enabled|target.time_to_die<=1&combo_points>=3
    if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishCdActions()

    unless { ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishCdPostConditions()
    {
     #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
     if Enemies() == 4 and ComboPoints() >= 4 SubtletyFinishCdActions()

     unless Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishCdPostConditions()
     {
      #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold-40*!(talent.alacrity.enabled|talent.shadow_focus.enabled|talent.master_of_shadows.enabled)
      if EnergyDeficit() <= stealth_threshold() - 40 * { not { Talent(alacrity_talent) or Talent(shadow_focus_talent) or Talent(master_of_shadows_talent) } } SubtletyBuildCdActions()

      unless EnergyDeficit() <= stealth_threshold() - 40 * { not { Talent(alacrity_talent) or Talent(shadow_focus_talent) or Talent(master_of_shadows_talent) } } and SubtletyBuildCdPostConditions()
      {
       #arcane_torrent,if=energy.deficit>=15+energy.regen
       if EnergyDeficit() >= 15 + EnergyRegenRate() Spell(arcane_torrent_energy)
       #arcane_pulse
       Spell(arcane_pulse)
       #lights_judgment
       Spell(lights_judgment)
      }
     }
    }
   }
  }
 }
}

AddFunction SubtletyDefaultCdPostConditions
{
 SubtletyCdsCdPostConditions() or Stealthed() and SubtletyStealthedCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade) or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsCdPostConditions() or { ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishCdPostConditions() or Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishCdPostConditions() or EnergyDeficit() <= stealth_threshold() - 40 * { not { Talent(alacrity_talent) or Talent(shadow_focus_talent) or Talent(master_of_shadows_talent) } } and SubtletyBuildCdPostConditions()
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
# alacrity_talent
# ancestral_call
# arcane_pulse
# arcane_torrent_energy
# backstab
# battle_potion_of_agility
# berserking
# blood_fury_ap
# dark_shadow_talent
# deeper_stratagem_talent
# eviscerate
# find_weakness_debuff
# find_weakness_talent
# fireblood
# gloomblade
# kick
# lights_judgment
# marked_for_death
# master_of_shadows_talent
# nightblade
# nightblade_debuff
# nightstalker_talent
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
# sharpened_blades_buff
# sharpened_blades_trait
# shuriken_storm
# shuriken_tornado
# shuriken_toss
# stealth
# subterfuge_talent
# symbols_of_death
# symbols_of_death_buff
# the_dreadlords_deceit_subtlety_buff
# vanish
# vanish_buff
# vigor_talent
]]
    OvaleScripts:RegisterScript("ROGUE", "subtlety", name, desc, code, "script")
end
