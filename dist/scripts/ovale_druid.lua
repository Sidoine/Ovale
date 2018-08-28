local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_druid_balance"
    local desc = "[8.0] Simulationcraft: PR_Druid_Balance"
    local code = [[
# Based on SimulationCraft profile "PR_Druid_Balance".
#	class=druid
#	spec=balance
#	talents=2000231

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)


AddFunction az_potm
{
 if Talent(twin_moons_talent) AzeriteTraitRank(power_of_the_moon_trait)
}

AddFunction az_sb
{
 AzeriteTraitRank(sunblaze_trait)
}

AddFunction az_ds
{
 AzeriteTraitRank(dawning_sun_trait)
}

AddFunction az_streak
{
 AzeriteTraitRank(streaking_stars_trait)
}

AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=balance)

AddFunction BalanceUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.precombat

AddFunction BalancePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #variable,name=az_streak,value=azerite.streaking_stars.rank
 #variable,name=az_ds,value=azerite.dawning_sun.rank
 #variable,name=az_sb,value=azerite.sunblaze.rank
 #variable,name=az_potm,value=azerite.power_of_the_moon.rank,if=talent.twin_moons.enabled
 #moonkin_form
 Spell(moonkin_form_balance)
 #solar_wrath
 Spell(solar_wrath_balance)
}

AddFunction BalancePrecombatMainPostConditions
{
}

AddFunction BalancePrecombatShortCdActions
{
}

AddFunction BalancePrecombatShortCdPostConditions
{
 Spell(moonkin_form_balance) or Spell(solar_wrath_balance)
}

AddFunction BalancePrecombatCdActions
{
 unless Spell(moonkin_form_balance)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(rising_death usable=1)
 }
}

AddFunction BalancePrecombatCdPostConditions
{
 Spell(moonkin_form_balance) or Spell(solar_wrath_balance)
}

### actions.default

AddFunction BalanceDefaultMainActions
{
 #sunfire,target_if=refreshable,if=astral_power.deficit>=7&target.time_to_die>5.4&(!buff.celestial_alignment.up&!buff.incarnation.up|!variable.az_streak|!prev_gcd.1.sunfire)&(movement.distance>0|raid_event.movement.in>remains|remains<=execute_time*2)
 if target.Refreshable(sunfire_debuff) and AstralPowerDeficit() >= 7 and target.TimeToDie() > 5.4 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(sunfire) } and { target.Distance() > 0 or 600 > target.DebuffRemaining(sunfire_debuff) or target.DebuffRemaining(sunfire_debuff) <= ExecuteTime(sunfire) * 2 } Spell(sunfire)
 #moonfire,target_if=refreshable,if=astral_power.deficit>=7&target.time_to_die>6.6&(!buff.celestial_alignment.up&!buff.incarnation.up|!variable.az_streak|!prev_gcd.1.moonfire)&(movement.distance>0|raid_event.movement.in>remains|remains<=execute_time*2)
 if target.Refreshable(moonfire_debuff) and AstralPowerDeficit() >= 7 and target.TimeToDie() > 6.6 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(moonfire) } and { target.Distance() > 0 or 600 > target.DebuffRemaining(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= ExecuteTime(moonfire) * 2 } Spell(moonfire)
 #stellar_flare,target_if=refreshable,if=astral_power.deficit>=12&target.time_to_die>7.2&(!buff.celestial_alignment.up&!buff.incarnation.up|!variable.az_streak|!prev_gcd.1.stellar_flare)
 if target.Refreshable(stellar_flare_debuff) and AstralPowerDeficit() >= 12 and target.TimeToDie() > 7.2 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(stellar_flare) } Spell(stellar_flare)
 #lunar_strike,if=astral_power.deficit>=16&(buff.lunar_empowerment.stack=3|(spell_targets<3&astral_power>=40&(buff.lunar_empowerment.stack=2&buff.solar_empowerment.stack=2)))&!(spell_targets.moonfire>=2&variable.az_potm=3&active_enemies=2)
 if AstralPowerDeficit() >= 16 and { BuffStacks(lunar_empowerment_buff) == 3 or Enemies() < 3 and AstralPower() >= 40 and BuffStacks(lunar_empowerment_buff) == 2 and BuffStacks(solar_empowerment_buff) == 2 } and not { Enemies() >= 2 and az_potm() == 3 and Enemies() == 2 } Spell(lunar_strike)
 #solar_wrath,if=astral_power.deficit>=12&(buff.solar_empowerment.stack=3|(variable.az_sb>1&spell_targets.starfall<3&astral_power>=32&!buff.sunblaze.up))&!(spell_targets.moonfire>=2&active_enemies<=4&variable.az_potm=3)|(variable.az_streak&(buff.celestial_alignment.up|buff.incarnation.up)&!prev_gcd.1.solar_wrath&astral_power.deficit>=12)
 if AstralPowerDeficit() >= 12 and { BuffStacks(solar_empowerment_buff) == 3 or az_sb() > 1 and Enemies() < 3 and AstralPower() >= 32 and not BuffPresent(sunblaze_buff) } and not { Enemies() >= 2 and Enemies() <= 4 and az_potm() == 3 } or az_streak() and { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and not PreviousGCDSpell(solar_wrath_balance) and AstralPowerDeficit() >= 12 Spell(solar_wrath_balance)
 #starsurge,if=(spell_targets.starfall<3&(!buff.starlord.up|buff.starlord.remains>=4)|execute_time*(astral_power%40)>target.time_to_die)&(!buff.celestial_alignment.up&!buff.incarnation.up|variable.az_streak<2|!prev_gcd.1.starsurge)&(raid_event.movement.in>(buff.lunar_empowerment.stack*action.lunar_strike.execute_time+buff.solar_empowerment.stack*action.solar_wrath.execute_time)|(astral_power+buff.lunar_empowerment.stack*12+buff.solar_empowerment.stack*8)>=96)
 if { Enemies() < 3 and { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 } or ExecuteTime(starsurge_balance) * { AstralPower() / 40 } > target.TimeToDie() } and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(starsurge_balance) } and { 600 > BuffStacks(lunar_empowerment_buff) * ExecuteTime(lunar_strike) + BuffStacks(solar_empowerment_buff) * ExecuteTime(solar_wrath_balance) or AstralPower() + BuffStacks(lunar_empowerment_buff) * 12 + BuffStacks(solar_empowerment_buff) * 8 >= 96 } Spell(starsurge_balance)
 #starfall,if=spell_targets.starfall>=3&(!buff.starlord.up|buff.starlord.remains>=4)
 if Enemies() >= 3 and { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 } Spell(starfall)
 #new_moon,if=astral_power.deficit>10+execute_time%1.5
 if AstralPowerDeficit() > 10 + ExecuteTime(new_moon) / 1.5 and not SpellKnown(half_moon) and not SpellKnown(full_moon) Spell(new_moon)
 #half_moon,if=astral_power.deficit>20+execute_time%1.5
 if AstralPowerDeficit() > 20 + ExecuteTime(half_moon) / 1.5 and SpellKnown(half_moon) Spell(half_moon)
 #full_moon,if=astral_power.deficit>40+execute_time%1.5
 if AstralPowerDeficit() > 40 + ExecuteTime(full_moon) / 1.5 and SpellKnown(full_moon) Spell(full_moon)
 #lunar_strike,if=((buff.warrior_of_elune.up|buff.lunar_empowerment.up|spell_targets>=3&!buff.solar_empowerment.up)&(!buff.celestial_alignment.up&!buff.incarnation.up|variable.az_streak<2|!prev_gcd.1.lunar_strike)|(variable.az_ds&!buff.dawning_sun.up))&!(spell_targets.moonfire>=2&active_enemies<=4&(variable.az_potm=3|variable.az_potm=2&active_enemies=2))
 if { { BuffPresent(warrior_of_elune_buff) or BuffPresent(lunar_empowerment_buff) or Enemies() >= 3 and not BuffPresent(solar_empowerment_buff) } and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(lunar_strike) } or az_ds() and not BuffPresent(dawning_sun_buff) } and not { Enemies() >= 2 and Enemies() <= 4 and { az_potm() == 3 or az_potm() == 2 and Enemies() == 2 } } Spell(lunar_strike)
 #solar_wrath,if=(!buff.celestial_alignment.up&!buff.incarnation.up|variable.az_streak<2|!prev_gcd.1.solar_wrath)&!(spell_targets.moonfire>=2&active_enemies<=4&(variable.az_potm=3|variable.az_potm=2&active_enemies=2))
 if { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(solar_wrath_balance) } and not { Enemies() >= 2 and Enemies() <= 4 and { az_potm() == 3 or az_potm() == 2 and Enemies() == 2 } } Spell(solar_wrath_balance)
 #sunfire,if=(!buff.celestial_alignment.up&!buff.incarnation.up|!variable.az_streak|!prev_gcd.1.sunfire)&!(variable.az_potm>=2&spell_targets.moonfire>=2)
 if { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(sunfire) } and not { az_potm() >= 2 and Enemies() >= 2 } Spell(sunfire)
 #moonfire
 Spell(moonfire)
}

AddFunction BalanceDefaultMainPostConditions
{
}

AddFunction BalanceDefaultShortCdActions
{
 #warrior_of_elune
 Spell(warrior_of_elune)
 #fury_of_elune,if=(((raid_event.adds.duration%8)*(4)<(raid_event.adds.in%60))|(raid_event.adds.up))&((buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30))
 if { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation_chosen_of_elune) > 30 } Spell(fury_of_elune)
 #force_of_nature,if=(buff.celestial_alignment.up|buff.incarnation.up)|(cooldown.celestial_alignment.remains>30|cooldown.incarnation.remains>30)
 if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation_chosen_of_elune) > 30 Spell(force_of_nature)
}

AddFunction BalanceDefaultShortCdPostConditions
{
 target.Refreshable(sunfire_debuff) and AstralPowerDeficit() >= 7 and target.TimeToDie() > 5.4 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(sunfire) } and { target.Distance() > 0 or 600 > target.DebuffRemaining(sunfire_debuff) or target.DebuffRemaining(sunfire_debuff) <= ExecuteTime(sunfire) * 2 } and Spell(sunfire) or target.Refreshable(moonfire_debuff) and AstralPowerDeficit() >= 7 and target.TimeToDie() > 6.6 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(moonfire) } and { target.Distance() > 0 or 600 > target.DebuffRemaining(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= ExecuteTime(moonfire) * 2 } and Spell(moonfire) or target.Refreshable(stellar_flare_debuff) and AstralPowerDeficit() >= 12 and target.TimeToDie() > 7.2 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(stellar_flare) } and Spell(stellar_flare) or AstralPowerDeficit() >= 16 and { BuffStacks(lunar_empowerment_buff) == 3 or Enemies() < 3 and AstralPower() >= 40 and BuffStacks(lunar_empowerment_buff) == 2 and BuffStacks(solar_empowerment_buff) == 2 } and not { Enemies() >= 2 and az_potm() == 3 and Enemies() == 2 } and Spell(lunar_strike) or { AstralPowerDeficit() >= 12 and { BuffStacks(solar_empowerment_buff) == 3 or az_sb() > 1 and Enemies() < 3 and AstralPower() >= 32 and not BuffPresent(sunblaze_buff) } and not { Enemies() >= 2 and Enemies() <= 4 and az_potm() == 3 } or az_streak() and { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and not PreviousGCDSpell(solar_wrath_balance) and AstralPowerDeficit() >= 12 } and Spell(solar_wrath_balance) or { Enemies() < 3 and { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 } or ExecuteTime(starsurge_balance) * { AstralPower() / 40 } > target.TimeToDie() } and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(starsurge_balance) } and { 600 > BuffStacks(lunar_empowerment_buff) * ExecuteTime(lunar_strike) + BuffStacks(solar_empowerment_buff) * ExecuteTime(solar_wrath_balance) or AstralPower() + BuffStacks(lunar_empowerment_buff) * 12 + BuffStacks(solar_empowerment_buff) * 8 >= 96 } and Spell(starsurge_balance) or Enemies() >= 3 and { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 } and Spell(starfall) or AstralPowerDeficit() > 10 + ExecuteTime(new_moon) / 1.5 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 20 + ExecuteTime(half_moon) / 1.5 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 40 + ExecuteTime(full_moon) / 1.5 and SpellKnown(full_moon) and Spell(full_moon) or { { BuffPresent(warrior_of_elune_buff) or BuffPresent(lunar_empowerment_buff) or Enemies() >= 3 and not BuffPresent(solar_empowerment_buff) } and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(lunar_strike) } or az_ds() and not BuffPresent(dawning_sun_buff) } and not { Enemies() >= 2 and Enemies() <= 4 and { az_potm() == 3 or az_potm() == 2 and Enemies() == 2 } } and Spell(lunar_strike) or { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(solar_wrath_balance) } and not { Enemies() >= 2 and Enemies() <= 4 and { az_potm() == 3 or az_potm() == 2 and Enemies() == 2 } } and Spell(solar_wrath_balance) or { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(sunfire) } and not { az_potm() >= 2 and Enemies() >= 2 } and Spell(sunfire) or Spell(moonfire)
}

AddFunction BalanceDefaultCdActions
{
 #potion,if=buff.celestial_alignment.up|buff.incarnation.up
 if { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(rising_death usable=1)
 #blood_fury,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(blood_fury)
 #berserking,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(berserking)
 #arcane_torrent,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(arcane_torrent_energy)
 #lights_judgment,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(lights_judgment)
 #fireblood,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(fireblood)
 #ancestral_call,if=buff.celestial_alignment.up|buff.incarnation.up
 if BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) Spell(ancestral_call)
 #use_items
 BalanceUseItemActions()

 unless Spell(warrior_of_elune)
 {
  #innervate,if=azerite.lively_spirit.enabled&(cooldown.incarnation.up|cooldown.celestial_alignment.remains<12)&(((raid_event.adds.duration%15)*(4)<(raid_event.adds.in%180))|(raid_event.adds.up))
  if HasAzeriteTrait(lively_spirit_trait) and { not SpellCooldown(incarnation_chosen_of_elune) > 0 or SpellCooldown(celestial_alignment) < 12 } and { 10 / 15 * 4 < 600 / 180 or False(raid_event_adds_exists) } Spell(innervate)
  #incarnation,if=astral_power>=40&(((raid_event.adds.duration%30)*(4)<(raid_event.adds.in%180))|(raid_event.adds.up))
  if AstralPower() >= 40 and { 10 / 30 * 4 < 600 / 180 or False(raid_event_adds_exists) } Spell(incarnation_chosen_of_elune)
  #celestial_alignment,if=astral_power>=40&(!azerite.lively_spirit.enabled|buff.lively_spirit.up)&(((raid_event.adds.duration%15)*(4)<(raid_event.adds.in%180))|(raid_event.adds.up))
  if AstralPower() >= 40 and { not HasAzeriteTrait(lively_spirit_trait) or BuffPresent(lively_spirit_buff) } and { 10 / 15 * 4 < 600 / 180 or False(raid_event_adds_exists) } Spell(celestial_alignment)
 }
}

AddFunction BalanceDefaultCdPostConditions
{
 Spell(warrior_of_elune) or { 10 / 8 * 4 < 600 / 60 or False(raid_event_adds_exists) } and { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation_chosen_of_elune) > 30 } and Spell(fury_of_elune) or { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) or SpellCooldown(celestial_alignment) > 30 or SpellCooldown(incarnation_chosen_of_elune) > 30 } and Spell(force_of_nature) or target.Refreshable(sunfire_debuff) and AstralPowerDeficit() >= 7 and target.TimeToDie() > 5.4 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(sunfire) } and { target.Distance() > 0 or 600 > target.DebuffRemaining(sunfire_debuff) or target.DebuffRemaining(sunfire_debuff) <= ExecuteTime(sunfire) * 2 } and Spell(sunfire) or target.Refreshable(moonfire_debuff) and AstralPowerDeficit() >= 7 and target.TimeToDie() > 6.6 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(moonfire) } and { target.Distance() > 0 or 600 > target.DebuffRemaining(moonfire_debuff) or target.DebuffRemaining(moonfire_debuff) <= ExecuteTime(moonfire) * 2 } and Spell(moonfire) or target.Refreshable(stellar_flare_debuff) and AstralPowerDeficit() >= 12 and target.TimeToDie() > 7.2 and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(stellar_flare) } and Spell(stellar_flare) or AstralPowerDeficit() >= 16 and { BuffStacks(lunar_empowerment_buff) == 3 or Enemies() < 3 and AstralPower() >= 40 and BuffStacks(lunar_empowerment_buff) == 2 and BuffStacks(solar_empowerment_buff) == 2 } and not { Enemies() >= 2 and az_potm() == 3 and Enemies() == 2 } and Spell(lunar_strike) or { AstralPowerDeficit() >= 12 and { BuffStacks(solar_empowerment_buff) == 3 or az_sb() > 1 and Enemies() < 3 and AstralPower() >= 32 and not BuffPresent(sunblaze_buff) } and not { Enemies() >= 2 and Enemies() <= 4 and az_potm() == 3 } or az_streak() and { BuffPresent(celestial_alignment_buff) or BuffPresent(incarnation_chosen_of_elune_buff) } and not PreviousGCDSpell(solar_wrath_balance) and AstralPowerDeficit() >= 12 } and Spell(solar_wrath_balance) or { Enemies() < 3 and { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 } or ExecuteTime(starsurge_balance) * { AstralPower() / 40 } > target.TimeToDie() } and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(starsurge_balance) } and { 600 > BuffStacks(lunar_empowerment_buff) * ExecuteTime(lunar_strike) + BuffStacks(solar_empowerment_buff) * ExecuteTime(solar_wrath_balance) or AstralPower() + BuffStacks(lunar_empowerment_buff) * 12 + BuffStacks(solar_empowerment_buff) * 8 >= 96 } and Spell(starsurge_balance) or Enemies() >= 3 and { not BuffPresent(starlord_buff) or BuffRemaining(starlord_buff) >= 4 } and Spell(starfall) or AstralPowerDeficit() > 10 + ExecuteTime(new_moon) / 1.5 and not SpellKnown(half_moon) and not SpellKnown(full_moon) and Spell(new_moon) or AstralPowerDeficit() > 20 + ExecuteTime(half_moon) / 1.5 and SpellKnown(half_moon) and Spell(half_moon) or AstralPowerDeficit() > 40 + ExecuteTime(full_moon) / 1.5 and SpellKnown(full_moon) and Spell(full_moon) or { { BuffPresent(warrior_of_elune_buff) or BuffPresent(lunar_empowerment_buff) or Enemies() >= 3 and not BuffPresent(solar_empowerment_buff) } and { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(lunar_strike) } or az_ds() and not BuffPresent(dawning_sun_buff) } and not { Enemies() >= 2 and Enemies() <= 4 and { az_potm() == 3 or az_potm() == 2 and Enemies() == 2 } } and Spell(lunar_strike) or { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or az_streak() < 2 or not PreviousGCDSpell(solar_wrath_balance) } and not { Enemies() >= 2 and Enemies() <= 4 and { az_potm() == 3 or az_potm() == 2 and Enemies() == 2 } } and Spell(solar_wrath_balance) or { not BuffPresent(celestial_alignment_buff) and not BuffPresent(incarnation_chosen_of_elune_buff) or not az_streak() or not PreviousGCDSpell(sunfire) } and not { az_potm() >= 2 and Enemies() >= 2 } and Spell(sunfire) or Spell(moonfire)
}

### Balance icons.

AddCheckBox(opt_druid_balance_aoe L(AOE) default specialization=balance)

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=shortcd specialization=balance
{
 if not InCombat() BalancePrecombatShortCdActions()
 unless not InCombat() and BalancePrecombatShortCdPostConditions()
 {
  BalanceDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_druid_balance_aoe help=shortcd specialization=balance
{
 if not InCombat() BalancePrecombatShortCdActions()
 unless not InCombat() and BalancePrecombatShortCdPostConditions()
 {
  BalanceDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=balance
{
 if not InCombat() BalancePrecombatMainActions()
 unless not InCombat() and BalancePrecombatMainPostConditions()
 {
  BalanceDefaultMainActions()
 }
}

AddIcon checkbox=opt_druid_balance_aoe help=aoe specialization=balance
{
 if not InCombat() BalancePrecombatMainActions()
 unless not InCombat() and BalancePrecombatMainPostConditions()
 {
  BalanceDefaultMainActions()
 }
}

AddIcon checkbox=!opt_druid_balance_aoe enemies=1 help=cd specialization=balance
{
 if not InCombat() BalancePrecombatCdActions()
 unless not InCombat() and BalancePrecombatCdPostConditions()
 {
  BalanceDefaultCdActions()
 }
}

AddIcon checkbox=opt_druid_balance_aoe help=cd specialization=balance
{
 if not InCombat() BalancePrecombatCdActions()
 unless not InCombat() and BalancePrecombatCdPostConditions()
 {
  BalanceDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_energy
# berserking
# blood_fury
# celestial_alignment
# celestial_alignment_buff
# dawning_sun_buff
# dawning_sun_trait
# fireblood
# force_of_nature
# full_moon
# fury_of_elune
# half_moon
# incarnation_chosen_of_elune
# incarnation_chosen_of_elune_buff
# innervate
# lights_judgment
# lively_spirit_buff
# lively_spirit_trait
# lunar_empowerment_buff
# lunar_strike
# moonfire
# moonfire_debuff
# moonkin_form_balance
# new_moon
# power_of_the_moon_trait
# rising_death
# solar_empowerment_buff
# solar_wrath_balance
# starfall
# starlord_buff
# starsurge_balance
# stellar_flare
# stellar_flare_debuff
# streaking_stars_trait
# sunblaze_buff
# sunblaze_trait
# sunfire
# sunfire_debuff
# twin_moons_talent
# warrior_of_elune
# warrior_of_elune_buff
]]
    OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
end
do
    local name = "sc_pr_druid_feral"
    local desc = "[8.0] Simulationcraft: PR_Druid_Feral"
    local code = [[
# Based on SimulationCraft profile "PR_Druid_Feral".
#	class=druid
#	spec=feral
#	talents=3000212

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)


AddFunction use_thrash
{
 if HasEquippedItem(luffa_wrappings_item) 1
 0
}

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=feral)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=feral)

AddFunction FeralUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction FeralGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
 {
  if target.InRange(wild_charge) Spell(wild_charge)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.st_generators

AddFunction FeralStgeneratorsMainActions
{
 #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points=4&dot.rake.remains<4
 if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 Spell(regrowth)
 #regrowth,if=equipped.ailuro_pouncers&talent.bloodtalons.enabled&(buff.predatory_swiftness.stack>2|(buff.predatory_swiftness.stack>1&dot.rake.remains<3))&buff.bloodtalons.down
 if HasEquippedItem(ailuro_pouncers_item) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) Spell(regrowth)
 #brutal_slash,if=spell_targets.brutal_slash>desired_targets
 if Enemies() > Enemies(tagged=1) Spell(brutal_slash)
 #pool_resource,for_next=1
 #thrash_cat,if=refreshable&(spell_targets.thrash_cat>2)
 if target.Refreshable(thrash_cat_debuff) and Enemies() > 2 Spell(thrash_cat)
 unless target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
 {
  #pool_resource,for_next=1
  #thrash_cat,if=spell_targets.thrash_cat>3&equipped.luffa_wrappings&talent.brutal_slash.enabled
  if Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) Spell(thrash_cat)
  unless Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
  {
   #pool_resource,for_next=1
   #rake,target_if=!ticking|(!talent.bloodtalons.enabled&remains<duration*0.3)&target.time_to_die>4
   if not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 Spell(rake)
   unless { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake)
   {
    #pool_resource,for_next=1
    #rake,target_if=talent.bloodtalons.enabled&buff.bloodtalons.up&((remains<=7)&persistent_multiplier>dot.rake.pmultiplier*0.85)&target.time_to_die>4
    if Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 Spell(rake)
    unless Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake)
    {
     #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
     if BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) Spell(brutal_slash)
     #moonfire_cat,target_if=refreshable
     if target.Refreshable(moonfire_cat_debuff) Spell(moonfire_cat)
     #pool_resource,for_next=1
     #thrash_cat,if=refreshable&(variable.use_thrash=2|spell_targets.thrash_cat>1)
     if target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } Spell(thrash_cat)
     unless target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
     {
      #thrash_cat,if=refreshable&variable.use_thrash=1&buff.clearcasting.react
      if target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) Spell(thrash_cat)
      #pool_resource,for_next=1
      #swipe_cat,if=spell_targets.swipe_cat>1
      if Enemies() > 1 Spell(swipe_cat)
      unless Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat)
      {
       #shred,if=dot.rake.remains>(action.shred.cost+action.rake.cost-energy)%energy.regen|buff.clearcasting.react
       if target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) Spell(shred)
      }
     }
    }
   }
  }
 }
}

AddFunction FeralStgeneratorsMainPostConditions
{
}

AddFunction FeralStgeneratorsShortCdActions
{
}

AddFunction FeralStgeneratorsShortCdPostConditions
{
 Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 and Spell(regrowth) or HasEquippedItem(ailuro_pouncers_item) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) and Spell(regrowth) or Enemies() > Enemies(tagged=1) and Spell(brutal_slash) or target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and Spell(thrash_cat) or not { Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and Spell(rake) or not { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and Spell(rake) or not { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) and Spell(brutal_slash) or target.Refreshable(moonfire_cat_debuff) and Spell(moonfire_cat) or target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) and Spell(thrash_cat) or Enemies() > 1 and Spell(swipe_cat) or not { Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) } and Spell(shred) } } } } }
}

AddFunction FeralStgeneratorsCdActions
{
}

AddFunction FeralStgeneratorsCdPostConditions
{
 Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 and Spell(regrowth) or HasEquippedItem(ailuro_pouncers_item) and Talent(bloodtalons_talent) and { BuffStacks(predatory_swiftness_buff) > 2 or BuffStacks(predatory_swiftness_buff) > 1 and target.DebuffRemaining(rake_debuff) < 3 } and BuffExpires(bloodtalons_buff) and Spell(regrowth) or Enemies() > Enemies(tagged=1) and Spell(brutal_slash) or target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and Enemies() > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and Spell(thrash_cat) or not { Enemies() > 3 and HasEquippedItem(luffa_wrappings_item) and Talent(brutal_slash_talent) and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and Spell(rake) or not { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and Spell(rake) or not { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) and Spell(brutal_slash) or target.Refreshable(moonfire_cat_debuff) and Spell(moonfire_cat) or target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 or Enemies() > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) and Spell(thrash_cat) or Enemies() > 1 and Spell(swipe_cat) or not { Enemies() > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) } and Spell(shred) } } } } }
}

### actions.st_finishers

AddFunction FeralStfinishersMainActions
{
 #pool_resource,for_next=1
 #savage_roar,if=buff.savage_roar.down
 if BuffExpires(savage_roar_buff) Spell(savage_roar)
 unless BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
 {
  #pool_resource,for_next=1
  #rip,target_if=!ticking|(remains<=duration*0.3)&(target.health.pct>25&!talent.sabertooth.enabled)|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier)&target.time_to_die>8
  if not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 Spell(rip)
  unless { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip)
  {
   #pool_resource,for_next=1
   #savage_roar,if=buff.savage_roar.remains<12
   if BuffRemaining(savage_roar_buff) < 12 Spell(savage_roar)
   unless BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
   {
    #ferocious_bite,max_energy=1
    if Energy() >= EnergyCost(ferocious_bite max=1) Spell(ferocious_bite)
   }
  }
 }
}

AddFunction FeralStfinishersMainPostConditions
{
}

AddFunction FeralStfinishersShortCdActions
{
}

AddFunction FeralStfinishersShortCdPostConditions
{
 BuffExpires(savage_roar_buff) and Spell(savage_roar) or not { BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and Spell(rip) or not { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip) } and { BuffRemaining(savage_roar_buff) < 12 and Spell(savage_roar) or not { BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and Energy() >= EnergyCost(ferocious_bite max=1) and Spell(ferocious_bite) } }
}

AddFunction FeralStfinishersCdActions
{
}

AddFunction FeralStfinishersCdPostConditions
{
 BuffExpires(savage_roar_buff) and Spell(savage_roar) or not { BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and Spell(rip) or not { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and target.HealthPercent() > 25 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip) } and { BuffRemaining(savage_roar_buff) < 12 and Spell(savage_roar) or not { BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and Energy() >= EnergyCost(ferocious_bite max=1) and Spell(ferocious_bite) } }
}

### actions.single_target

AddFunction FeralSingletargetMainActions
{
 #cat_form,if=!buff.cat_form.up
 if not BuffPresent(cat_form_buff) Spell(cat_form)
 #rake,if=buff.prowl.up|buff.shadowmeld.up
 if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
 #call_action_list,name=cooldowns
 FeralCooldownsMainActions()

 unless FeralCooldownsMainPostConditions()
 {
  #ferocious_bite,target_if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&(target.health.pct<25|talent.sabertooth.enabled)
  if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } Spell(ferocious_bite)
  #regrowth,if=combo_points=5&buff.predatory_swiftness.up&talent.bloodtalons.enabled&buff.bloodtalons.down&(!buff.incarnation.up|dot.rip.remains<8)
  if ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 } Spell(regrowth)
  #regrowth,if=combo_points>3&talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.apex_predator.up&buff.incarnation.down
  if ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and BuffExpires(incarnation_king_of_the_jungle_buff) Spell(regrowth)
  #ferocious_bite,if=buff.apex_predator.up&((combo_points>4&(buff.incarnation.up|talent.moment_of_clarity.enabled))|(talent.bloodtalons.enabled&buff.bloodtalons.up&combo_points>3))
  if BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { BuffPresent(incarnation_king_of_the_jungle_buff) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } Spell(ferocious_bite)
  #run_action_list,name=st_finishers,if=combo_points>4
  if ComboPoints() > 4 FeralStfinishersMainActions()

  unless ComboPoints() > 4 and FeralStfinishersMainPostConditions()
  {
   #run_action_list,name=st_generators
   FeralStgeneratorsMainActions()
  }
 }
}

AddFunction FeralSingletargetMainPostConditions
{
 FeralCooldownsMainPostConditions() or ComboPoints() > 4 and FeralStfinishersMainPostConditions() or FeralStgeneratorsMainPostConditions()
}

AddFunction FeralSingletargetShortCdActions
{
 unless not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
 {
  #auto_attack
  FeralGetInMeleeRange()
  #call_action_list,name=cooldowns
  FeralCooldownsShortCdActions()

  unless FeralCooldownsShortCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 } and Spell(regrowth) or ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and BuffExpires(incarnation_king_of_the_jungle_buff) and Spell(regrowth) or BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { BuffPresent(incarnation_king_of_the_jungle_buff) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } and Spell(ferocious_bite)
  {
   #run_action_list,name=st_finishers,if=combo_points>4
   if ComboPoints() > 4 FeralStfinishersShortCdActions()

   unless ComboPoints() > 4 and FeralStfinishersShortCdPostConditions()
   {
    #run_action_list,name=st_generators
    FeralStgeneratorsShortCdActions()
   }
  }
 }
}

AddFunction FeralSingletargetShortCdPostConditions
{
 not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or FeralCooldownsShortCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 } and Spell(regrowth) or ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and BuffExpires(incarnation_king_of_the_jungle_buff) and Spell(regrowth) or BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { BuffPresent(incarnation_king_of_the_jungle_buff) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } and Spell(ferocious_bite) or ComboPoints() > 4 and FeralStfinishersShortCdPostConditions() or FeralStgeneratorsShortCdPostConditions()
}

AddFunction FeralSingletargetCdActions
{
 unless not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
 {
  #call_action_list,name=cooldowns
  FeralCooldownsCdActions()

  unless FeralCooldownsCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 } and Spell(regrowth) or ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and BuffExpires(incarnation_king_of_the_jungle_buff) and Spell(regrowth) or BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { BuffPresent(incarnation_king_of_the_jungle_buff) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } and Spell(ferocious_bite)
  {
   #run_action_list,name=st_finishers,if=combo_points>4
   if ComboPoints() > 4 FeralStfinishersCdActions()

   unless ComboPoints() > 4 and FeralStfinishersCdPostConditions()
   {
    #run_action_list,name=st_generators
    FeralStgeneratorsCdActions()
   }
  }
 }
}

AddFunction FeralSingletargetCdPostConditions
{
 not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or FeralCooldownsCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and { target.HealthPercent() < 25 or Talent(sabertooth_talent) } and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or target.DebuffRemaining(rip_debuff) < 8 } and Spell(regrowth) or ComboPoints() > 3 and Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffPresent(apex_predator_buff) and BuffExpires(incarnation_king_of_the_jungle_buff) and Spell(regrowth) or BuffPresent(apex_predator_buff) and { ComboPoints() > 4 and { BuffPresent(incarnation_king_of_the_jungle_buff) or Talent(moment_of_clarity_talent) } or Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and ComboPoints() > 3 } and Spell(ferocious_bite) or ComboPoints() > 4 and FeralStfinishersCdPostConditions() or FeralStgeneratorsCdPostConditions()
}

### actions.precombat

AddFunction FeralPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #regrowth,if=talent.bloodtalons.enabled
 if Talent(bloodtalons_talent) Spell(regrowth)
 #variable,name=use_thrash,value=0
 #variable,name=use_thrash,value=1,if=equipped.luffa_wrappings
 #cat_form
 Spell(cat_form)
 #prowl
 Spell(prowl)
}

AddFunction FeralPrecombatMainPostConditions
{
}

AddFunction FeralPrecombatShortCdActions
{
}

AddFunction FeralPrecombatShortCdPostConditions
{
 Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form) or Spell(prowl)
}

AddFunction FeralPrecombatCdActions
{
 unless Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form) or Spell(prowl)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 }
}

AddFunction FeralPrecombatCdPostConditions
{
 Talent(bloodtalons_talent) and Spell(regrowth) or Spell(cat_form) or Spell(prowl)
}

### actions.cooldowns

AddFunction FeralCooldownsMainActions
{
 #prowl,if=buff.incarnation.remains<0.5&buff.jungle_stalker.up
 if BuffRemaining(incarnation_king_of_the_jungle_buff) < 0.5 and BuffPresent(jungle_stalker_buff) Spell(prowl)
}

AddFunction FeralCooldownsMainPostConditions
{
}

AddFunction FeralCooldownsShortCdActions
{
 unless BuffRemaining(incarnation_king_of_the_jungle_buff) < 0.5 and BuffPresent(jungle_stalker_buff) and Spell(prowl)
 {
  #tigers_fury,if=energy.deficit>=60
  if EnergyDeficit() >= 60 Spell(tigers_fury)
  #feral_frenzy,if=combo_points=0
  if ComboPoints() == 0 Spell(feral_frenzy)
 }
}

AddFunction FeralCooldownsShortCdPostConditions
{
 BuffRemaining(incarnation_king_of_the_jungle_buff) < 0.5 and BuffPresent(jungle_stalker_buff) and Spell(prowl)
}

AddFunction FeralCooldownsCdActions
{
 #dash,if=!buff.cat_form.up
 if not BuffPresent(cat_form_buff) Spell(dash)

 unless BuffRemaining(incarnation_king_of_the_jungle_buff) < 0.5 and BuffPresent(jungle_stalker_buff) and Spell(prowl)
 {
  #berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
  if Energy() >= 30 and { SpellCooldown(tigers_fury) > 5 or BuffPresent(tigers_fury_buff) } Spell(berserk)

  unless EnergyDeficit() >= 60 and Spell(tigers_fury)
  {
   #berserking
   Spell(berserking)

   unless ComboPoints() == 0 and Spell(feral_frenzy)
   {
    #incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
    if Energy() >= 30 and { SpellCooldown(tigers_fury) > 15 or BuffPresent(tigers_fury_buff) } Spell(incarnation_king_of_the_jungle)
    #potion,name=battle_potion_of_agility,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
    if { target.TimeToDie() < 65 or target.TimeToDie() < 180 and { BuffPresent(berserk_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
    #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
    if ComboPoints() < 5 and Energy() >= PowerCost(rake) and target.DebuffPersistentMultiplier(rake_debuff) < 2.1 and BuffPresent(tigers_fury_buff) and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { not Talent(incarnation_talent) or SpellCooldown(incarnation_king_of_the_jungle) > 18 } and not BuffPresent(incarnation_king_of_the_jungle_buff) Spell(shadowmeld)
    #use_items
    FeralUseItemActions()
   }
  }
 }
}

AddFunction FeralCooldownsCdPostConditions
{
 BuffRemaining(incarnation_king_of_the_jungle_buff) < 0.5 and BuffPresent(jungle_stalker_buff) and Spell(prowl) or EnergyDeficit() >= 60 and Spell(tigers_fury) or ComboPoints() == 0 and Spell(feral_frenzy)
}

### actions.default

AddFunction FeralDefaultMainActions
{
 #run_action_list,name=single_target,if=dot.rip.ticking|time>15
 if target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 FeralSingletargetMainActions()

 unless { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetMainPostConditions()
 {
  #rake,if=!ticking|buff.prowl.up
  if not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) Spell(rake)
  #moonfire_cat,if=talent.lunar_inspiration.enabled&!ticking
  if Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) Spell(moonfire_cat)
  #savage_roar,if=!buff.savage_roar.up
  if not BuffPresent(savage_roar_buff) Spell(savage_roar)
  #regrowth,if=(talent.sabertooth.enabled|buff.predatory_swiftness.up)&talent.bloodtalons.enabled&buff.bloodtalons.down&combo_points=5
  if { Talent(sabertooth_talent) or BuffPresent(predatory_swiftness_buff) } and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 Spell(regrowth)
  #rip,if=combo_points=5
  if ComboPoints() == 5 Spell(rip)
  #thrash_cat,if=!ticking&variable.use_thrash>0
  if not target.DebuffPresent(thrash_cat_debuff) and use_thrash() > 0 Spell(thrash_cat)
  #shred
  Spell(shred)
 }
}

AddFunction FeralDefaultMainPostConditions
{
 { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetMainPostConditions()
}

AddFunction FeralDefaultShortCdActions
{
 #run_action_list,name=single_target,if=dot.rip.ticking|time>15
 if target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 FeralSingletargetShortCdActions()

 unless { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetShortCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake)
 {
  #auto_attack
  FeralGetInMeleeRange()

  unless Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar)
  {
   #tigers_fury
   Spell(tigers_fury)
  }
 }
}

AddFunction FeralDefaultShortCdPostConditions
{
 { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetShortCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake) or Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar) or { Talent(sabertooth_talent) or BuffPresent(predatory_swiftness_buff) } and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 and Spell(regrowth) or ComboPoints() == 5 and Spell(rip) or not target.DebuffPresent(thrash_cat_debuff) and use_thrash() > 0 and Spell(thrash_cat) or Spell(shred)
}

AddFunction FeralDefaultCdActions
{
 #run_action_list,name=single_target,if=dot.rip.ticking|time>15
 if target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 FeralSingletargetCdActions()

 unless { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake)
 {
  #dash,if=!buff.cat_form.up
  if not BuffPresent(cat_form_buff) Spell(dash)

  unless Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar)
  {
   #berserk
   Spell(berserk)
   #incarnation
   Spell(incarnation_king_of_the_jungle)
  }
 }
}

AddFunction FeralDefaultCdPostConditions
{
 { target.DebuffPresent(rip_debuff) or TimeInCombat() > 15 } and FeralSingletargetCdPostConditions() or { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake) or Talent(lunar_inspiration_talent) and not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not BuffPresent(savage_roar_buff) and Spell(savage_roar) or Spell(tigers_fury) or { Talent(sabertooth_talent) or BuffPresent(predatory_swiftness_buff) } and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and ComboPoints() == 5 and Spell(regrowth) or ComboPoints() == 5 and Spell(rip) or not target.DebuffPresent(thrash_cat_debuff) and use_thrash() > 0 and Spell(thrash_cat) or Spell(shred)
}

### Feral icons.

AddCheckBox(opt_druid_feral_aoe L(AOE) default specialization=feral)

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=shortcd specialization=feral
{
 if not InCombat() FeralPrecombatShortCdActions()
 unless not InCombat() and FeralPrecombatShortCdPostConditions()
 {
  FeralDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_druid_feral_aoe help=shortcd specialization=feral
{
 if not InCombat() FeralPrecombatShortCdActions()
 unless not InCombat() and FeralPrecombatShortCdPostConditions()
 {
  FeralDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=feral
{
 if not InCombat() FeralPrecombatMainActions()
 unless not InCombat() and FeralPrecombatMainPostConditions()
 {
  FeralDefaultMainActions()
 }
}

AddIcon checkbox=opt_druid_feral_aoe help=aoe specialization=feral
{
 if not InCombat() FeralPrecombatMainActions()
 unless not InCombat() and FeralPrecombatMainPostConditions()
 {
  FeralDefaultMainActions()
 }
}

AddIcon checkbox=!opt_druid_feral_aoe enemies=1 help=cd specialization=feral
{
 if not InCombat() FeralPrecombatCdActions()
 unless not InCombat() and FeralPrecombatCdPostConditions()
 {
  FeralDefaultCdActions()
 }
}

AddIcon checkbox=opt_druid_feral_aoe help=cd specialization=feral
{
 if not InCombat() FeralPrecombatCdActions()
 unless not InCombat() and FeralPrecombatCdPostConditions()
 {
  FeralDefaultCdActions()
 }
}

### Required symbols
# ailuro_pouncers_item
# apex_predator_buff
# battle_potion_of_agility
# berserk
# berserk_buff
# berserking
# bloodtalons_buff
# bloodtalons_talent
# brutal_slash
# brutal_slash_talent
# cat_form
# cat_form_buff
# clearcasting_buff
# dash
# feral_frenzy
# ferocious_bite
# incarnation_king_of_the_jungle
# incarnation_king_of_the_jungle_buff
# incarnation_talent
# jungle_stalker_buff
# luffa_wrappings_item
# lunar_inspiration_talent
# mangle
# moment_of_clarity_talent
# moonfire_cat
# moonfire_cat_debuff
# predatory_swiftness_buff
# prowl
# prowl_buff
# rake
# rake_debuff
# regrowth
# rip
# rip_debuff
# sabertooth_talent
# savage_roar
# savage_roar_buff
# shadowmeld
# shadowmeld_buff
# shred
# swipe_cat
# thrash_cat
# thrash_cat_debuff
# tigers_fury
# tigers_fury_buff
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
    OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
end
do
    local name = "sc_pr_druid_guardian"
    local desc = "[8.0] Simulationcraft: PR_Druid_Guardian"
    local code = [[
# Based on SimulationCraft profile "PR_Druid_Guardian".
#	class=druid
#	spec=guardian
#	talents=1111123

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=guardian)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=guardian)

AddFunction GuardianUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction GuardianGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
 {
  if target.InRange(wild_charge) Spell(wild_charge)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.precombat

AddFunction GuardianPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #bear_form
 Spell(bear_form)
}

AddFunction GuardianPrecombatMainPostConditions
{
}

AddFunction GuardianPrecombatShortCdActions
{
}

AddFunction GuardianPrecombatShortCdPostConditions
{
 Spell(bear_form)
}

AddFunction GuardianPrecombatCdActions
{
 unless Spell(bear_form)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war usable=1)
 }
}

AddFunction GuardianPrecombatCdPostConditions
{
 Spell(bear_form)
}

### actions.cooldowns

AddFunction GuardianCooldownsMainActions
{
}

AddFunction GuardianCooldownsMainPostConditions
{
}

AddFunction GuardianCooldownsShortCdActions
{
 #barkskin,if=buff.bear_form.up
 if DebuffPresent(bear_form) Spell(barkskin)
 #lunar_beam,if=buff.bear_form.up
 if DebuffPresent(bear_form) Spell(lunar_beam)
 #bristling_fur,if=buff.bear_form.up
 if DebuffPresent(bear_form) Spell(bristling_fur)
}

AddFunction GuardianCooldownsShortCdPostConditions
{
}

AddFunction GuardianCooldownsCdActions
{
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(old_war usable=1)
 #blood_fury
 Spell(blood_fury)
 #berserking
 Spell(berserking)
 #arcane_torrent
 Spell(arcane_torrent_energy)
 #lights_judgment
 Spell(lights_judgment)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)

 unless DebuffPresent(bear_form) and Spell(barkskin) or DebuffPresent(bear_form) and Spell(lunar_beam) or DebuffPresent(bear_form) and Spell(bristling_fur)
 {
  #use_items
  GuardianUseItemActions()
 }
}

AddFunction GuardianCooldownsCdPostConditions
{
 DebuffPresent(bear_form) and Spell(barkskin) or DebuffPresent(bear_form) and Spell(lunar_beam) or DebuffPresent(bear_form) and Spell(bristling_fur)
}

### actions.default

AddFunction GuardianDefaultMainActions
{
 #call_action_list,name=cooldowns
 GuardianCooldownsMainActions()

 unless GuardianCooldownsMainPostConditions()
 {
  #maul,if=rage.deficit<10&active_enemies<4
  if RageDeficit() < 10 and Enemies() < 4 Spell(maul)
  #pulverize,target_if=dot.thrash_bear.stack=dot.thrash_bear.max_stacks
  if target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) Spell(pulverize)
  #moonfire,target_if=dot.moonfire.refreshable&active_enemies<2
  if target.DebuffRefreshable(moonfire_debuff) and Enemies() < 2 Spell(moonfire)
  #thrash,if=(buff.incarnation.down&active_enemies>1)|(buff.incarnation.up&active_enemies>4)
  if BuffExpires(incarnation_guardian_of_ursoc_buff) and Enemies() > 1 or BuffPresent(incarnation_guardian_of_ursoc_buff) and Enemies() > 4 Spell(thrash)
  #swipe,if=buff.incarnation.down&active_enemies>4
  if BuffExpires(incarnation_guardian_of_ursoc_buff) and Enemies() > 4 Spell(swipe)
  #mangle,if=dot.thrash_bear.ticking
  if target.DebuffPresent(thrash_bear_debuff) Spell(mangle)
  #moonfire,target_if=buff.galactic_guardian.up&active_enemies<2
  if BuffPresent(galactic_guardian_buff) and Enemies() < 2 Spell(moonfire)
  #thrash
  Spell(thrash)
  #maul
  Spell(maul)
  #swipe
  Spell(swipe)
 }
}

AddFunction GuardianDefaultMainPostConditions
{
 GuardianCooldownsMainPostConditions()
}

AddFunction GuardianDefaultShortCdActions
{
 #auto_attack
 GuardianGetInMeleeRange()
 #call_action_list,name=cooldowns
 GuardianCooldownsShortCdActions()
}

AddFunction GuardianDefaultShortCdPostConditions
{
 GuardianCooldownsShortCdPostConditions() or RageDeficit() < 10 and Enemies() < 4 and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and Enemies() < 2 and Spell(moonfire) or { BuffExpires(incarnation_guardian_of_ursoc_buff) and Enemies() > 1 or BuffPresent(incarnation_guardian_of_ursoc_buff) and Enemies() > 4 } and Spell(thrash) or BuffExpires(incarnation_guardian_of_ursoc_buff) and Enemies() > 4 and Spell(swipe) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and Enemies() < 2 and Spell(moonfire) or Spell(thrash) or Spell(maul) or Spell(swipe)
}

AddFunction GuardianDefaultCdActions
{
 #call_action_list,name=cooldowns
 GuardianCooldownsCdActions()

 unless GuardianCooldownsCdPostConditions() or RageDeficit() < 10 and Enemies() < 4 and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and Enemies() < 2 and Spell(moonfire)
 {
  #incarnation
  Spell(incarnation_guardian_of_ursoc)
 }
}

AddFunction GuardianDefaultCdPostConditions
{
 GuardianCooldownsCdPostConditions() or RageDeficit() < 10 and Enemies() < 4 and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and Enemies() < 2 and Spell(moonfire) or { BuffExpires(incarnation_guardian_of_ursoc_buff) and Enemies() > 1 or BuffPresent(incarnation_guardian_of_ursoc_buff) and Enemies() > 4 } and Spell(thrash) or BuffExpires(incarnation_guardian_of_ursoc_buff) and Enemies() > 4 and Spell(swipe) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and Enemies() < 2 and Spell(moonfire) or Spell(thrash) or Spell(maul) or Spell(swipe)
}

### Guardian icons.

AddCheckBox(opt_druid_guardian_aoe L(AOE) default specialization=guardian)

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=shortcd specialization=guardian
{
 if not InCombat() GuardianPrecombatShortCdActions()
 unless not InCombat() and GuardianPrecombatShortCdPostConditions()
 {
  GuardianDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_druid_guardian_aoe help=shortcd specialization=guardian
{
 if not InCombat() GuardianPrecombatShortCdActions()
 unless not InCombat() and GuardianPrecombatShortCdPostConditions()
 {
  GuardianDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=guardian
{
 if not InCombat() GuardianPrecombatMainActions()
 unless not InCombat() and GuardianPrecombatMainPostConditions()
 {
  GuardianDefaultMainActions()
 }
}

AddIcon checkbox=opt_druid_guardian_aoe help=aoe specialization=guardian
{
 if not InCombat() GuardianPrecombatMainActions()
 unless not InCombat() and GuardianPrecombatMainPostConditions()
 {
  GuardianDefaultMainActions()
 }
}

AddIcon checkbox=!opt_druid_guardian_aoe enemies=1 help=cd specialization=guardian
{
 if not InCombat() GuardianPrecombatCdActions()
 unless not InCombat() and GuardianPrecombatCdPostConditions()
 {
  GuardianDefaultCdActions()
 }
}

AddIcon checkbox=opt_druid_guardian_aoe help=cd specialization=guardian
{
 if not InCombat() GuardianPrecombatCdActions()
 unless not InCombat() and GuardianPrecombatCdPostConditions()
 {
  GuardianDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# arcane_torrent_energy
# barkskin
# bear_form
# berserking
# blood_fury
# bristling_fur
# fireblood
# galactic_guardian_buff
# incarnation_guardian_of_ursoc
# incarnation_guardian_of_ursoc_buff
# lights_judgment
# lunar_beam
# mangle
# maul
# moonfire
# moonfire_debuff
# old_war
# pulverize
# shred
# swipe
# thrash
# thrash_bear_debuff
# wild_charge
# wild_charge_bear
# wild_charge_cat
]]
    OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
end
