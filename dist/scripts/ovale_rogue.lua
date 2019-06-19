local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_rogue_assassination"
    local desc = "[8.1] Simulationcraft: PR_Rogue_Assassination"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Assassination".
#	class=rogue
#	spec=assassination
#	talents=2310021

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction single_target
{
 Enemies() < 2
}

AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * 7 / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } }
}

AddFunction use_filler
{
 ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target()
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=assassination)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=assassination)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=assassination)
AddCheckBox(opt_vanish SpellName(vanish) default specialization=assassination)

AddFunction AssassinationInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(kick) and target.IsInterruptible() Spell(kick)
  if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
  if target.InRange(kidney_shot) and not target.Classification(worldboss) and ComboPoints() >= MaxComboPoints()-1+Talent(internal_bleeding_talent) Spell(kidney_shot)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
 }
}

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
 #rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&(talent.exsanguinate.enabled&cooldown.exsanguinate.remains<=2|!ticking)&variable.single_target)&target.time_to_die-remains>6
 if ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 Spell(rupture)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&refreshable&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&remains<=10&pmultiplier<=1&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking
 if Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) Spell(rupture)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&target.time_to_die>remains&combo_points.deficit>1
 if Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 Spell(garrote)
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
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and Spell(rupture) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
}

AddFunction AssassinationStealthedCdActions
{
}

AddFunction AssassinationStealthedCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and Spell(rupture) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
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
 #garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains>4&spell_targets.fan_of_knives<=1|target.time_to_die-remains>12)
 if { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } Spell(garrote)
 unless { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
 {
  #crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4
  if Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 Spell(crimson_tempest)
  #rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
  if ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 Spell(rupture)
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
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

AddFunction AssassinationDotCdActions
{
}

AddFunction AssassinationDotCdPostConditions
{
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

### actions.direct

AddFunction AssassinationDirectMainActions
{
 #envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
 if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } Spell(envenom)
 #variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target
 #fan_of_knives,if=variable.use_filler&azerite.echoing_blades.enabled&spell_targets.fan_of_knives>=2
 if use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies() >= 2 Spell(fan_of_knives)
 #fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue)
 if use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } Spell(fan_of_knives)
 #fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3
 if not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() >= 3 Spell(fan_of_knives)
 #blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled&!azerite.double_dose.enabled)
 if use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } Spell(blindside)
 #mutilate,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives=2
 if not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() == 2 Spell(mutilate)
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
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies() >= 2 and Spell(fan_of_knives) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } and Spell(fan_of_knives) or not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() >= 3 and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } and Spell(blindside) or not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() == 2 and Spell(mutilate) or use_filler() and Spell(mutilate)
}

AddFunction AssassinationDirectCdActions
{
}

AddFunction AssassinationDirectCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies() >= 2 and Spell(fan_of_knives) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } and Spell(fan_of_knives) or not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() >= 3 and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } and Spell(blindside) or not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() == 2 and Spell(mutilate) or use_filler() and Spell(mutilate)
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
 #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend)
 if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() * 1.5 or ComboPointsDeficit() >= MaxComboPoints() } Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend
 if 600 > 30 - 10 and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
 #vanish,if=talent.subterfuge.enabled&!dot.garrote.ticking&variable.single_target
 if Talent(subterfuge_talent) and not target.DebuffPresent(garrote_debuff) and single_target() and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&variable.single_target)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier<=1)
 if Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and single_target() } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up
 if Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.subterfuge.enabled&(!talent.exsanguinate.enabled|!variable.single_target)&!stealthed.rogue&cooldown.garrote.up&dot.garrote.refreshable&(spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives|spell_targets.fan_of_knives>=4&combo_points.deficit>=4)
 if Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or not single_target() } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable
 if Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) Spell(vanish)
}

AddFunction AssassinationCdsShortCdPostConditions
{
 target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

AddFunction AssassinationCdsCdActions
{
 #potion,if=buff.bloodlust.react|debuff.vendetta.up
 if { BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=galecallers_boon,if=cooldown.vendetta.remains<=1&(!talent.subterfuge.enabled|dot.garrote.pmultiplier>1)|cooldown.vendetta.remains>45
 if SpellCooldown(vendetta) <= 1 and { not Talent(subterfuge_talent) or target.DebuffPersistentMultiplier(garrote_debuff) > 1 } or SpellCooldown(vendetta) > 45 AssassinationUseItemActions()
 #blood_fury,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(blood_fury_ap)
 #berserking,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(berserking)
 #fireblood,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(fireblood)
 #ancestral_call,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(ancestral_call)

 unless False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() * 1.5 or ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or 600 > 30 - 10 and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death)
 {
  #vendetta,if=!stealthed.rogue&dot.rupture.ticking&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1)&(!talent.nightstalker.enabled|!talent.exsanguinate.enabled|cooldown.exsanguinate.remains<5-2*talent.deeper_stratagem.enabled)
  if not Stealthed() and target.DebuffPresent(rupture_debuff) and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) > 1 } and { not Talent(nightstalker_talent) or not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) < 5 - 2 * TalentPoints(deeper_stratagem_talent) } Spell(vendetta)

  unless Talent(subterfuge_talent) and not target.DebuffPresent(garrote_debuff) and single_target() and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and single_target() } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or not single_target() } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish)
  {
   #shadowmeld,if=!stealthed.all&azerite.shrouded_suffocation.enabled&dot.garrote.refreshable&dot.garrote.pmultiplier<=1&combo_points.deficit>=1
   if not Stealthed() and HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) and target.DebuffPersistentMultiplier(garrote_debuff) <= 1 and ComboPointsDeficit() >= 1 Spell(shadowmeld)
  }
 }
}

AddFunction AssassinationCdsCdPostConditions
{
 False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() * 1.5 or ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or 600 > 30 - 10 and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death) or Talent(subterfuge_talent) and not target.DebuffPresent(garrote_debuff) and single_target() and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and single_target() } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or not single_target() } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #stealth
 Spell(stealth)
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #variable,name=single_target,value=spell_targets.fan_of_knives<2
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
 unless Spell(stealth)
 {
  #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
  #variable,name=single_target,value=spell_targets.fan_of_knives<2
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
}

AddFunction AssassinationDefaultShortCdPostConditions
{
 Spell(stealth) or Stealthed() and AssassinationStealthedShortCdPostConditions() or AssassinationCdsShortCdPostConditions() or AssassinationDotShortCdPostConditions() or AssassinationDirectShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 AssassinationInterruptActions()

 unless Spell(stealth)
 {
  #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
  #variable,name=single_target,value=spell_targets.fan_of_knives<2
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
}

AddFunction AssassinationDefaultCdPostConditions
{
 Spell(stealth) or Stealthed() and AssassinationStealthedCdPostConditions() or AssassinationCdsCdPostConditions() or AssassinationDotCdPostConditions() or AssassinationDirectCdPostConditions()
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
# cheap_shot
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
# garrote
# garrote_debuff
# hidden_blades_buff
# internal_bleeding_debuff
# internal_bleeding_talent
# kick
# kidney_shot
# lights_judgment
# marked_for_death
# master_assassin_buff
# master_assassin_talent
# mutilate
# nightstalker_talent
# quaking_palm
# rupture
# rupture_debuff
# shadowmeld
# shadowstep
# shrouded_suffocation_trait
# stealth
# subterfuge_talent
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
    local desc = "[8.1] Simulationcraft: PR_Rogue_Assassination_Exsg"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Assassination_Exsg".
#	class=rogue
#	spec=assassination
#	talents=2210031

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction single_target
{
 Enemies() < 2
}

AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * 7 / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } }
}

AddFunction use_filler
{
 ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target()
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=assassination)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=assassination)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=assassination)
AddCheckBox(opt_vanish SpellName(vanish) default specialization=assassination)

AddFunction AssassinationInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(kick) and target.IsInterruptible() Spell(kick)
  if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
  if target.InRange(kidney_shot) and not target.Classification(worldboss) and ComboPoints() >= MaxComboPoints()-1+Talent(internal_bleeding_talent) Spell(kidney_shot)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
 }
}

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
 #rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&(talent.exsanguinate.enabled&cooldown.exsanguinate.remains<=2|!ticking)&variable.single_target)&target.time_to_die-remains>6
 if ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 Spell(rupture)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&refreshable&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&remains<=10&pmultiplier<=1&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
 #rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking
 if Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) Spell(rupture)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&target.time_to_die>remains&combo_points.deficit>1
 if Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 Spell(garrote)
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
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and Spell(rupture) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
}

AddFunction AssassinationStealthedCdActions
{
}

AddFunction AssassinationStealthedCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and Spell(rupture) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
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
 #garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains>4&spell_targets.fan_of_knives<=1|target.time_to_die-remains>12)
 if { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } Spell(garrote)
 unless { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
 {
  #crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4
  if Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 Spell(crimson_tempest)
  #rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
  if ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 Spell(rupture)
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
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

AddFunction AssassinationDotCdActions
{
}

AddFunction AssassinationDotCdPostConditions
{
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False() and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies() <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies() >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies() >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies() >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

### actions.direct

AddFunction AssassinationDirectMainActions
{
 #envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
 if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } Spell(envenom)
 #variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target
 #fan_of_knives,if=variable.use_filler&azerite.echoing_blades.enabled&spell_targets.fan_of_knives>=2
 if use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies() >= 2 Spell(fan_of_knives)
 #fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue)
 if use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } Spell(fan_of_knives)
 #fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3
 if not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() >= 3 Spell(fan_of_knives)
 #blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled&!azerite.double_dose.enabled)
 if use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } Spell(blindside)
 #mutilate,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives=2
 if not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() == 2 Spell(mutilate)
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
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies() >= 2 and Spell(fan_of_knives) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } and Spell(fan_of_knives) or not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() >= 3 and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } and Spell(blindside) or not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() == 2 and Spell(mutilate) or use_filler() and Spell(mutilate)
}

AddFunction AssassinationDirectCdActions
{
}

AddFunction AssassinationDirectCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies() >= 2 and Spell(fan_of_knives) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies() >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } and Spell(fan_of_knives) or not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() >= 3 and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } and Spell(blindside) or not target.DebuffPresent(deadly_poison_debuff) and use_filler() and Enemies() == 2 and Spell(mutilate) or use_filler() and Spell(mutilate)
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
 #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend)
 if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() * 1.5 or ComboPointsDeficit() >= MaxComboPoints() } Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend
 if 600 > 30 - 10 and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
 #vanish,if=talent.subterfuge.enabled&!dot.garrote.ticking&variable.single_target
 if Talent(subterfuge_talent) and not target.DebuffPresent(garrote_debuff) and single_target() and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&variable.single_target)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier<=1)
 if Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and single_target() } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up
 if Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.subterfuge.enabled&(!talent.exsanguinate.enabled|!variable.single_target)&!stealthed.rogue&cooldown.garrote.up&dot.garrote.refreshable&(spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives|spell_targets.fan_of_knives>=4&combo_points.deficit>=4)
 if Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or not single_target() } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) Spell(vanish)
 #vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable
 if Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) Spell(vanish)
}

AddFunction AssassinationCdsShortCdPostConditions
{
 target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

AddFunction AssassinationCdsCdActions
{
 #potion,if=buff.bloodlust.react|debuff.vendetta.up
 if { BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=galecallers_boon,if=cooldown.vendetta.remains<=1&(!talent.subterfuge.enabled|dot.garrote.pmultiplier>1)|cooldown.vendetta.remains>45
 if SpellCooldown(vendetta) <= 1 and { not Talent(subterfuge_talent) or target.DebuffPersistentMultiplier(garrote_debuff) > 1 } or SpellCooldown(vendetta) > 45 AssassinationUseItemActions()
 #blood_fury,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(blood_fury_ap)
 #berserking,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(berserking)
 #fireblood,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(fireblood)
 #ancestral_call,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(ancestral_call)

 unless False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() * 1.5 or ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or 600 > 30 - 10 and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death)
 {
  #vendetta,if=!stealthed.rogue&dot.rupture.ticking&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1)&(!talent.nightstalker.enabled|!talent.exsanguinate.enabled|cooldown.exsanguinate.remains<5-2*talent.deeper_stratagem.enabled)
  if not Stealthed() and target.DebuffPresent(rupture_debuff) and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) > 1 } and { not Talent(nightstalker_talent) or not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) < 5 - 2 * TalentPoints(deeper_stratagem_talent) } Spell(vendetta)

  unless Talent(subterfuge_talent) and not target.DebuffPresent(garrote_debuff) and single_target() and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and single_target() } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or not single_target() } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish)
  {
   #shadowmeld,if=!stealthed.all&azerite.shrouded_suffocation.enabled&dot.garrote.refreshable&dot.garrote.pmultiplier<=1&combo_points.deficit>=1
   if not Stealthed() and HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) and target.DebuffPersistentMultiplier(garrote_debuff) <= 1 and ComboPointsDeficit() >= 1 Spell(shadowmeld)
  }
 }
}

AddFunction AssassinationCdsCdPostConditions
{
 False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() * 1.5 or ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or 600 > 30 - 10 and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death) or Talent(subterfuge_talent) and not target.DebuffPresent(garrote_debuff) and single_target() and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and single_target() } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or not single_target() } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies() <= 3 and ComboPointsDeficit() >= 1 + Enemies() or Enemies() >= 4 and ComboPointsDeficit() >= 4 } and CheckBoxOn(opt_vanish) and Spell(vanish) or Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and CheckBoxOn(opt_vanish) and Spell(vanish) or target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #stealth
 Spell(stealth)
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #variable,name=single_target,value=spell_targets.fan_of_knives<2
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
 unless Spell(stealth)
 {
  #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
  #variable,name=single_target,value=spell_targets.fan_of_knives<2
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
}

AddFunction AssassinationDefaultShortCdPostConditions
{
 Spell(stealth) or Stealthed() and AssassinationStealthedShortCdPostConditions() or AssassinationCdsShortCdPostConditions() or AssassinationDotShortCdPostConditions() or AssassinationDirectShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 AssassinationInterruptActions()

 unless Spell(stealth)
 {
  #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
  #variable,name=single_target,value=spell_targets.fan_of_knives<2
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
}

AddFunction AssassinationDefaultCdPostConditions
{
 Spell(stealth) or Stealthed() and AssassinationStealthedCdPostConditions() or AssassinationCdsCdPostConditions() or AssassinationDotCdPostConditions() or AssassinationDirectCdPostConditions()
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
# cheap_shot
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
# garrote
# garrote_debuff
# hidden_blades_buff
# internal_bleeding_debuff
# internal_bleeding_talent
# kick
# kidney_shot
# lights_judgment
# marked_for_death
# master_assassin_buff
# master_assassin_talent
# mutilate
# nightstalker_talent
# quaking_palm
# rupture
# rupture_debuff
# shadowmeld
# shadowstep
# shrouded_suffocation_trait
# stealth
# subterfuge_talent
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
    local desc = "[8.1] Simulationcraft: PR_Rogue_Outlaw"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Outlaw".
#	class=rogue
#	spec=outlaw
#	talents=2010022

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
 if AzeriteTraitRank(snake_eyes_trait) >= 2 BuffCount(roll_the_bones_buff) < 2
 if HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or BuffRemaining(ruthless_precision_buff) <= SpellCooldown(between_the_eyes) }
 BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or not BuffPresent(grand_melee_buff) and not BuffPresent(ruthless_precision_buff) }
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=outlaw)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=outlaw)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=outlaw)
AddCheckBox(opt_blade_flurry SpellName(blade_flurry) default specialization=outlaw)

AddFunction OutlawInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(kick) and target.IsInterruptible() Spell(kick)
  if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
  if target.InRange(between_the_eyes) and not target.Classification(worldboss) and ComboPoints() >= MaxComboPoints()-1 Spell(between_the_eyes)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.InRange(gouge) and not target.Classification(worldboss) Spell(gouge)
 }
}

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
 #roll_the_bones,if=buff.roll_the_bones.remains<=3|variable.rtb_reroll
 if BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() Spell(roll_the_bones)
 #dispatch
 Spell(dispatch)
}

AddFunction OutlawFinishMainPostConditions
{
}

AddFunction OutlawFinishShortCdActions
{
 #between_the_eyes,if=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
 if BuffPresent(ruthless_precision_buff) or { HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) } and DebuffPresent(roll_the_bones) Spell(between_the_eyes)

 unless BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones)
 {
  #between_the_eyes,if=azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
  if HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) Spell(between_the_eyes)
 }
}

AddFunction OutlawFinishShortCdPostConditions
{
 BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or Spell(dispatch)
}

AddFunction OutlawFinishCdActions
{
}

AddFunction OutlawFinishCdPostConditions
{
 { BuffPresent(ruthless_precision_buff) or { HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) } and DebuffPresent(roll_the_bones) } and Spell(between_the_eyes) or BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or { HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) } and Spell(between_the_eyes) or Spell(dispatch)
}

### actions.cds

AddFunction OutlawCdsMainActions
{
 #blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
 if Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) Spell(blade_flurry)
}

AddFunction OutlawCdsMainPostConditions
{
}

AddFunction OutlawCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
 if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1
 if 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 Spell(marked_for_death)

 unless Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
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
 Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
}

AddFunction OutlawCdsCdActions
{
 #potion,if=buff.bloodlust.react|buff.adrenaline_rush.up
 if { BuffPresent(burst_haste_buff any=1) or BuffPresent(adrenaline_rush_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
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

 unless False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 and Spell(marked_for_death) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
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
 False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 and Spell(marked_for_death) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike) or blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush) or not Stealthed() and ambush_condition() and Spell(vanish)
}

### actions.build

AddFunction OutlawBuildMainActions
{
 #pistol_shot,if=combo_points.deficit>=1+buff.broadside.up+talent.quick_draw.enabled&buff.opportunity.up
 if ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) Spell(pistol_shot)
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
 ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) and Spell(pistol_shot) or Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildCdActions
{
}

AddFunction OutlawBuildCdPostConditions
{
 ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) and Spell(pistol_shot) or Spell(sinister_strike_outlaw)
}

### actions.default

AddFunction OutlawDefaultMainActions
{
 #stealth
 Spell(stealth)
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
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
 unless Spell(stealth)
 {
  #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
  #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
  #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
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
}

AddFunction OutlawDefaultShortCdPostConditions
{
 Spell(stealth) or Stealthed() and OutlawStealthShortCdPostConditions() or OutlawCdsShortCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishShortCdPostConditions() or OutlawBuildShortCdPostConditions()
}

AddFunction OutlawDefaultCdActions
{
 OutlawInterruptActions()

 unless Spell(stealth)
 {
  #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
  #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
  #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
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
}

AddFunction OutlawDefaultCdPostConditions
{
 Spell(stealth) or Stealthed() and OutlawStealthCdPostConditions() or OutlawCdsCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishCdPostConditions() or OutlawBuildCdPostConditions()
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
# cheap_shot
# deadshot_trait
# dispatch
# fireblood
# ghostly_strike
# ghostly_strike_talent
# gouge
# grand_melee_buff
# kick
# killing_spree
# lights_judgment
# loaded_dice_buff
# marked_for_death
# marked_for_death_talent
# opportunity_buff
# pistol_shot
# quaking_palm
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
# snake_eyes_trait
# stealth
# vanish
]]
    OvaleScripts:RegisterScript("ROGUE", "outlaw", name, desc, code, "script")
end
do
    local name = "sc_pr_rogue_outlaw_snd"
    local desc = "[8.1] Simulationcraft: PR_Rogue_Outlaw_SnD"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Outlaw_SnD".
#	class=rogue
#	spec=outlaw
#	talents=2010032

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
 if AzeriteTraitRank(snake_eyes_trait) >= 2 BuffCount(roll_the_bones_buff) < 2
 if HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or BuffRemaining(ruthless_precision_buff) <= SpellCooldown(between_the_eyes) }
 BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or not BuffPresent(grand_melee_buff) and not BuffPresent(ruthless_precision_buff) }
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=outlaw)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=outlaw)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=outlaw)
AddCheckBox(opt_blade_flurry SpellName(blade_flurry) default specialization=outlaw)

AddFunction OutlawInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(kick) and target.IsInterruptible() Spell(kick)
  if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
  if target.InRange(between_the_eyes) and not target.Classification(worldboss) and ComboPoints() >= MaxComboPoints()-1 Spell(between_the_eyes)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.InRange(gouge) and not target.Classification(worldboss) Spell(gouge)
 }
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
 #roll_the_bones,if=buff.roll_the_bones.remains<=3|variable.rtb_reroll
 if BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() Spell(roll_the_bones)
 #dispatch
 Spell(dispatch)
}

AddFunction OutlawFinishMainPostConditions
{
}

AddFunction OutlawFinishShortCdActions
{
 #between_the_eyes,if=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
 if BuffPresent(ruthless_precision_buff) or { HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) } and DebuffPresent(roll_the_bones) Spell(between_the_eyes)

 unless BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones)
 {
  #between_the_eyes,if=azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
  if HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) Spell(between_the_eyes)
 }
}

AddFunction OutlawFinishShortCdPostConditions
{
 BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or Spell(dispatch)
}

AddFunction OutlawFinishCdActions
{
}

AddFunction OutlawFinishCdPostConditions
{
 { BuffPresent(ruthless_precision_buff) or { HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) } and DebuffPresent(roll_the_bones) } and Spell(between_the_eyes) or BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or { HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) } and Spell(between_the_eyes) or Spell(dispatch)
}

### actions.cds

AddFunction OutlawCdsMainActions
{
 #blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
 if Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) Spell(blade_flurry)
}

AddFunction OutlawCdsMainPostConditions
{
}

AddFunction OutlawCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
 if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1
 if 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 Spell(marked_for_death)

 unless Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
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
 Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry)
}

AddFunction OutlawCdsCdActions
{
 #potion,if=buff.bloodlust.react|buff.adrenaline_rush.up
 if { BuffPresent(burst_haste_buff any=1) or BuffPresent(adrenaline_rush_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
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

 unless False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 and Spell(marked_for_death) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
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
 False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } and Spell(marked_for_death) or 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 and Spell(marked_for_death) or Enemies() >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and CheckBoxOn(opt_blade_flurry) and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike) or blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush) or not Stealthed() and ambush_condition() and Spell(vanish)
}

### actions.build

AddFunction OutlawBuildMainActions
{
 #pistol_shot,if=combo_points.deficit>=1+buff.broadside.up+talent.quick_draw.enabled&buff.opportunity.up
 if ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) Spell(pistol_shot)
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
 ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) and Spell(pistol_shot) or Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildCdActions
{
}

AddFunction OutlawBuildCdPostConditions
{
 ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) + TalentPoints(quick_draw_talent) and BuffPresent(opportunity_buff) and Spell(pistol_shot) or Spell(sinister_strike_outlaw)
}

### actions.default

AddFunction OutlawDefaultMainActions
{
 #stealth
 Spell(stealth)
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
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
 unless Spell(stealth)
 {
  #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
  #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
  #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
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
}

AddFunction OutlawDefaultShortCdPostConditions
{
 Spell(stealth) or Stealthed() and OutlawStealthShortCdPostConditions() or OutlawCdsShortCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishShortCdPostConditions() or OutlawBuildShortCdPostConditions()
}

AddFunction OutlawDefaultCdActions
{
 OutlawInterruptActions()

 unless Spell(stealth)
 {
  #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
  #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
  #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
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
}

AddFunction OutlawDefaultCdPostConditions
{
 Spell(stealth) or Stealthed() and OutlawStealthCdPostConditions() or OutlawCdsCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishCdPostConditions() or OutlawBuildCdPostConditions()
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
# cheap_shot
# deadshot_trait
# dispatch
# fireblood
# ghostly_strike
# ghostly_strike_talent
# gouge
# grand_melee_buff
# kick
# killing_spree
# lights_judgment
# loaded_dice_buff
# marked_for_death
# marked_for_death_talent
# opportunity_buff
# pistol_shot
# quaking_palm
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
# snake_eyes_trait
# stealth
# vanish
]]
    OvaleScripts:RegisterScript("ROGUE", "outlaw", name, desc, code, "script")
end
do
    local name = "sc_pr_rogue_subtlety"
    local desc = "[8.1] Simulationcraft: PR_Rogue_Subtlety"
    local code = [[
# Based on SimulationCraft profile "PR_Rogue_Subtlety".
#	class=rogue
#	spec=subtlety
#	talents=1320031

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)


AddFunction stealth_threshold
{
 25 + TalentPoints(vigor_talent) * 35 + TalentPoints(master_of_shadows_talent) * 25 + TalentPoints(shadow_focus_talent) * 20 + TalentPoints(alacrity_talent) * 10 + 15 * { Enemies() >= 3 }
}

AddFunction use_priority_rotation
{
 CheckBoxOn(opt_priority_rotation) and Enemies() >= 2
}

AddFunction shd_threshold
{
 SpellCharges(shadow_dance count=0) >= 1.75
}

AddCheckBox(opt_priority_rotation L(opt_priority_rotation) default specialization=subtlety)
AddCheckBox(opt_interrupt L(interrupt) default specialization=subtlety)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=subtlety)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=subtlety)

AddFunction SubtletyInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(kick) and target.IsInterruptible() Spell(kick)
  if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
  if target.InRange(kidney_shot) and not target.Classification(worldboss) and ComboPoints() >= MaxComboPoints()-1 Spell(kidney_shot)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
 }
}

AddFunction SubtletyUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

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
 #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&(buff.vanish.up|azerite.the_first_dance.enabled&!talent.dark_shadow.enabled&!talent.subterfuge.enabled))
 if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and { BuffPresent(vanish_buff) or HasAzeriteTrait(the_first_dance_trait) and not Talent(dark_shadow_talent) and not Talent(subterfuge_talent) } } SubtletyFinishMainActions()

 unless ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and { BuffPresent(vanish_buff) or HasAzeriteTrait(the_first_dance_trait) and not Talent(dark_shadow_talent) and not Talent(subterfuge_talent) } } and SubtletyFinishMainPostConditions()
 {
  #shadowstrike,cycle_targets=1,if=talent.secret_technique.enabled&talent.find_weakness.enabled&debuff.find_weakness.remains<1&spell_targets.shuriken_storm=2&target.time_to_die-remains>6
  if Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies() == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 Spell(shadowstrike)
  #shadowstrike,if=!talent.deeper_stratagem.enabled&azerite.blade_in_the_shadows.rank=3&spell_targets.shuriken_storm=3
  if not Talent(deeper_stratagem_talent) and AzeriteTraitRank(blade_in_the_shadows_trait) == 3 and Enemies() == 3 Spell(shadowstrike)
  #shuriken_storm,if=spell_targets>=3
  if Enemies() >= 3 Spell(shuriken_storm)
  #shadowstrike
  Spell(shadowstrike)
 }
}

AddFunction SubtletyStealthedMainPostConditions
{
 ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and { BuffPresent(vanish_buff) or HasAzeriteTrait(the_first_dance_trait) and not Talent(dark_shadow_talent) and not Talent(subterfuge_talent) } } and SubtletyFinishMainPostConditions()
}

AddFunction SubtletyStealthedShortCdActions
{
 unless BuffPresent(stealthed_buff any=1) and Spell(shadowstrike)
 {
  #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&(buff.vanish.up|azerite.the_first_dance.enabled&!talent.dark_shadow.enabled&!talent.subterfuge.enabled))
  if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and { BuffPresent(vanish_buff) or HasAzeriteTrait(the_first_dance_trait) and not Talent(dark_shadow_talent) and not Talent(subterfuge_talent) } } SubtletyFinishShortCdActions()
 }
}

AddFunction SubtletyStealthedShortCdPostConditions
{
 BuffPresent(stealthed_buff any=1) and Spell(shadowstrike) or ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and { BuffPresent(vanish_buff) or HasAzeriteTrait(the_first_dance_trait) and not Talent(dark_shadow_talent) and not Talent(subterfuge_talent) } } and SubtletyFinishShortCdPostConditions() or Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies() == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 and Spell(shadowstrike) or not Talent(deeper_stratagem_talent) and AzeriteTraitRank(blade_in_the_shadows_trait) == 3 and Enemies() == 3 and Spell(shadowstrike) or Enemies() >= 3 and Spell(shuriken_storm) or Spell(shadowstrike)
}

AddFunction SubtletyStealthedCdActions
{
 unless BuffPresent(stealthed_buff any=1) and Spell(shadowstrike)
 {
  #call_action_list,name=finish,if=combo_points.deficit<=1-(talent.deeper_stratagem.enabled&(buff.vanish.up|azerite.the_first_dance.enabled&!talent.dark_shadow.enabled&!talent.subterfuge.enabled))
  if ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and { BuffPresent(vanish_buff) or HasAzeriteTrait(the_first_dance_trait) and not Talent(dark_shadow_talent) and not Talent(subterfuge_talent) } } SubtletyFinishCdActions()
 }
}

AddFunction SubtletyStealthedCdPostConditions
{
 BuffPresent(stealthed_buff any=1) and Spell(shadowstrike) or ComboPointsDeficit() <= 1 - { Talent(deeper_stratagem_talent) and { BuffPresent(vanish_buff) or HasAzeriteTrait(the_first_dance_trait) and not Talent(dark_shadow_talent) and not Talent(subterfuge_talent) } } and SubtletyFinishCdPostConditions() or Talent(secret_technique_talent) and Talent(find_weakness_talent) and target.DebuffRemaining(find_weakness_debuff) < 1 and Enemies() == 2 and target.TimeToDie() - target.DebuffRemaining(shadowstrike) > 6 and Spell(shadowstrike) or not Talent(deeper_stratagem_talent) and AzeriteTraitRank(blade_in_the_shadows_trait) == 3 and Enemies() == 3 and Spell(shadowstrike) or Enemies() >= 3 and Spell(shuriken_storm) or Spell(shadowstrike)
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
 #vanish,if=!variable.shd_threshold&debuff.find_weakness.remains<1&combo_points.deficit>1
 if not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 Spell(vanish)
 #pool_resource,for_next=1,extra_amount=40
 #shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&debuff.find_weakness.remains<1&combo_points.deficit>1
 unless True(pool_energy 40) and EnergyDeficit() >= 10 and not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(40)
 {
  #shadow_dance,if=(!talent.dark_shadow.enabled|dot.nightblade.remains>=5+talent.subterfuge.enabled)&(!talent.nightstalker.enabled&!talent.dark_shadow.enabled|!variable.use_priority_rotation|combo_points.deficit<=1+2*azerite.the_first_dance.enabled)&(variable.shd_threshold|buff.symbols_of_death.remains>=1.2|spell_targets.shuriken_storm>=4&cooldown.symbols_of_death.remains>10)
  if { not Talent(dark_shadow_talent) or target.DebuffRemaining(nightblade_debuff) >= 5 + TalentPoints(subterfuge_talent) } and { not Talent(nightstalker_talent) and not Talent(dark_shadow_talent) or not use_priority_rotation() or ComboPointsDeficit() <= 1 + 2 * HasAzeriteTrait(the_first_dance_trait) } and { shd_threshold() or BuffRemaining(symbols_of_death_buff) >= 1.2 or Enemies() >= 4 and SpellCooldown(symbols_of_death) > 10 } Spell(shadow_dance)
  #shadow_dance,if=target.time_to_die<cooldown.symbols_of_death.remains&!raid_event.adds.up
  if target.TimeToDie() < SpellCooldown(symbols_of_death) and not False(raid_event_adds_exists) Spell(shadow_dance)
 }
}

AddFunction SubtletyStealthcdsShortCdPostConditions
{
}

AddFunction SubtletyStealthcdsCdActions
{
 unless not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 and Spell(vanish)
 {
  #pool_resource,for_next=1,extra_amount=40
  #shadowmeld,if=energy>=40&energy.deficit>=10&!variable.shd_threshold&debuff.find_weakness.remains<1&combo_points.deficit>1
  if Energy() >= 40 and EnergyDeficit() >= 10 and not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 Spell(shadowmeld)
 }
}

AddFunction SubtletyStealthcdsCdPostConditions
{
 not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 and Spell(vanish) or not { True(pool_energy 40) and EnergyDeficit() >= 10 and not shd_threshold() and target.DebuffRemaining(find_weakness_debuff) < 1 and ComboPointsDeficit() > 1 and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(40) } and { { not Talent(dark_shadow_talent) or target.DebuffRemaining(nightblade_debuff) >= 5 + TalentPoints(subterfuge_talent) } and { not Talent(nightstalker_talent) and not Talent(dark_shadow_talent) or not use_priority_rotation() or ComboPointsDeficit() <= 1 + 2 * HasAzeriteTrait(the_first_dance_trait) } and { shd_threshold() or BuffRemaining(symbols_of_death_buff) >= 1.2 or Enemies() >= 4 and SpellCooldown(symbols_of_death) > 10 } and Spell(shadow_dance) or target.TimeToDie() < SpellCooldown(symbols_of_death) and not False(raid_event_adds_exists) and Spell(shadow_dance) }
}

### actions.precombat

AddFunction SubtletyPrecombatMainActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
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
 #eviscerate,if=talent.shadow_focus.enabled&buff.nights_vengeance.up&spell_targets.shuriken_storm>=2+3*talent.secret_technique.enabled
 if Talent(shadow_focus_talent) and BuffPresent(nights_vengeance_buff) and Enemies() >= 2 + 3 * TalentPoints(secret_technique_talent) Spell(eviscerate)
 #nightblade,if=(!talent.dark_shadow.enabled|!buff.shadow_dance.up)&target.time_to_die-remains>6&remains<tick_time*2
 if { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.CurrentTickTime(nightblade_debuff) * 2 Spell(nightblade)
 #nightblade,cycle_targets=1,if=!variable.use_priority_rotation&spell_targets.shuriken_storm>=2&(azerite.nights_vengeance.enabled|!azerite.replicating_shadows.enabled|spell_targets.shuriken_storm-active_dot.nightblade>=2)&!buff.shadow_dance.up&target.time_to_die>=(5+(2*combo_points))&refreshable
 if not use_priority_rotation() and Enemies() >= 2 and { HasAzeriteTrait(nights_vengeance_trait) or not HasAzeriteTrait(replicating_shadows_trait) or Enemies() - DebuffCountOnAny(nightblade_debuff) >= 2 } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) Spell(nightblade)
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
 unless Talent(shadow_focus_talent) and BuffPresent(nights_vengeance_buff) and Enemies() >= 2 + 3 * TalentPoints(secret_technique_talent) and Spell(eviscerate) or { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.CurrentTickTime(nightblade_debuff) * 2 and Spell(nightblade) or not use_priority_rotation() and Enemies() >= 2 and { HasAzeriteTrait(nights_vengeance_trait) or not HasAzeriteTrait(replicating_shadows_trait) or Enemies() - DebuffCountOnAny(nightblade_debuff) >= 2 } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade)
 {
  #secret_technique,if=buff.symbols_of_death.up&(!talent.dark_shadow.enabled|buff.shadow_dance.up)
  if BuffPresent(symbols_of_death_buff) and { not Talent(dark_shadow_talent) or BuffPresent(shadow_dance_buff) } Spell(secret_technique)
  #secret_technique,if=spell_targets.shuriken_storm>=2+talent.dark_shadow.enabled+talent.nightstalker.enabled
  if Enemies() >= 2 + TalentPoints(dark_shadow_talent) + TalentPoints(nightstalker_talent) Spell(secret_technique)
 }
}

AddFunction SubtletyFinishShortCdPostConditions
{
 Talent(shadow_focus_talent) and BuffPresent(nights_vengeance_buff) and Enemies() >= 2 + 3 * TalentPoints(secret_technique_talent) and Spell(eviscerate) or { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.CurrentTickTime(nightblade_debuff) * 2 and Spell(nightblade) or not use_priority_rotation() and Enemies() >= 2 and { HasAzeriteTrait(nights_vengeance_trait) or not HasAzeriteTrait(replicating_shadows_trait) or Enemies() - DebuffCountOnAny(nightblade_debuff) >= 2 } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade) or Spell(eviscerate)
}

AddFunction SubtletyFinishCdActions
{
}

AddFunction SubtletyFinishCdPostConditions
{
 Talent(shadow_focus_talent) and BuffPresent(nights_vengeance_buff) and Enemies() >= 2 + 3 * TalentPoints(secret_technique_talent) and Spell(eviscerate) or { not Talent(dark_shadow_talent) or not BuffPresent(shadow_dance_buff) } and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > 6 and target.DebuffRemaining(nightblade_debuff) < target.CurrentTickTime(nightblade_debuff) * 2 and Spell(nightblade) or not use_priority_rotation() and Enemies() >= 2 and { HasAzeriteTrait(nights_vengeance_trait) or not HasAzeriteTrait(replicating_shadows_trait) or Enemies() - DebuffCountOnAny(nightblade_debuff) >= 2 } and not BuffPresent(shadow_dance_buff) and target.TimeToDie() >= 5 + 2 * ComboPoints() and target.Refreshable(nightblade_debuff) and Spell(nightblade) or target.DebuffRemaining(nightblade_debuff) < SpellCooldown(symbols_of_death) + 10 and SpellCooldown(symbols_of_death) <= 5 and target.TimeToDie() - target.DebuffRemaining(nightblade_debuff) > SpellCooldown(symbols_of_death) + 5 and Spell(nightblade) or BuffPresent(symbols_of_death_buff) and { not Talent(dark_shadow_talent) or BuffPresent(shadow_dance_buff) } and Spell(secret_technique) or Enemies() >= 2 + TalentPoints(dark_shadow_talent) + TalentPoints(nightstalker_talent) and Spell(secret_technique) or Spell(eviscerate)
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
 #shadow_dance,use_off_gcd=1,if=!buff.shadow_dance.up&buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
 if not BuffPresent(shadow_dance_buff) and DebuffPresent(shuriken_tornado) and DebuffRemaining(shuriken_tornado) <= 3.5 Spell(shadow_dance)
 #symbols_of_death,use_off_gcd=1,if=buff.shuriken_tornado.up&buff.shuriken_tornado.remains<=3.5
 if DebuffPresent(shuriken_tornado) and DebuffRemaining(shuriken_tornado) <= 3.5 Spell(symbols_of_death)
 #symbols_of_death,if=dot.nightblade.ticking&(!talent.shuriken_tornado.enabled|talent.shadow_focus.enabled|spell_targets.shuriken_storm<3|!cooldown.shuriken_tornado.up)
 if target.DebuffPresent(nightblade_debuff) and { not Talent(shuriken_tornado_talent) or Talent(shadow_focus_talent) or Enemies() < 3 or not { not SpellCooldown(shuriken_tornado) > 0 } } Spell(symbols_of_death)
 #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.all&combo_points.deficit>=cp_max_spend)
 if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() } Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.all&combo_points.deficit>=cp_max_spend
 if 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
 #shuriken_tornado,if=spell_targets>=3&!talent.shadow_focus.enabled&dot.nightblade.ticking&!stealthed.all&cooldown.symbols_of_death.up&cooldown.shadow_dance.charges>=1
 if Enemies() >= 3 and not Talent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and not Stealthed() and not SpellCooldown(symbols_of_death) > 0 and SpellCharges(shadow_dance) >= 1 Spell(shuriken_tornado)
 #shuriken_tornado,if=spell_targets>=3&talent.shadow_focus.enabled&dot.nightblade.ticking&buff.symbols_of_death.up
 if Enemies() >= 3 and Talent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and BuffPresent(symbols_of_death_buff) Spell(shuriken_tornado)
 #shadow_dance,if=!buff.shadow_dance.up&target.time_to_die<=5+talent.subterfuge.enabled&!raid_event.adds.up
 if not BuffPresent(shadow_dance_buff) and target.TimeToDie() <= 5 + TalentPoints(subterfuge_talent) and not False(raid_event_adds_exists) Spell(shadow_dance)
}

AddFunction SubtletyCdsShortCdPostConditions
{
}

AddFunction SubtletyCdsCdActions
{
 #potion,if=buff.bloodlust.react|buff.symbols_of_death.up&(buff.shadow_blades.up|cooldown.shadow_blades.remains<=10)
 if { BuffPresent(burst_haste_buff any=1) or BuffPresent(symbols_of_death_buff) and { BuffPresent(shadow_blades_buff) or SpellCooldown(shadow_blades) <= 10 } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=galecallers_boon,if=buff.symbols_of_death.up|target.time_to_die<20
 if BuffPresent(symbols_of_death_buff) or target.TimeToDie() < 20 SubtletyUseItemActions()
 #blood_fury,if=buff.symbols_of_death.up
 if BuffPresent(symbols_of_death_buff) Spell(blood_fury_ap)
 #berserking,if=buff.symbols_of_death.up
 if BuffPresent(symbols_of_death_buff) Spell(berserking)
 #fireblood,if=buff.symbols_of_death.up
 if BuffPresent(symbols_of_death_buff) Spell(fireblood)
 #ancestral_call,if=buff.symbols_of_death.up
 if BuffPresent(symbols_of_death_buff) Spell(ancestral_call)

 unless not BuffPresent(shadow_dance_buff) and DebuffPresent(shuriken_tornado) and DebuffRemaining(shuriken_tornado) <= 3.5 and Spell(shadow_dance) or DebuffPresent(shuriken_tornado) and DebuffRemaining(shuriken_tornado) <= 3.5 and Spell(symbols_of_death) or target.DebuffPresent(nightblade_debuff) and { not Talent(shuriken_tornado_talent) or Talent(shadow_focus_talent) or Enemies() < 3 or not { not SpellCooldown(shuriken_tornado) > 0 } } and Spell(symbols_of_death) or False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death)
 {
  #shadow_blades,if=combo_points.deficit>=2+stealthed.all
  if ComboPointsDeficit() >= 2 + Stealthed() Spell(shadow_blades)
 }
}

AddFunction SubtletyCdsCdPostConditions
{
 not BuffPresent(shadow_dance_buff) and DebuffPresent(shuriken_tornado) and DebuffRemaining(shuriken_tornado) <= 3.5 and Spell(shadow_dance) or DebuffPresent(shuriken_tornado) and DebuffRemaining(shuriken_tornado) <= 3.5 and Spell(symbols_of_death) or target.DebuffPresent(nightblade_debuff) and { not Talent(shuriken_tornado_talent) or Talent(shadow_focus_talent) or Enemies() < 3 or not { not SpellCooldown(shuriken_tornado) > 0 } } and Spell(symbols_of_death) or False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() } and Spell(marked_for_death) or 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() and Spell(marked_for_death) or Enemies() >= 3 and not Talent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and not Stealthed() and not SpellCooldown(symbols_of_death) > 0 and SpellCharges(shadow_dance) >= 1 and Spell(shuriken_tornado) or Enemies() >= 3 and Talent(shadow_focus_talent) and target.DebuffPresent(nightblade_debuff) and BuffPresent(symbols_of_death_buff) and Spell(shuriken_tornado) or not BuffPresent(shadow_dance_buff) and target.TimeToDie() <= 5 + TalentPoints(subterfuge_talent) and not False(raid_event_adds_exists) and Spell(shadow_dance)
}

### actions.build

AddFunction SubtletyBuildMainActions
{
 #shuriken_storm,if=spell_targets>=2
 if Enemies() >= 2 Spell(shuriken_storm)
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
 Enemies() >= 2 and Spell(shuriken_storm) or Spell(gloomblade) or Spell(backstab)
}

AddFunction SubtletyBuildCdActions
{
}

AddFunction SubtletyBuildCdPostConditions
{
 Enemies() >= 2 and Spell(shuriken_storm) or Spell(gloomblade) or Spell(backstab)
}

### actions.default

AddFunction SubtletyDefaultMainActions
{
 #stealth
 Spell(stealth)
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
   #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
   #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
   if use_priority_rotation() SubtletyStealthcdsMainActions()

   unless use_priority_rotation() and SubtletyStealthcdsMainPostConditions()
   {
    #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
    #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
    if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthcdsMainActions()

    unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsMainPostConditions()
    {
     #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&talent.dark_shadow.enabled&talent.secret_technique.enabled&cooldown.secret_technique.up&spell_targets.shuriken_storm<=4
     if EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 SubtletyStealthcdsMainActions()

     unless EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 and SubtletyStealthcdsMainPostConditions()
     {
      #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
      if ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishMainActions()

      unless { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishMainPostConditions()
      {
       #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
       if Enemies() == 4 and ComboPoints() >= 4 SubtletyFinishMainActions()

       unless Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishMainPostConditions()
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

AddFunction SubtletyDefaultMainPostConditions
{
 SubtletyCdsMainPostConditions() or Stealthed() and SubtletyStealthedMainPostConditions() or use_priority_rotation() and SubtletyStealthcdsMainPostConditions() or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsMainPostConditions() or EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 and SubtletyStealthcdsMainPostConditions() or { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishMainPostConditions() or Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishMainPostConditions() or EnergyDeficit() <= stealth_threshold() and SubtletyBuildMainPostConditions()
}

AddFunction SubtletyDefaultShortCdActions
{
 unless Spell(stealth)
 {
  #call_action_list,name=cds
  SubtletyCdsShortCdActions()

  unless SubtletyCdsShortCdPostConditions()
  {
   #run_action_list,name=stealthed,if=stealthed.all
   if Stealthed() SubtletyStealthedShortCdActions()

   unless Stealthed() and SubtletyStealthedShortCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade)
   {
    #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
    #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
    if use_priority_rotation() SubtletyStealthcdsShortCdActions()

    unless use_priority_rotation() and SubtletyStealthcdsShortCdPostConditions()
    {
     #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
     #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
     if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthcdsShortCdActions()

     unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsShortCdPostConditions()
     {
      #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&talent.dark_shadow.enabled&talent.secret_technique.enabled&cooldown.secret_technique.up&spell_targets.shuriken_storm<=4
      if EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 SubtletyStealthcdsShortCdActions()

      unless EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 and SubtletyStealthcdsShortCdPostConditions()
      {
       #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
       if ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishShortCdActions()

       unless { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishShortCdPostConditions()
       {
        #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
        if Enemies() == 4 and ComboPoints() >= 4 SubtletyFinishShortCdActions()

        unless Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishShortCdPostConditions()
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

AddFunction SubtletyDefaultShortCdPostConditions
{
 Spell(stealth) or SubtletyCdsShortCdPostConditions() or Stealthed() and SubtletyStealthedShortCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade) or use_priority_rotation() and SubtletyStealthcdsShortCdPostConditions() or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsShortCdPostConditions() or EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 and SubtletyStealthcdsShortCdPostConditions() or { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishShortCdPostConditions() or Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishShortCdPostConditions() or EnergyDeficit() <= stealth_threshold() and SubtletyBuildShortCdPostConditions()
}

AddFunction SubtletyDefaultCdActions
{
 SubtletyInterruptActions()

 unless Spell(stealth)
 {
  #call_action_list,name=cds
  SubtletyCdsCdActions()

  unless SubtletyCdsCdPostConditions()
  {
   #run_action_list,name=stealthed,if=stealthed.all
   if Stealthed() SubtletyStealthedCdActions()

   unless Stealthed() and SubtletyStealthedCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade)
   {
    #variable,name=use_priority_rotation,value=priority_rotation&spell_targets.shuriken_storm>=2
    #call_action_list,name=stealth_cds,if=variable.use_priority_rotation
    if use_priority_rotation() SubtletyStealthcdsCdActions()

    unless use_priority_rotation() and SubtletyStealthcdsCdPostConditions()
    {
     #variable,name=stealth_threshold,value=25+talent.vigor.enabled*35+talent.master_of_shadows.enabled*25+talent.shadow_focus.enabled*20+talent.alacrity.enabled*10+15*(spell_targets.shuriken_storm>=3)
     #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&combo_points.deficit>=4
     if EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 SubtletyStealthcdsCdActions()

     unless EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsCdPostConditions()
     {
      #call_action_list,name=stealth_cds,if=energy.deficit<=variable.stealth_threshold&talent.dark_shadow.enabled&talent.secret_technique.enabled&cooldown.secret_technique.up&spell_targets.shuriken_storm<=4
      if EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 SubtletyStealthcdsCdActions()

      unless EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 and SubtletyStealthcdsCdPostConditions()
      {
       #call_action_list,name=finish,if=combo_points.deficit<=1|target.time_to_die<=1&combo_points>=3
       if ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 SubtletyFinishCdActions()

       unless { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishCdPostConditions()
       {
        #call_action_list,name=finish,if=spell_targets.shuriken_storm=4&combo_points>=4
        if Enemies() == 4 and ComboPoints() >= 4 SubtletyFinishCdActions()

        unless Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishCdPostConditions()
        {
         #call_action_list,name=build,if=energy.deficit<=variable.stealth_threshold
         if EnergyDeficit() <= stealth_threshold() SubtletyBuildCdActions()

         unless EnergyDeficit() <= stealth_threshold() and SubtletyBuildCdPostConditions()
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
  }
 }
}

AddFunction SubtletyDefaultCdPostConditions
{
 Spell(stealth) or SubtletyCdsCdPostConditions() or Stealthed() and SubtletyStealthedCdPostConditions() or target.TimeToDie() > 6 and target.DebuffRemaining(nightblade_debuff) < GCD() and ComboPoints() >= 4 - { TimeInCombat() < 10 } * 2 and Spell(nightblade) or use_priority_rotation() and SubtletyStealthcdsCdPostConditions() or EnergyDeficit() <= stealth_threshold() and ComboPointsDeficit() >= 4 and SubtletyStealthcdsCdPostConditions() or EnergyDeficit() <= stealth_threshold() and Talent(dark_shadow_talent) and Talent(secret_technique_talent) and not SpellCooldown(secret_technique) > 0 and Enemies() <= 4 and SubtletyStealthcdsCdPostConditions() or { ComboPointsDeficit() <= 1 or target.TimeToDie() <= 1 and ComboPoints() >= 3 } and SubtletyFinishCdPostConditions() or Enemies() == 4 and ComboPoints() >= 4 and SubtletyFinishCdPostConditions() or EnergyDeficit() <= stealth_threshold() and SubtletyBuildCdPostConditions()
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
# blade_in_the_shadows_trait
# blood_fury_ap
# cheap_shot
# dark_shadow_talent
# deeper_stratagem_talent
# eviscerate
# find_weakness_debuff
# find_weakness_talent
# fireblood
# gloomblade
# kick
# kidney_shot
# lights_judgment
# marked_for_death
# master_of_shadows_talent
# nightblade
# nightblade_debuff
# nights_vengeance_buff
# nights_vengeance_trait
# nightstalker_talent
# quaking_palm
# replicating_shadows_trait
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
# vanish
# vanish_buff
# vigor_talent
]]
    OvaleScripts:RegisterScript("ROGUE", "subtlety", name, desc, code, "script")
end
