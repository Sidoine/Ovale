local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_warrior_arms"
    local desc = "[8.1] Simulationcraft: PR_Warrior_Arms"
    local code = [[
# Based on SimulationCraft profile "PR_Warrior_Arms".
#	class=warrior
#	spec=arms
#	talents=3112211

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=arms)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=arms)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=arms)

AddFunction ArmsInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(pummel) and target.IsInterruptible() Spell(pummel)
  if target.InRange(storm_bolt) and not target.Classification(worldboss) Spell(storm_bolt)
  if target.Distance(less 10) and not target.Classification(worldboss) Spell(shockwave)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(intimidating_shout) and not target.Classification(worldboss) Spell(intimidating_shout)
 }
}

AddFunction ArmsGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not InFlightToTarget(charge) and not InFlightToTarget(heroic_leap) and not target.InRange(pummel)
 {
  if target.InRange(charge) Spell(charge)
  if SpellCharges(charge) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.single_target

AddFunction ArmsSingletargetMainActions
{
 #rend,if=remains<=duration*0.3&debuff.colossus_smash.down
 if target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and target.DebuffExpires(colossus_smash_debuff) Spell(rend)
 #skullsplitter,if=rage<60&(!talent.deadly_calm.enabled|buff.deadly_calm.down)
 if Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } Spell(skullsplitter)
 #colossus_smash,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(colossus_smash)
 #warbreaker,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(warbreaker)
 #execute,if=buff.sudden_death.react
 if BuffPresent(sudden_death_arms_buff) Spell(execute_arms)
 #cleave,if=spell_targets.whirlwind>2
 if Enemies() > 2 Spell(cleave)
 #overpower,if=azerite.seismic_wave.rank=3
 if AzeriteTraitRank(seismic_wave_trait) == 3 Spell(overpower)
 #mortal_strike
 Spell(mortal_strike)
 #whirlwind,if=talent.fervor_of_battle.enabled&(buff.deadly_calm.up|rage>=60)
 if Talent(fervor_of_battle_talent) and { BuffPresent(deadly_calm_buff) or Rage() >= 60 } Spell(whirlwind_arms)
 #overpower
 Spell(overpower)
 #whirlwind,if=talent.fervor_of_battle.enabled&(!azerite.test_of_might.enabled|debuff.colossus_smash.up)
 if Talent(fervor_of_battle_talent) and { not HasAzeriteTrait(test_of_might_trait) or target.DebuffPresent(colossus_smash_debuff) } Spell(whirlwind_arms)
 #slam,if=!talent.fervor_of_battle.enabled&(!azerite.test_of_might.enabled|debuff.colossus_smash.up|buff.deadly_calm.up|rage>=60)
 if not Talent(fervor_of_battle_talent) and { not HasAzeriteTrait(test_of_might_trait) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(deadly_calm_buff) or Rage() >= 60 } Spell(slam)
}

AddFunction ArmsSingletargetMainPostConditions
{
}

AddFunction ArmsSingletargetShortCdActions
{
 unless target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter)
 {
  #ravager,if=!buff.deadly_calm.up&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if not BuffPresent(deadly_calm_buff) and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } Spell(ravager)

  unless target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker)
  {
   #deadly_calm
   Spell(deadly_calm)

   unless BuffPresent(sudden_death_arms_buff) and Spell(execute_arms)
   {
    #bladestorm,if=cooldown.mortal_strike.remains&(!talent.deadly_calm.enabled|buff.deadly_calm.down)&((debuff.colossus_smash.up&!azerite.test_of_might.enabled)|buff.test_of_might.up)
    if SpellCooldown(mortal_strike) > 0 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and { target.DebuffPresent(colossus_smash_debuff) and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } Spell(bladestorm_arms)
   }
  }
 }
}

AddFunction ArmsSingletargetShortCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or BuffPresent(sudden_death_arms_buff) and Spell(execute_arms) or Enemies() > 2 and Spell(cleave) or AzeriteTraitRank(seismic_wave_trait) == 3 and Spell(overpower) or Spell(mortal_strike) or Talent(fervor_of_battle_talent) and { BuffPresent(deadly_calm_buff) or Rage() >= 60 } and Spell(whirlwind_arms) or Spell(overpower) or Talent(fervor_of_battle_talent) and { not HasAzeriteTrait(test_of_might_trait) or target.DebuffPresent(colossus_smash_debuff) } and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and { not HasAzeriteTrait(test_of_might_trait) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(deadly_calm_buff) or Rage() >= 60 } and Spell(slam)
}

AddFunction ArmsSingletargetCdActions
{
}

AddFunction ArmsSingletargetCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter) or not BuffPresent(deadly_calm_buff) and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } and Spell(ravager) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or Spell(deadly_calm) or BuffPresent(sudden_death_arms_buff) and Spell(execute_arms) or SpellCooldown(mortal_strike) > 0 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and { target.DebuffPresent(colossus_smash_debuff) and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } and Spell(bladestorm_arms) or Enemies() > 2 and Spell(cleave) or AzeriteTraitRank(seismic_wave_trait) == 3 and Spell(overpower) or Spell(mortal_strike) or Talent(fervor_of_battle_talent) and { BuffPresent(deadly_calm_buff) or Rage() >= 60 } and Spell(whirlwind_arms) or Spell(overpower) or Talent(fervor_of_battle_talent) and { not HasAzeriteTrait(test_of_might_trait) or target.DebuffPresent(colossus_smash_debuff) } and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and { not HasAzeriteTrait(test_of_might_trait) or target.DebuffPresent(colossus_smash_debuff) or BuffPresent(deadly_calm_buff) or Rage() >= 60 } and Spell(slam)
}

### actions.precombat

AddFunction ArmsPrecombatMainActions
{
}

AddFunction ArmsPrecombatMainPostConditions
{
}

AddFunction ArmsPrecombatShortCdActions
{
}

AddFunction ArmsPrecombatShortCdPostConditions
{
}

AddFunction ArmsPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_bursting_blood usable=1)
}

AddFunction ArmsPrecombatCdPostConditions
{
}

### actions.hac

AddFunction ArmsHacMainActions
{
 #rend,if=remains<=duration*0.3&(!raid_event.adds.up|buff.sweeping_strikes.up)
 if target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and { not False(raid_event_adds_exists) or BuffPresent(sweeping_strikes_buff) } Spell(rend)
 #skullsplitter,if=rage<60&(cooldown.deadly_calm.remains>3|!talent.deadly_calm.enabled)
 if Rage() < 60 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } Spell(skullsplitter)
 #colossus_smash,if=raid_event.adds.up|raid_event.adds.in>40|(raid_event.adds.in>20&talent.anger_management.enabled)
 if False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) Spell(colossus_smash)
 #warbreaker,if=raid_event.adds.up|raid_event.adds.in>40|(raid_event.adds.in>20&talent.anger_management.enabled)
 if False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) Spell(warbreaker)
 #overpower,if=!raid_event.adds.up|(raid_event.adds.up&azerite.seismic_wave.enabled)
 if not False(raid_event_adds_exists) or False(raid_event_adds_exists) and HasAzeriteTrait(seismic_wave_trait) Spell(overpower)
 #cleave,if=spell_targets.whirlwind>2
 if Enemies() > 2 Spell(cleave)
 #execute,if=!raid_event.adds.up|(!talent.cleave.enabled&dot.deep_wounds.remains<2)|buff.sudden_death.react
 if not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sudden_death_arms_buff) Spell(execute_arms)
 #mortal_strike,if=!raid_event.adds.up|(!talent.cleave.enabled&dot.deep_wounds.remains<2)
 if not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 Spell(mortal_strike)
 #whirlwind,if=raid_event.adds.up
 if False(raid_event_adds_exists) Spell(whirlwind_arms)
 #overpower
 Spell(overpower)
 #whirlwind,if=talent.fervor_of_battle.enabled
 if Talent(fervor_of_battle_talent) Spell(whirlwind_arms)
 #slam,if=!talent.fervor_of_battle.enabled&!raid_event.adds.up
 if not Talent(fervor_of_battle_talent) and not False(raid_event_adds_exists) Spell(slam)
}

AddFunction ArmsHacMainPostConditions
{
}

AddFunction ArmsHacShortCdActions
{
 unless target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and { not False(raid_event_adds_exists) or BuffPresent(sweeping_strikes_buff) } and Spell(rend) or Rage() < 60 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter)
 {
  #deadly_calm,if=(cooldown.bladestorm.remains>6|talent.ravager.enabled&cooldown.ravager.remains>6)&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if { SpellCooldown(bladestorm_arms) > 6 or Talent(ravager_talent) and SpellCooldown(ravager) > 6 } and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } Spell(deadly_calm)
  #ravager,if=(raid_event.adds.up|raid_event.adds.in>target.time_to_die)&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if { False(raid_event_adds_exists) or 600 > target.TimeToDie() } and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } Spell(ravager)

  unless { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(colossus_smash) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(warbreaker)
  {
   #bladestorm,if=(debuff.colossus_smash.up&raid_event.adds.in>target.time_to_die)|raid_event.adds.up&((debuff.colossus_smash.remains>4.5&!azerite.test_of_might.enabled)|buff.test_of_might.up)
   if target.DebuffPresent(colossus_smash_debuff) and 600 > target.TimeToDie() or False(raid_event_adds_exists) and { target.DebuffRemaining(colossus_smash_debuff) > 4.5 and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } Spell(bladestorm_arms)
  }
 }
}

AddFunction ArmsHacShortCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and { not False(raid_event_adds_exists) or BuffPresent(sweeping_strikes_buff) } and Spell(rend) or Rage() < 60 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(colossus_smash) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(warbreaker) or { not False(raid_event_adds_exists) or False(raid_event_adds_exists) and HasAzeriteTrait(seismic_wave_trait) } and Spell(overpower) or Enemies() > 2 and Spell(cleave) or { not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sudden_death_arms_buff) } and Spell(execute_arms) or { not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 } and Spell(mortal_strike) or False(raid_event_adds_exists) and Spell(whirlwind_arms) or Spell(overpower) or Talent(fervor_of_battle_talent) and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and not False(raid_event_adds_exists) and Spell(slam)
}

AddFunction ArmsHacCdActions
{
}

AddFunction ArmsHacCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and { not False(raid_event_adds_exists) or BuffPresent(sweeping_strikes_buff) } and Spell(rend) or Rage() < 60 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or { SpellCooldown(bladestorm_arms) > 6 or Talent(ravager_talent) and SpellCooldown(ravager) > 6 } and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } and Spell(deadly_calm) or { False(raid_event_adds_exists) or 600 > target.TimeToDie() } and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } and Spell(ravager) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(colossus_smash) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(warbreaker) or { target.DebuffPresent(colossus_smash_debuff) and 600 > target.TimeToDie() or False(raid_event_adds_exists) and { target.DebuffRemaining(colossus_smash_debuff) > 4.5 and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } } and Spell(bladestorm_arms) or { not False(raid_event_adds_exists) or False(raid_event_adds_exists) and HasAzeriteTrait(seismic_wave_trait) } and Spell(overpower) or Enemies() > 2 and Spell(cleave) or { not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sudden_death_arms_buff) } and Spell(execute_arms) or { not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 } and Spell(mortal_strike) or False(raid_event_adds_exists) and Spell(whirlwind_arms) or Spell(overpower) or Talent(fervor_of_battle_talent) and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and not False(raid_event_adds_exists) and Spell(slam)
}

### actions.five_target

AddFunction ArmsFivetargetMainActions
{
 #skullsplitter,if=rage<60&(!talent.deadly_calm.enabled|buff.deadly_calm.down)
 if Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } Spell(skullsplitter)
 #colossus_smash,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(colossus_smash)
 #warbreaker,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(warbreaker)
 #cleave
 Spell(cleave)
 #execute,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|(buff.sudden_death.react|buff.stone_heart.react)&(buff.sweeping_strikes.up|cooldown.sweeping_strikes.remains>8)
 if not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } Spell(execute_arms)
 #mortal_strike,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|buff.sweeping_strikes.up&buff.overpower.stack=2&(talent.dreadnaught.enabled|buff.executioners_precision.stack=2)
 if not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or target.DebuffStacks(executioners_precision_debuff) == 2 } Spell(mortal_strike)
 #whirlwind,if=debuff.colossus_smash.up|(buff.crushing_assault.up&talent.fervor_of_battle.enabled)
 if target.DebuffPresent(colossus_smash_debuff) or BuffPresent(crushing_assault_buff) and Talent(fervor_of_battle_talent) Spell(whirlwind_arms)
 #whirlwind,if=buff.deadly_calm.up|rage>60
 if BuffPresent(deadly_calm_buff) or Rage() > 60 Spell(whirlwind_arms)
 #overpower
 Spell(overpower)
 #whirlwind
 Spell(whirlwind_arms)
}

AddFunction ArmsFivetargetMainPostConditions
{
}

AddFunction ArmsFivetargetShortCdActions
{
 unless Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter)
 {
  #ravager,if=(!talent.warbreaker.enabled|cooldown.warbreaker.remains<2)
  if not Talent(warbreaker_talent) or SpellCooldown(warbreaker) < 2 Spell(ravager)

  unless target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker)
  {
   #bladestorm,if=buff.sweeping_strikes.down&(!talent.deadly_calm.enabled|buff.deadly_calm.down)&((debuff.colossus_smash.remains>4.5&!azerite.test_of_might.enabled)|buff.test_of_might.up)
   if BuffExpires(sweeping_strikes_buff) and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and { target.DebuffRemaining(colossus_smash_debuff) > 4.5 and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } Spell(bladestorm_arms)
   #deadly_calm
   Spell(deadly_calm)
  }
 }
}

AddFunction ArmsFivetargetShortCdPostConditions
{
 Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or Spell(cleave) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } } and Spell(execute_arms) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or target.DebuffStacks(executioners_precision_debuff) == 2 } } and Spell(mortal_strike) or { target.DebuffPresent(colossus_smash_debuff) or BuffPresent(crushing_assault_buff) and Talent(fervor_of_battle_talent) } and Spell(whirlwind_arms) or { BuffPresent(deadly_calm_buff) or Rage() > 60 } and Spell(whirlwind_arms) or Spell(overpower) or Spell(whirlwind_arms)
}

AddFunction ArmsFivetargetCdActions
{
}

AddFunction ArmsFivetargetCdPostConditions
{
 Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter) or { not Talent(warbreaker_talent) or SpellCooldown(warbreaker) < 2 } and Spell(ravager) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or BuffExpires(sweeping_strikes_buff) and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and { target.DebuffRemaining(colossus_smash_debuff) > 4.5 and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } and Spell(bladestorm_arms) or Spell(deadly_calm) or Spell(cleave) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death_arms_buff) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } } and Spell(execute_arms) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or target.DebuffStacks(executioners_precision_debuff) == 2 } } and Spell(mortal_strike) or { target.DebuffPresent(colossus_smash_debuff) or BuffPresent(crushing_assault_buff) and Talent(fervor_of_battle_talent) } and Spell(whirlwind_arms) or { BuffPresent(deadly_calm_buff) or Rage() > 60 } and Spell(whirlwind_arms) or Spell(overpower) or Spell(whirlwind_arms)
}

### actions.execute

AddFunction ArmsExecuteMainActions
{
 #skullsplitter,if=rage<60&(!talent.deadly_calm.enabled|buff.deadly_calm.down)
 if Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } Spell(skullsplitter)
 #colossus_smash,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(colossus_smash)
 #warbreaker,if=debuff.colossus_smash.down
 if target.DebuffExpires(colossus_smash_debuff) Spell(warbreaker)
 #cleave,if=spell_targets.whirlwind>2
 if Enemies() > 2 Spell(cleave)
 #slam,if=buff.crushing_assault.up
 if BuffPresent(crushing_assault_buff) Spell(slam)
 #mortal_strike,if=buff.overpower.stack=2&talent.dreadnaught.enabled|buff.executioners_precision.stack=2
 if BuffStacks(overpower_buff) == 2 and Talent(dreadnaught_talent) or target.DebuffStacks(executioners_precision_debuff) == 2 Spell(mortal_strike)
 #execute,if=buff.deadly_calm.up
 if BuffPresent(deadly_calm_buff) Spell(execute_arms)
 #overpower
 Spell(overpower)
 #execute
 Spell(execute_arms)
}

AddFunction ArmsExecuteMainPostConditions
{
}

AddFunction ArmsExecuteShortCdActions
{
 unless Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter)
 {
  #ravager,if=!buff.deadly_calm.up&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if not BuffPresent(deadly_calm_buff) and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } Spell(ravager)

  unless target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker)
  {
   #deadly_calm
   Spell(deadly_calm)
   #bladestorm,if=rage<30&!buff.deadly_calm.up
   if Rage() < 30 and not BuffPresent(deadly_calm_buff) Spell(bladestorm_arms)
  }
 }
}

AddFunction ArmsExecuteShortCdPostConditions
{
 Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or Enemies() > 2 and Spell(cleave) or BuffPresent(crushing_assault_buff) and Spell(slam) or { BuffStacks(overpower_buff) == 2 and Talent(dreadnaught_talent) or target.DebuffStacks(executioners_precision_debuff) == 2 } and Spell(mortal_strike) or BuffPresent(deadly_calm_buff) and Spell(execute_arms) or Spell(overpower) or Spell(execute_arms)
}

AddFunction ArmsExecuteCdActions
{
}

AddFunction ArmsExecuteCdPostConditions
{
 Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter) or not BuffPresent(deadly_calm_buff) and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } and Spell(ravager) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or Spell(deadly_calm) or Rage() < 30 and not BuffPresent(deadly_calm_buff) and Spell(bladestorm_arms) or Enemies() > 2 and Spell(cleave) or BuffPresent(crushing_assault_buff) and Spell(slam) or { BuffStacks(overpower_buff) == 2 and Talent(dreadnaught_talent) or target.DebuffStacks(executioners_precision_debuff) == 2 } and Spell(mortal_strike) or BuffPresent(deadly_calm_buff) and Spell(execute_arms) or Spell(overpower) or Spell(execute_arms)
}

### actions.default

AddFunction ArmsDefaultMainActions
{
 #charge
 if CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) Spell(charge)
 #sweeping_strikes,if=spell_targets.whirlwind>1&(cooldown.bladestorm.remains>10|cooldown.colossus_smash.remains>8|azerite.test_of_might.enabled)
 if Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } Spell(sweeping_strikes)
 #run_action_list,name=hac,if=raid_event.adds.exists
 if False(raid_event_adds_exists) ArmsHacMainActions()

 unless False(raid_event_adds_exists) and ArmsHacMainPostConditions()
 {
  #run_action_list,name=five_target,if=spell_targets.whirlwind>4
  if Enemies() > 4 ArmsFivetargetMainActions()

  unless Enemies() > 4 and ArmsFivetargetMainPostConditions()
  {
   #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
   if Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteMainActions()

   unless { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteMainPostConditions()
   {
    #run_action_list,name=single_target
    ArmsSingletargetMainActions()
   }
  }
 }
}

AddFunction ArmsDefaultMainPostConditions
{
 False(raid_event_adds_exists) and ArmsHacMainPostConditions() or Enemies() > 4 and ArmsFivetargetMainPostConditions() or { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteMainPostConditions() or ArmsSingletargetMainPostConditions()
}

AddFunction ArmsDefaultShortCdActions
{
 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge)
 {
  #auto_attack
  ArmsGetInMeleeRange()

  unless Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } and Spell(sweeping_strikes)
  {
   #run_action_list,name=hac,if=raid_event.adds.exists
   if False(raid_event_adds_exists) ArmsHacShortCdActions()

   unless False(raid_event_adds_exists) and ArmsHacShortCdPostConditions()
   {
    #run_action_list,name=five_target,if=spell_targets.whirlwind>4
    if Enemies() > 4 ArmsFivetargetShortCdActions()

    unless Enemies() > 4 and ArmsFivetargetShortCdPostConditions()
    {
     #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
     if Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteShortCdActions()

     unless { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteShortCdPostConditions()
     {
      #run_action_list,name=single_target
      ArmsSingletargetShortCdActions()
     }
    }
   }
  }
 }
}

AddFunction ArmsDefaultShortCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge) or Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } and Spell(sweeping_strikes) or False(raid_event_adds_exists) and ArmsHacShortCdPostConditions() or Enemies() > 4 and ArmsFivetargetShortCdPostConditions() or { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteShortCdPostConditions() or ArmsSingletargetShortCdPostConditions()
}

AddFunction ArmsDefaultCdActions
{
 ArmsInterruptActions()

 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_bursting_blood usable=1)
  #blood_fury,if=debuff.colossus_smash.up
  if target.DebuffPresent(colossus_smash_debuff) Spell(blood_fury_ap)
  #berserking,if=debuff.colossus_smash.up
  if target.DebuffPresent(colossus_smash_debuff) Spell(berserking)
  #arcane_torrent,if=debuff.colossus_smash.down&cooldown.mortal_strike.remains>1.5&rage<50
  if target.DebuffExpires(colossus_smash_debuff) and SpellCooldown(mortal_strike) > 1.5 and Rage() < 50 Spell(arcane_torrent_rage)
  #lights_judgment,if=debuff.colossus_smash.down
  if target.DebuffExpires(colossus_smash_debuff) Spell(lights_judgment)
  #fireblood,if=debuff.colossus_smash.up
  if target.DebuffPresent(colossus_smash_debuff) Spell(fireblood)
  #ancestral_call,if=debuff.colossus_smash.up
  if target.DebuffPresent(colossus_smash_debuff) Spell(ancestral_call)
  #avatar,if=cooldown.colossus_smash.remains<8|(talent.warbreaker.enabled&cooldown.warbreaker.remains<8)
  if SpellCooldown(colossus_smash) < 8 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 8 Spell(avatar)

  unless Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } and Spell(sweeping_strikes)
  {
   #run_action_list,name=hac,if=raid_event.adds.exists
   if False(raid_event_adds_exists) ArmsHacCdActions()

   unless False(raid_event_adds_exists) and ArmsHacCdPostConditions()
   {
    #run_action_list,name=five_target,if=spell_targets.whirlwind>4
    if Enemies() > 4 ArmsFivetargetCdActions()

    unless Enemies() > 4 and ArmsFivetargetCdPostConditions()
    {
     #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
     if Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteCdActions()

     unless { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteCdPostConditions()
     {
      #run_action_list,name=single_target
      ArmsSingletargetCdActions()
     }
    }
   }
  }
 }
}

AddFunction ArmsDefaultCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge) or Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } and Spell(sweeping_strikes) or False(raid_event_adds_exists) and ArmsHacCdPostConditions() or Enemies() > 4 and ArmsFivetargetCdPostConditions() or { Talent(arms_massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteCdPostConditions() or ArmsSingletargetCdPostConditions()
}

### Arms icons.

AddCheckBox(opt_warrior_arms_aoe L(AOE) default specialization=arms)

AddIcon checkbox=!opt_warrior_arms_aoe enemies=1 help=shortcd specialization=arms
{
 if not InCombat() ArmsPrecombatShortCdActions()
 unless not InCombat() and ArmsPrecombatShortCdPostConditions()
 {
  ArmsDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warrior_arms_aoe help=shortcd specialization=arms
{
 if not InCombat() ArmsPrecombatShortCdActions()
 unless not InCombat() and ArmsPrecombatShortCdPostConditions()
 {
  ArmsDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=arms
{
 if not InCombat() ArmsPrecombatMainActions()
 unless not InCombat() and ArmsPrecombatMainPostConditions()
 {
  ArmsDefaultMainActions()
 }
}

AddIcon checkbox=opt_warrior_arms_aoe help=aoe specialization=arms
{
 if not InCombat() ArmsPrecombatMainActions()
 unless not InCombat() and ArmsPrecombatMainPostConditions()
 {
  ArmsDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warrior_arms_aoe enemies=1 help=cd specialization=arms
{
 if not InCombat() ArmsPrecombatCdActions()
 unless not InCombat() and ArmsPrecombatCdPostConditions()
 {
  ArmsDefaultCdActions()
 }
}

AddIcon checkbox=opt_warrior_arms_aoe help=cd specialization=arms
{
 if not InCombat() ArmsPrecombatCdActions()
 unless not InCombat() and ArmsPrecombatCdPostConditions()
 {
  ArmsDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# anger_management_talent
# arcane_torrent_rage
# arms_massacre_talent
# avatar
# berserking
# bladestorm_arms
# blood_fury_ap
# charge
# cleave
# cleave_talent
# colossus_smash
# colossus_smash_debuff
# crushing_assault_buff
# deadly_calm
# deadly_calm_buff
# deadly_calm_talent
# deep_wounds_arms_debuff
# dreadnaught_talent
# execute_arms
# executioners_precision_debuff
# fervor_of_battle_talent
# fireblood
# heroic_leap
# intimidating_shout
# item_bursting_blood
# lights_judgment
# mortal_strike
# overpower
# overpower_buff
# pummel
# quaking_palm
# ravager
# ravager_talent
# rend
# rend_debuff
# seismic_wave_trait
# shockwave
# skullsplitter
# slam
# stone_heart_buff
# storm_bolt
# sudden_death_arms_buff
# sweeping_strikes
# sweeping_strikes_buff
# test_of_might_buff
# test_of_might_trait
# war_stomp
# warbreaker
# warbreaker_talent
# whirlwind_arms
]]
    OvaleScripts:RegisterScript("WARRIOR", "arms", name, desc, code, "script")
end
do
    local name = "sc_pr_warrior_fury"
    local desc = "[8.1] Simulationcraft: PR_Warrior_Fury"
    local code = [[
# Based on SimulationCraft profile "PR_Warrior_Fury".
#	class=warrior
#	spec=fury
#	talents=2122123

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=fury)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=fury)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=fury)

AddFunction FuryInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(pummel) and target.IsInterruptible() Spell(pummel)
  if target.InRange(storm_bolt) and not target.Classification(worldboss) Spell(storm_bolt)
  if target.Distance(less 10) and not target.Classification(worldboss) Spell(shockwave)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(intimidating_shout) and not target.Classification(worldboss) Spell(intimidating_shout)
 }
}

AddFunction FuryGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not InFlightToTarget(charge) and not InFlightToTarget(heroic_leap) and not target.InRange(pummel)
 {
  if target.InRange(charge) Spell(charge)
  if SpellCharges(charge) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.single_target

AddFunction FurySingletargetMainActions
{
 #rampage,if=buff.recklessness.up|(talent.frothing_berserker.enabled|talent.carnage.enabled&(buff.enrage.remains<gcd|rage>90)|talent.massacre.enabled&(buff.enrage.remains<gcd|rage>90))
 if BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } Spell(rampage)
 #execute
 Spell(execute)
 #bloodthirst,if=buff.enrage.down|azerite.cold_steel_hot_blood.rank>1
 if not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 Spell(bloodthirst)
 #raging_blow,if=charges=2
 if Charges(raging_blow) == 2 Spell(raging_blow)
 #bloodthirst
 Spell(bloodthirst)
 #dragon_roar,if=buff.enrage.up
 if IsEnraged() Spell(dragon_roar)
 #raging_blow,if=talent.carnage.enabled|(talent.massacre.enabled&rage<80)|(talent.frothing_berserker.enabled&rage<90)
 if Talent(carnage_talent) or Talent(massacre_talent_fury) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 Spell(raging_blow)
 #furious_slash,if=talent.furious_slash.enabled
 if Talent(furious_slash_talent) Spell(furious_slash)
 #whirlwind
 Spell(whirlwind_fury)
}

AddFunction FurySingletargetMainPostConditions
{
}

AddFunction FurySingletargetShortCdActions
{
 #siegebreaker
 Spell(siegebreaker)

 unless { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute)
 {
  #bladestorm,if=prev_gcd.1.rampage
  if PreviousGCDSpell(rampage) Spell(bladestorm_fury)
 }
}

AddFunction FurySingletargetShortCdPostConditions
{
 { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute) or { not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 } and Spell(bloodthirst) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst) or IsEnraged() and Spell(dragon_roar) or { Talent(carnage_talent) or Talent(massacre_talent_fury) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 } and Spell(raging_blow) or Talent(furious_slash_talent) and Spell(furious_slash) or Spell(whirlwind_fury)
}

AddFunction FurySingletargetCdActions
{
}

AddFunction FurySingletargetCdPostConditions
{
 Spell(siegebreaker) or { BuffPresent(recklessness_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute) or PreviousGCDSpell(rampage) and Spell(bladestorm_fury) or { not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 } and Spell(bloodthirst) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst) or IsEnraged() and Spell(dragon_roar) or { Talent(carnage_talent) or Talent(massacre_talent_fury) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 } and Spell(raging_blow) or Talent(furious_slash_talent) and Spell(furious_slash) or Spell(whirlwind_fury)
}

### actions.precombat

AddFunction FuryPrecombatMainActions
{
}

AddFunction FuryPrecombatMainPostConditions
{
}

AddFunction FuryPrecombatShortCdActions
{
}

AddFunction FuryPrecombatShortCdPostConditions
{
}

AddFunction FuryPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_bursting_blood usable=1)
 #recklessness,if=!talent.furious_slash.enabled&!talent.reckless_abandon.enabled
 if not Talent(furious_slash_talent) and not Talent(reckless_abandon_talent) Spell(recklessness)
}

AddFunction FuryPrecombatCdPostConditions
{
}

### actions.movement

AddFunction FuryMovementMainActions
{
}

AddFunction FuryMovementMainPostConditions
{
}

AddFunction FuryMovementShortCdActions
{
 #heroic_leap
 if CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
}

AddFunction FuryMovementShortCdPostConditions
{
}

AddFunction FuryMovementCdActions
{
}

AddFunction FuryMovementCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap)
}

### actions.default

AddFunction FuryDefaultMainActions
{
 #charge
 if CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) Spell(charge)
 #run_action_list,name=movement,if=movement.distance>5
 if target.Distance() > 5 FuryMovementMainActions()

 unless target.Distance() > 5 and FuryMovementMainPostConditions()
 {
  #furious_slash,if=talent.furious_slash.enabled&(buff.furious_slash.stack<3|buff.furious_slash.remains<3|(cooldown.recklessness.remains<3&buff.furious_slash.remains<9))
  if Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } Spell(furious_slash)
  #rampage,if=cooldown.recklessness.remains<3
  if SpellCooldown(recklessness) < 3 Spell(rampage)
  #whirlwind,if=spell_targets.whirlwind>1&!buff.meat_cleaver.up
  if Enemies() > 1 and not BuffPresent(whirlwind_buff) Spell(whirlwind_fury)
  #run_action_list,name=single_target
  FurySingletargetMainActions()
 }
}

AddFunction FuryDefaultMainPostConditions
{
 target.Distance() > 5 and FuryMovementMainPostConditions() or FurySingletargetMainPostConditions()
}

AddFunction FuryDefaultShortCdActions
{
 #auto_attack
 FuryGetInMeleeRange()

 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge)
 {
  #run_action_list,name=movement,if=movement.distance>5
  if target.Distance() > 5 FuryMovementShortCdActions()

  unless target.Distance() > 5 and FuryMovementShortCdPostConditions()
  {
   #heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)|!raid_event.movement.exists
   if { target.Distance() > 25 and 600 > 45 or not False(raid_event_movement_exists) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)

   unless Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury)
   {
    #run_action_list,name=single_target
    FurySingletargetShortCdActions()
   }
  }
 }
}

AddFunction FuryDefaultShortCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge) or target.Distance() > 5 and FuryMovementShortCdPostConditions() or Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury) or FurySingletargetShortCdPostConditions()
}

AddFunction FuryDefaultCdActions
{
 FuryInterruptActions()

 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge)
 {
  #run_action_list,name=movement,if=movement.distance>5
  if target.Distance() > 5 FuryMovementCdActions()

  unless target.Distance() > 5 and FuryMovementCdPostConditions() or { target.Distance() > 25 and 600 > 45 or not False(raid_event_movement_exists) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap)
  {
   #potion
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_bursting_blood usable=1)

   unless Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage)
   {
    #recklessness,if=!talent.siegebreaker.enabled|(cooldown.siegebreaker.remains<1|cooldown.siegebreaker.remains>5)
    if not Talent(siegebreaker_talent) or SpellCooldown(siegebreaker) < 1 or SpellCooldown(siegebreaker) > 5 Spell(recklessness)

    unless Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury)
    {
     #blood_fury
     Spell(blood_fury_ap)
     #berserking
     Spell(berserking)
     #lights_judgment,if=buff.recklessness.down
     if BuffExpires(recklessness_buff) Spell(lights_judgment)
     #fireblood
     Spell(fireblood)
     #ancestral_call
     Spell(ancestral_call)
     #run_action_list,name=single_target
     FurySingletargetCdActions()
    }
   }
  }
 }
}

AddFunction FuryDefaultCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge) or target.Distance() > 5 and FuryMovementCdPostConditions() or { target.Distance() > 25 and 600 > 45 or not False(raid_event_movement_exists) } and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap) or Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage) or Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury) or FurySingletargetCdPostConditions()
}

### Fury icons.

AddCheckBox(opt_warrior_fury_aoe L(AOE) default specialization=fury)

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=shortcd specialization=fury
{
 if not InCombat() FuryPrecombatShortCdActions()
 unless not InCombat() and FuryPrecombatShortCdPostConditions()
 {
  FuryDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warrior_fury_aoe help=shortcd specialization=fury
{
 if not InCombat() FuryPrecombatShortCdActions()
 unless not InCombat() and FuryPrecombatShortCdPostConditions()
 {
  FuryDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=fury
{
 if not InCombat() FuryPrecombatMainActions()
 unless not InCombat() and FuryPrecombatMainPostConditions()
 {
  FuryDefaultMainActions()
 }
}

AddIcon checkbox=opt_warrior_fury_aoe help=aoe specialization=fury
{
 if not InCombat() FuryPrecombatMainActions()
 unless not InCombat() and FuryPrecombatMainPostConditions()
 {
  FuryDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warrior_fury_aoe enemies=1 help=cd specialization=fury
{
 if not InCombat() FuryPrecombatCdActions()
 unless not InCombat() and FuryPrecombatCdPostConditions()
 {
  FuryDefaultCdActions()
 }
}

AddIcon checkbox=opt_warrior_fury_aoe help=cd specialization=fury
{
 if not InCombat() FuryPrecombatCdActions()
 unless not InCombat() and FuryPrecombatCdPostConditions()
 {
  FuryDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# berserking
# bladestorm_fury
# blood_fury_ap
# bloodthirst
# carnage_talent
# charge
# cold_steel_hot_blood_trait
# dragon_roar
# execute
# fireblood
# frothing_berserker_talent
# furious_slash
# furious_slash_buff
# furious_slash_talent
# heroic_leap
# intimidating_shout
# item_bursting_blood
# lights_judgment
# massacre_talent_fury
# pummel
# quaking_palm
# raging_blow
# rampage
# reckless_abandon_talent
# recklessness
# recklessness_buff
# shockwave
# siegebreaker
# siegebreaker_talent
# storm_bolt
# war_stomp
# whirlwind_buff
# whirlwind_fury
]]
    OvaleScripts:RegisterScript("WARRIOR", "fury", name, desc, code, "script")
end
