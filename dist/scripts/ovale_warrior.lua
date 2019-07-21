local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_t23_warrior_arms"
    local desc = "[8.2] Simulationcraft: T23_Warrior_Arms"
    local code = [[
# Based on SimulationCraft profile "T23_Warrior_Arms".
#	class=warrior
#	spec=arms
#	talents=3322211

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
  if target.Distance(less 10) and not target.Classification(worldboss) Spell(shockwave)
  if target.InRange(storm_bolt) and not target.Classification(worldboss) Spell(storm_bolt)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(intimidating_shout) and not target.Classification(worldboss) Spell(intimidating_shout)
 }
}

AddFunction ArmsUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
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
 #skullsplitter,if=rage<60&buff.deadly_calm.down&buff.memory_of_lucid_dreams.down
 if Rage() < 60 and BuffExpires(deadly_calm_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) Spell(skullsplitter)
 #colossus_smash,if=!essence.memory_of_lucid_dreams.major|(buff.memory_of_lucid_dreams.up|cooldown.memory_of_lucid_dreams.remains>10)
 if not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 Spell(colossus_smash)
 #warbreaker,if=!essence.memory_of_lucid_dreams.major|(buff.memory_of_lucid_dreams.up|cooldown.memory_of_lucid_dreams.remains>10)
 if not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 Spell(warbreaker)
 #execute,if=buff.sudden_death.react
 if BuffPresent(sudden_death) Spell(execute_arms)
 #cleave,if=spell_targets.whirlwind>2
 if Enemies() > 2 Spell(cleave)
 #overpower,if=rage<30&buff.memory_of_lucid_dreams.up&debuff.colossus_smash.up
 if Rage() < 30 and BuffPresent(memory_of_lucid_dreams_essence_buff) and target.DebuffPresent(colossus_smash_debuff) Spell(overpower)
 #mortal_strike
 Spell(mortal_strike)
 #whirlwind,if=talent.fervor_of_battle.enabled&(buff.memory_of_lucid_dreams.up|buff.deadly_calm.up)
 if Talent(fervor_of_battle_talent) and { BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(deadly_calm_buff) } Spell(whirlwind_arms)
 #overpower
 Spell(overpower)
 #whirlwind,if=talent.fervor_of_battle.enabled
 if Talent(fervor_of_battle_talent) Spell(whirlwind_arms)
 #slam,if=!talent.fervor_of_battle.enabled
 if not Talent(fervor_of_battle_talent) Spell(slam)
}

AddFunction ArmsSingletargetMainPostConditions
{
}

AddFunction ArmsSingletargetShortCdActions
{
 unless target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 60 and BuffExpires(deadly_calm_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(skullsplitter)
 {
  #ravager,if=!buff.deadly_calm.up&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if not BuffPresent(deadly_calm_buff) and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } Spell(ravager)

  unless { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(colossus_smash) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(warbreaker)
  {
   #deadly_calm
   Spell(deadly_calm)

   unless BuffPresent(sudden_death) and Spell(execute_arms)
   {
    #bladestorm,if=cooldown.mortal_strike.remains&(!talent.deadly_calm.enabled|buff.deadly_calm.down)&((debuff.colossus_smash.up&!azerite.test_of_might.enabled)|buff.test_of_might.up)&buff.memory_of_lucid_dreams.down
    if SpellCooldown(mortal_strike) > 0 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and { target.DebuffPresent(colossus_smash_debuff) and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } and BuffExpires(memory_of_lucid_dreams_essence_buff) Spell(bladestorm_arms)
   }
  }
 }
}

AddFunction ArmsSingletargetShortCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 60 and BuffExpires(deadly_calm_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(skullsplitter) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(colossus_smash) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(warbreaker) or BuffPresent(sudden_death) and Spell(execute_arms) or Enemies() > 2 and Spell(cleave) or Rage() < 30 and BuffPresent(memory_of_lucid_dreams_essence_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(overpower) or Spell(mortal_strike) or Talent(fervor_of_battle_talent) and { BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(deadly_calm_buff) } and Spell(whirlwind_arms) or Spell(overpower) or Talent(fervor_of_battle_talent) and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and Spell(slam)
}

AddFunction ArmsSingletargetCdActions
{
}

AddFunction ArmsSingletargetCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and target.DebuffExpires(colossus_smash_debuff) and Spell(rend) or Rage() < 60 and BuffExpires(deadly_calm_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(skullsplitter) or not BuffPresent(deadly_calm_buff) and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } and Spell(ravager) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(colossus_smash) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(warbreaker) or Spell(deadly_calm) or BuffPresent(sudden_death) and Spell(execute_arms) or SpellCooldown(mortal_strike) > 0 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and { target.DebuffPresent(colossus_smash_debuff) and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(bladestorm_arms) or Enemies() > 2 and Spell(cleave) or Rage() < 30 and BuffPresent(memory_of_lucid_dreams_essence_buff) and target.DebuffPresent(colossus_smash_debuff) and Spell(overpower) or Spell(mortal_strike) or Talent(fervor_of_battle_talent) and { BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(deadly_calm_buff) } and Spell(whirlwind_arms) or Spell(overpower) or Talent(fervor_of_battle_talent) and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and Spell(slam)
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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams_essence)
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
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
 if not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sudden_death) Spell(execute_arms)
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
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and { not False(raid_event_adds_exists) or BuffPresent(sweeping_strikes_buff) } and Spell(rend) or Rage() < 60 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(colossus_smash) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(warbreaker) or { not False(raid_event_adds_exists) or False(raid_event_adds_exists) and HasAzeriteTrait(seismic_wave_trait) } and Spell(overpower) or Enemies() > 2 and Spell(cleave) or { not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sudden_death) } and Spell(execute_arms) or { not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 } and Spell(mortal_strike) or False(raid_event_adds_exists) and Spell(whirlwind_arms) or Spell(overpower) or Talent(fervor_of_battle_talent) and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and not False(raid_event_adds_exists) and Spell(slam)
}

AddFunction ArmsHacCdActions
{
}

AddFunction ArmsHacCdPostConditions
{
 target.DebuffRemaining(rend_debuff) <= BaseDuration(rend_debuff) * 0.3 and { not False(raid_event_adds_exists) or BuffPresent(sweeping_strikes_buff) } and Spell(rend) or Rage() < 60 and { SpellCooldown(deadly_calm) > 3 or not Talent(deadly_calm_talent) } and Spell(skullsplitter) or { SpellCooldown(bladestorm_arms) > 6 or Talent(ravager_talent) and SpellCooldown(ravager) > 6 } and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } and Spell(deadly_calm) or { False(raid_event_adds_exists) or 600 > target.TimeToDie() } and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } and Spell(ravager) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(colossus_smash) or { False(raid_event_adds_exists) or 600 > 40 or 600 > 20 and Talent(anger_management_talent) } and Spell(warbreaker) or { target.DebuffPresent(colossus_smash_debuff) and 600 > target.TimeToDie() or False(raid_event_adds_exists) and { target.DebuffRemaining(colossus_smash_debuff) > 4.5 and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } } and Spell(bladestorm_arms) or { not False(raid_event_adds_exists) or False(raid_event_adds_exists) and HasAzeriteTrait(seismic_wave_trait) } and Spell(overpower) or Enemies() > 2 and Spell(cleave) or { not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sudden_death) } and Spell(execute_arms) or { not False(raid_event_adds_exists) or not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 } and Spell(mortal_strike) or False(raid_event_adds_exists) and Spell(whirlwind_arms) or Spell(overpower) or Talent(fervor_of_battle_talent) and Spell(whirlwind_arms) or not Talent(fervor_of_battle_talent) and not False(raid_event_adds_exists) and Spell(slam)
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
 if not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } Spell(execute_arms)
 #mortal_strike,if=(!talent.cleave.enabled&dot.deep_wounds.remains<2)|buff.sweeping_strikes.up&buff.overpower.stack=2&(talent.dreadnaught.enabled|buff.executioners_precision.stack=2)
 if not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or 0 == 2 } Spell(mortal_strike)
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
 Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or Spell(cleave) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } } and Spell(execute_arms) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or 0 == 2 } } and Spell(mortal_strike) or { target.DebuffPresent(colossus_smash_debuff) or BuffPresent(crushing_assault_buff) and Talent(fervor_of_battle_talent) } and Spell(whirlwind_arms) or { BuffPresent(deadly_calm_buff) or Rage() > 60 } and Spell(whirlwind_arms) or Spell(overpower) or Spell(whirlwind_arms)
}

AddFunction ArmsFivetargetCdActions
{
}

AddFunction ArmsFivetargetCdPostConditions
{
 Rage() < 60 and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and Spell(skullsplitter) or { not Talent(warbreaker_talent) or SpellCooldown(warbreaker) < 2 } and Spell(ravager) or target.DebuffExpires(colossus_smash_debuff) and Spell(colossus_smash) or target.DebuffExpires(colossus_smash_debuff) and Spell(warbreaker) or BuffExpires(sweeping_strikes_buff) and { not Talent(deadly_calm_talent) or BuffExpires(deadly_calm_buff) } and { target.DebuffRemaining(colossus_smash_debuff) > 4.5 and not HasAzeriteTrait(test_of_might_trait) or BuffPresent(test_of_might_buff) } and Spell(bladestorm_arms) or Spell(deadly_calm) or Spell(cleave) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or { BuffPresent(sudden_death) or BuffPresent(stone_heart_buff) } and { BuffPresent(sweeping_strikes_buff) or SpellCooldown(sweeping_strikes) > 8 } } and Spell(execute_arms) or { not Talent(cleave_talent) and target.DebuffRemaining(deep_wounds_arms_debuff) < 2 or BuffPresent(sweeping_strikes_buff) and BuffStacks(overpower_buff) == 2 and { Talent(dreadnaught_talent) or 0 == 2 } } and Spell(mortal_strike) or { target.DebuffPresent(colossus_smash_debuff) or BuffPresent(crushing_assault_buff) and Talent(fervor_of_battle_talent) } and Spell(whirlwind_arms) or { BuffPresent(deadly_calm_buff) or Rage() > 60 } and Spell(whirlwind_arms) or Spell(overpower) or Spell(whirlwind_arms)
}

### actions.execute

AddFunction ArmsExecuteMainActions
{
 #skullsplitter,if=rage<60&buff.deadly_calm.down&buff.memory_of_lucid_dreams.down
 if Rage() < 60 and BuffExpires(deadly_calm_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) Spell(skullsplitter)
 #colossus_smash,if=!essence.memory_of_lucid_dreams.major|(buff.memory_of_lucid_dreams.up|cooldown.memory_of_lucid_dreams.remains>10)
 if not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 Spell(colossus_smash)
 #warbreaker,if=!essence.memory_of_lucid_dreams.major|(buff.memory_of_lucid_dreams.up|cooldown.memory_of_lucid_dreams.remains>10)
 if not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 Spell(warbreaker)
 #cleave,if=spell_targets.whirlwind>2
 if Enemies() > 2 Spell(cleave)
 #slam,if=buff.crushing_assault.up&buff.memory_of_lucid_dreams.down
 if BuffPresent(crushing_assault_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) Spell(slam)
 #mortal_strike,if=buff.overpower.stack=2&talent.dreadnaught.enabled|buff.executioners_precision.stack=2
 if BuffStacks(overpower_buff) == 2 and Talent(dreadnaught_talent) or 0 == 2 Spell(mortal_strike)
 #execute,if=buff.memory_of_lucid_dreams.up|buff.deadly_calm.up
 if BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(deadly_calm_buff) Spell(execute_arms)
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
 unless Rage() < 60 and BuffExpires(deadly_calm_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(skullsplitter)
 {
  #ravager,if=!buff.deadly_calm.up&(cooldown.colossus_smash.remains<2|(talent.warbreaker.enabled&cooldown.warbreaker.remains<2))
  if not BuffPresent(deadly_calm_buff) and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } Spell(ravager)

  unless { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(colossus_smash) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(warbreaker)
  {
   #deadly_calm
   Spell(deadly_calm)
   #bladestorm,if=!buff.memory_of_lucid_dreams.up&buff.test_of_might.up&rage<30&!buff.deadly_calm.up
   if not BuffPresent(memory_of_lucid_dreams_essence_buff) and BuffPresent(test_of_might_buff) and Rage() < 30 and not BuffPresent(deadly_calm_buff) Spell(bladestorm_arms)
  }
 }
}

AddFunction ArmsExecuteShortCdPostConditions
{
 Rage() < 60 and BuffExpires(deadly_calm_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(skullsplitter) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(colossus_smash) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(warbreaker) or Enemies() > 2 and Spell(cleave) or BuffPresent(crushing_assault_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(slam) or { BuffStacks(overpower_buff) == 2 and Talent(dreadnaught_talent) or 0 == 2 } and Spell(mortal_strike) or { BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(deadly_calm_buff) } and Spell(execute_arms) or Spell(overpower) or Spell(execute_arms)
}

AddFunction ArmsExecuteCdActions
{
}

AddFunction ArmsExecuteCdPostConditions
{
 Rage() < 60 and BuffExpires(deadly_calm_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(skullsplitter) or not BuffPresent(deadly_calm_buff) and { SpellCooldown(colossus_smash) < 2 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 2 } and Spell(ravager) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(colossus_smash) or { not AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or BuffPresent(memory_of_lucid_dreams_essence_buff) or SpellCooldown(memory_of_lucid_dreams_essence) > 10 } and Spell(warbreaker) or Spell(deadly_calm) or not BuffPresent(memory_of_lucid_dreams_essence_buff) and BuffPresent(test_of_might_buff) and Rage() < 30 and not BuffPresent(deadly_calm_buff) and Spell(bladestorm_arms) or Enemies() > 2 and Spell(cleave) or BuffPresent(crushing_assault_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Spell(slam) or { BuffStacks(overpower_buff) == 2 and Talent(dreadnaught_talent) or 0 == 2 } and Spell(mortal_strike) or { BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(deadly_calm_buff) } and Spell(execute_arms) or Spell(overpower) or Spell(execute_arms)
}

### actions.default

AddFunction ArmsDefaultMainActions
{
 #charge
 if CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) Spell(charge)
 #sweeping_strikes,if=spell_targets.whirlwind>1&(cooldown.bladestorm.remains>10|cooldown.colossus_smash.remains>8|azerite.test_of_might.enabled)
 if Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } Spell(sweeping_strikes)
 #focused_azerite_beam,if=!debuff.colossus_smash.up&!buff.test_of_might.up
 if not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) Spell(focused_azerite_beam)
 #concentrated_flame,if=!debuff.colossus_smash.up&!buff.test_of_might.up&dot.concentrated_flame_burn.remains=0
 if not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 Spell(concentrated_flame_essence)
 #run_action_list,name=hac,if=raid_event.adds.exists
 if False(raid_event_adds_exists) ArmsHacMainActions()

 unless False(raid_event_adds_exists) and ArmsHacMainPostConditions()
 {
  #run_action_list,name=five_target,if=spell_targets.whirlwind>4
  if Enemies() > 4 ArmsFivetargetMainActions()

  unless Enemies() > 4 and ArmsFivetargetMainPostConditions()
  {
   #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
   if Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteMainActions()

   unless { Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteMainPostConditions()
   {
    #run_action_list,name=single_target
    ArmsSingletargetMainActions()
   }
  }
 }
}

AddFunction ArmsDefaultMainPostConditions
{
 False(raid_event_adds_exists) and ArmsHacMainPostConditions() or Enemies() > 4 and ArmsFivetargetMainPostConditions() or { Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteMainPostConditions() or ArmsSingletargetMainPostConditions()
}

AddFunction ArmsDefaultShortCdActions
{
 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge)
 {
  #auto_attack
  ArmsGetInMeleeRange()

  unless Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } and Spell(sweeping_strikes)
  {
   #purifying_blast,if=!debuff.colossus_smash.up&!buff.test_of_might.up
   if not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) Spell(purifying_blast)
   #ripple_in_space,if=!debuff.colossus_smash.up&!buff.test_of_might.up
   if not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) Spell(ripple_in_space_essence)
   #worldvein_resonance,if=!debuff.colossus_smash.up&!buff.test_of_might.up
   if not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) Spell(worldvein_resonance_essence)

   unless not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(focused_azerite_beam) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence)
   {
    #the_unbound_force,if=buff.reckless_force.up
    if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
    #run_action_list,name=hac,if=raid_event.adds.exists
    if False(raid_event_adds_exists) ArmsHacShortCdActions()

    unless False(raid_event_adds_exists) and ArmsHacShortCdPostConditions()
    {
     #run_action_list,name=five_target,if=spell_targets.whirlwind>4
     if Enemies() > 4 ArmsFivetargetShortCdActions()

     unless Enemies() > 4 and ArmsFivetargetShortCdPostConditions()
     {
      #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
      if Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteShortCdActions()

      unless { Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteShortCdPostConditions()
      {
       #run_action_list,name=single_target
       ArmsSingletargetShortCdActions()
      }
     }
    }
   }
  }
 }
}

AddFunction ArmsDefaultShortCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge) or Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } and Spell(sweeping_strikes) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(focused_azerite_beam) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or False(raid_event_adds_exists) and ArmsHacShortCdPostConditions() or Enemies() > 4 and ArmsFivetargetShortCdPostConditions() or { Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteShortCdPostConditions() or ArmsSingletargetShortCdPostConditions()
}

AddFunction ArmsDefaultCdActions
{
 ArmsInterruptActions()

 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
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
  #use_item,name=ramping_amplitude_gigavolt_engine
  ArmsUseItemActions()
  #avatar,if=cooldown.colossus_smash.remains<8|(talent.warbreaker.enabled&cooldown.warbreaker.remains<8)
  if SpellCooldown(colossus_smash) < 8 or Talent(warbreaker_talent) and SpellCooldown(warbreaker) < 8 Spell(avatar)

  unless Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } and Spell(sweeping_strikes)
  {
   #blood_of_the_enemy,if=buff.test_of_might.up|(debuff.colossus_smash.up&!azerite.test_of_might.enabled)
   if BuffPresent(test_of_might_buff) or target.DebuffPresent(colossus_smash_debuff) and not HasAzeriteTrait(test_of_might_trait) Spell(blood_of_the_enemy)

   unless not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(purifying_blast) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(ripple_in_space_essence) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(worldvein_resonance_essence) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(focused_azerite_beam) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force)
   {
    #guardian_of_azeroth,if=cooldown.colossus_smash.remains<10
    if SpellCooldown(colossus_smash) < 10 Spell(guardian_of_azeroth)
    #memory_of_lucid_dreams,if=cooldown.colossus_smash.remains<3
    if SpellCooldown(colossus_smash) < 3 Spell(memory_of_lucid_dreams_essence)
    #run_action_list,name=hac,if=raid_event.adds.exists
    if False(raid_event_adds_exists) ArmsHacCdActions()

    unless False(raid_event_adds_exists) and ArmsHacCdPostConditions()
    {
     #run_action_list,name=five_target,if=spell_targets.whirlwind>4
     if Enemies() > 4 ArmsFivetargetCdActions()

     unless Enemies() > 4 and ArmsFivetargetCdPostConditions()
     {
      #run_action_list,name=execute,if=(talent.massacre.enabled&target.health.pct<35)|target.health.pct<20
      if Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 ArmsExecuteCdActions()

      unless { Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteCdPostConditions()
      {
       #run_action_list,name=single_target
       ArmsSingletargetCdActions()
      }
     }
    }
   }
  }
 }
}

AddFunction ArmsDefaultCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge) or Enemies() > 1 and { SpellCooldown(bladestorm_arms) > 10 or SpellCooldown(colossus_smash) > 8 or HasAzeriteTrait(test_of_might_trait) } and Spell(sweeping_strikes) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(purifying_blast) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(ripple_in_space_essence) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(worldvein_resonance_essence) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and Spell(focused_azerite_beam) or not target.DebuffPresent(colossus_smash_debuff) and not BuffPresent(test_of_might_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or False(raid_event_adds_exists) and ArmsHacCdPostConditions() or Enemies() > 4 and ArmsFivetargetCdPostConditions() or { Talent(massacre_talent) and target.HealthPercent() < 35 or target.HealthPercent() < 20 } and ArmsExecuteCdPostConditions() or ArmsSingletargetCdPostConditions()
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
# avatar
# berserking
# bladestorm_arms
# blood_fury_ap
# blood_of_the_enemy
# charge
# cleave
# cleave_talent
# colossus_smash
# colossus_smash_debuff
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# crushing_assault_buff
# deadly_calm
# deadly_calm_buff
# deadly_calm_talent
# deep_wounds_arms_debuff
# dreadnaught_talent
# execute_arms
# fervor_of_battle_talent
# fireblood
# focused_azerite_beam
# guardian_of_azeroth
# heroic_leap
# intimidating_shout
# item_unbridled_fury
# lights_judgment
# massacre_talent
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# memory_of_lucid_dreams_essence_id
# mortal_strike
# overpower
# overpower_buff
# pummel
# purifying_blast
# quaking_palm
# ravager
# ravager_talent
# reckless_force_buff
# rend
# rend_debuff
# ripple_in_space_essence
# seismic_wave_trait
# shockwave
# skullsplitter
# slam
# stone_heart_buff
# storm_bolt
# sudden_death
# sweeping_strikes
# sweeping_strikes_buff
# test_of_might_buff
# test_of_might_trait
# the_unbound_force
# war_stomp
# warbreaker
# warbreaker_talent
# whirlwind_arms
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("WARRIOR", "arms", name, desc, code, "script")
end
do
    local name = "sc_t23_warrior_fury"
    local desc = "[8.2] Simulationcraft: T23_Warrior_Fury"
    local code = [[
# Based on SimulationCraft profile "T23_Warrior_Fury".
#	class=warrior
#	spec=fury
#	talents=2123123

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
  if target.Distance(less 10) and not target.Classification(worldboss) Spell(shockwave)
  if target.InRange(storm_bolt) and not target.Classification(worldboss) Spell(storm_bolt)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(intimidating_shout) and not target.Classification(worldboss) Spell(intimidating_shout)
 }
}

AddFunction FuryUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
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
 #rampage,if=(buff.recklessness.up|buff.memory_of_lucid_dreams.up)|(talent.frothing_berserker.enabled|talent.carnage.enabled&(buff.enrage.remains<gcd|rage>90)|talent.massacre.enabled&(buff.enrage.remains<gcd|rage>90))
 if BuffPresent(recklessness_buff) or BuffPresent(memory_of_lucid_dreams_essence_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } Spell(rampage)
 #execute
 Spell(execute)
 #bloodthirst,if=buff.enrage.down|azerite.cold_steel_hot_blood.rank>1
 if not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 Spell(bloodthirst)
 #dragon_roar,if=buff.enrage.up
 if IsEnraged() Spell(dragon_roar)
 #raging_blow,if=charges=2
 if Charges(raging_blow) == 2 Spell(raging_blow)
 #bloodthirst
 Spell(bloodthirst)
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

 unless { BuffPresent(recklessness_buff) or BuffPresent(memory_of_lucid_dreams_essence_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute)
 {
  #bladestorm,if=prev_gcd.1.rampage
  if PreviousGCDSpell(rampage) Spell(bladestorm_fury)
 }
}

AddFunction FurySingletargetShortCdPostConditions
{
 { BuffPresent(recklessness_buff) or BuffPresent(memory_of_lucid_dreams_essence_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute) or { not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 } and Spell(bloodthirst) or IsEnraged() and Spell(dragon_roar) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst) or { Talent(carnage_talent) or Talent(massacre_talent_fury) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 } and Spell(raging_blow) or Talent(furious_slash_talent) and Spell(furious_slash) or Spell(whirlwind_fury)
}

AddFunction FurySingletargetCdActions
{
}

AddFunction FurySingletargetCdPostConditions
{
 Spell(siegebreaker) or { BuffPresent(recklessness_buff) or BuffPresent(memory_of_lucid_dreams_essence_buff) or Talent(frothing_berserker_talent) or Talent(carnage_talent) and { EnrageRemaining() < GCD() or Rage() > 90 } or Talent(massacre_talent_fury) and { EnrageRemaining() < GCD() or Rage() > 90 } } and Spell(rampage) or Spell(execute) or PreviousGCDSpell(rampage) and Spell(bladestorm_fury) or { not IsEnraged() or AzeriteTraitRank(cold_steel_hot_blood_trait) > 1 } and Spell(bloodthirst) or IsEnraged() and Spell(dragon_roar) or Charges(raging_blow) == 2 and Spell(raging_blow) or Spell(bloodthirst) or { Talent(carnage_talent) or Talent(massacre_talent_fury) and Rage() < 80 or Talent(frothing_berserker_talent) and Rage() < 90 } and Spell(raging_blow) or Talent(furious_slash_talent) and Spell(furious_slash) or Spell(whirlwind_fury)
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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams_essence)
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
 #recklessness,if=!talent.furious_slash.enabled
 if not Talent(furious_slash_talent) Spell(recklessness)
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
  #focused_azerite_beam,if=!buff.recklessness.up&!buff.siegebreaker.up
  if not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) Spell(focused_azerite_beam)
  #concentrated_flame,if=!buff.recklessness.up&!buff.siegebreaker.up&dot.concentrated_flame_burn.remains=0
  if not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 Spell(concentrated_flame_essence)
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
   #heroic_leap,if=(raid_event.movement.distance>25&raid_event.movement.in>45)
   if target.Distance() > 25 and 600 > 45 and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)

   unless Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage)
   {
    #purifying_blast,if=!buff.recklessness.up&!buff.siegebreaker.up
    if not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) Spell(purifying_blast)
    #ripple_in_space,if=!buff.recklessness.up&!buff.siegebreaker.up
    if not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) Spell(ripple_in_space_essence)
    #worldvein_resonance,if=!buff.recklessness.up&!buff.siegebreaker.up
    if not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) Spell(worldvein_resonance_essence)

    unless not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(focused_azerite_beam) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence)
    {
     #the_unbound_force,if=buff.reckless_force.up
     if BuffPresent(reckless_force_buff) Spell(the_unbound_force)

     unless Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury)
     {
      #run_action_list,name=single_target
      FurySingletargetShortCdActions()
     }
    }
   }
  }
 }
}

AddFunction FuryDefaultShortCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge) or target.Distance() > 5 and FuryMovementShortCdPostConditions() or Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(focused_azerite_beam) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury) or FurySingletargetShortCdPostConditions()
}

AddFunction FuryDefaultCdActions
{
 FuryInterruptActions()

 unless CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge)
 {
  #run_action_list,name=movement,if=movement.distance>5
  if target.Distance() > 5 FuryMovementCdActions()

  unless target.Distance() > 5 and FuryMovementCdPostConditions() or target.Distance() > 25 and 600 > 45 and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap)
  {
   #potion
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)

   unless Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage)
   {
    #blood_of_the_enemy,if=buff.recklessness.up
    if BuffPresent(recklessness_buff) Spell(blood_of_the_enemy)

    unless not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(purifying_blast) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(ripple_in_space_essence) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(worldvein_resonance_essence) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(focused_azerite_beam) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force)
    {
     #guardian_of_azeroth,if=!buff.recklessness.up
     if not BuffPresent(recklessness_buff) Spell(guardian_of_azeroth)
     #memory_of_lucid_dreams,if=!buff.recklessness.up
     if not BuffPresent(recklessness_buff) Spell(memory_of_lucid_dreams_essence)
     #recklessness,if=!essence.condensed_lifeforce.major&!essence.blood_of_the_enemy.major|cooldown.guardian_of_azeroth.remains>20|buff.guardian_of_azeroth.up|cooldown.blood_of_the_enemy.remains<gcd
     if not AzeriteEssenceIsMajor(condensed_lifeforce_essence_id) and not AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) or SpellCooldown(guardian_of_azeroth) > 20 or BuffPresent(guardian_of_azeroth_buff) or SpellCooldown(blood_of_the_enemy) < GCD() Spell(recklessness)

     unless Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury)
     {
      #use_item,name=ramping_amplitude_gigavolt_engine
      FuryUseItemActions()
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
}

AddFunction FuryDefaultCdPostConditions
{
 CheckBoxOn(opt_melee_range) and target.InRange(charge) and not target.InRange(pummel) and Spell(charge) or target.Distance() > 5 and FuryMovementCdPostConditions() or target.Distance() > 25 and 600 > 45 and CheckBoxOn(opt_melee_range) and target.Distance(atLeast 8) and target.Distance(atMost 40) and Spell(heroic_leap) or Talent(furious_slash_talent) and { BuffStacks(furious_slash_buff) < 3 or BuffRemaining(furious_slash_buff) < 3 or SpellCooldown(recklessness) < 3 and BuffRemaining(furious_slash_buff) < 9 } and Spell(furious_slash) or SpellCooldown(recklessness) < 3 and Spell(rampage) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(purifying_blast) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(ripple_in_space_essence) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(worldvein_resonance_essence) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and Spell(focused_azerite_beam) or not BuffPresent(recklessness_buff) and not BuffPresent(siegebreaker) and not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or Enemies() > 1 and not BuffPresent(whirlwind_buff) and Spell(whirlwind_fury) or FurySingletargetCdPostConditions()
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
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodthirst
# carnage_talent
# charge
# cold_steel_hot_blood_trait
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# condensed_lifeforce_essence_id
# dragon_roar
# execute
# fireblood
# focused_azerite_beam
# frothing_berserker_talent
# furious_slash
# furious_slash_buff
# furious_slash_talent
# guardian_of_azeroth
# guardian_of_azeroth_buff
# heroic_leap
# intimidating_shout
# item_unbridled_fury
# lights_judgment
# massacre_talent_fury
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# pummel
# purifying_blast
# quaking_palm
# raging_blow
# rampage
# reckless_force_buff
# recklessness
# recklessness_buff
# ripple_in_space_essence
# shockwave
# siegebreaker
# storm_bolt
# the_unbound_force
# war_stomp
# whirlwind_buff
# whirlwind_fury
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("WARRIOR", "fury", name, desc, code, "script")
end
do
    local name = "sc_t23_warrior_protection"
    local desc = "[8.2] Simulationcraft: T23_Warrior_Protection"
    local code = [[
# Based on SimulationCraft profile "T23_Warrior_Protection".
#	class=warrior
#	spec=protection
#	talents=1223211

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_warrior_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=protection)

AddFunction ProtectionInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(pummel) and target.IsInterruptible() Spell(pummel)
  if target.Distance(less 10) and not target.Classification(worldboss) Spell(shockwave)
  if target.InRange(storm_bolt) and not target.Classification(worldboss) Spell(storm_bolt)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
  if target.InRange(intimidating_shout) and not target.Classification(worldboss) Spell(intimidating_shout)
 }
}

AddFunction ProtectionUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction ProtectionGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not InFlightToTarget(intercept) and not InFlightToTarget(heroic_leap) and not target.InRange(pummel)
 {
  if target.InRange(intercept) Spell(intercept)
  if SpellCharges(intercept) == 0 and target.Distance(atLeast 8) and target.Distance(atMost 40) Spell(heroic_leap)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.st

AddFunction ProtectionStMainActions
{
 #thunder_clap,if=spell_targets.thunder_clap=2&talent.unstoppable_force.enabled&buff.avatar.up
 if Enemies() == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) Spell(thunder_clap)
 #shield_block,if=cooldown.shield_slam.ready&buff.shield_block.down
 if SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) Spell(shield_block)
 #shield_slam,if=buff.shield_block.up
 if BuffPresent(shield_block_buff) Spell(shield_slam)
 #thunder_clap,if=(talent.unstoppable_force.enabled&buff.avatar.up)
 if Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) Spell(thunder_clap)
 #shield_slam
 Spell(shield_slam)
 #dragon_roar
 Spell(dragon_roar)
 #thunder_clap
 Spell(thunder_clap)
 #revenge
 Spell(revenge)
 #devastate
 Spell(devastate)
}

AddFunction ProtectionStMainPostConditions
{
}

AddFunction ProtectionStShortCdActions
{
 unless Enemies() == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) and Spell(shield_block) or BuffPresent(shield_block_buff) and Spell(shield_slam) or Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap)
 {
  #demoralizing_shout,if=talent.booming_voice.enabled
  if Talent(booming_voice_talent) Spell(demoralizing_shout)

  unless Spell(shield_slam) or Spell(dragon_roar) or Spell(thunder_clap) or Spell(revenge)
  {
   #ravager
   Spell(ravager)
  }
 }
}

AddFunction ProtectionStShortCdPostConditions
{
 Enemies() == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) and Spell(shield_block) or BuffPresent(shield_block_buff) and Spell(shield_slam) or Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or Spell(shield_slam) or Spell(dragon_roar) or Spell(thunder_clap) or Spell(revenge) or Spell(devastate)
}

AddFunction ProtectionStCdActions
{
 unless Enemies() == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) and Spell(shield_block) or BuffPresent(shield_block_buff) and Spell(shield_slam) or Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or Talent(booming_voice_talent) and Spell(demoralizing_shout)
 {
  #anima_of_death,if=buff.last_stand.up
  if BuffPresent(last_stand_buff) Spell(anima_of_death)

  unless Spell(shield_slam)
  {
   #use_item,name=ashvanes_razor_coral,target_if=debuff.razor_coral_debuff.stack=0
   if target.DebuffStacks(razor_coral) == 0 ProtectionUseItemActions()
   #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.stack>7&(cooldown.avatar.remains<5|buff.avatar.up)
   if target.DebuffStacks(razor_coral) > 7 and { SpellCooldown(avatar) < 5 or BuffPresent(avatar_buff) } ProtectionUseItemActions()

   unless Spell(dragon_roar) or Spell(thunder_clap) or Spell(revenge)
   {
    #use_item,name=grongs_primal_rage,if=buff.avatar.down|cooldown.shield_slam.remains>=4
    if BuffExpires(avatar_buff) or SpellCooldown(shield_slam) >= 4 ProtectionUseItemActions()
   }
  }
 }
}

AddFunction ProtectionStCdPostConditions
{
 Enemies() == 2 and Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) and Spell(shield_block) or BuffPresent(shield_block_buff) and Spell(shield_slam) or Talent(unstoppable_force_talent) and BuffPresent(avatar_buff) and Spell(thunder_clap) or Talent(booming_voice_talent) and Spell(demoralizing_shout) or Spell(shield_slam) or Spell(dragon_roar) or Spell(thunder_clap) or Spell(revenge) or Spell(ravager) or Spell(devastate)
}

### actions.precombat

AddFunction ProtectionPrecombatMainActions
{
}

AddFunction ProtectionPrecombatMainPostConditions
{
}

AddFunction ProtectionPrecombatShortCdActions
{
}

AddFunction ProtectionPrecombatShortCdPostConditions
{
}

AddFunction ProtectionPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_superior_battle_potion_of_strength usable=1)
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams_essence)
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
}

AddFunction ProtectionPrecombatCdPostConditions
{
}

### actions.aoe

AddFunction ProtectionAoeMainActions
{
 #thunder_clap
 Spell(thunder_clap)
 #dragon_roar
 Spell(dragon_roar)
 #revenge
 Spell(revenge)
 #shield_block,if=cooldown.shield_slam.ready&buff.shield_block.down
 if SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) Spell(shield_block)
 #shield_slam
 Spell(shield_slam)
}

AddFunction ProtectionAoeMainPostConditions
{
}

AddFunction ProtectionAoeShortCdActions
{
 unless Spell(thunder_clap)
 {
  #demoralizing_shout,if=talent.booming_voice.enabled
  if Talent(booming_voice_talent) Spell(demoralizing_shout)

  unless Spell(dragon_roar) or Spell(revenge)
  {
   #ravager
   Spell(ravager)
  }
 }
}

AddFunction ProtectionAoeShortCdPostConditions
{
 Spell(thunder_clap) or Spell(dragon_roar) or Spell(revenge) or SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) and Spell(shield_block) or Spell(shield_slam)
}

AddFunction ProtectionAoeCdActions
{
 unless Spell(thunder_clap)
 {
  #memory_of_lucid_dreams,if=buff.avatar.down
  if BuffExpires(avatar_buff) Spell(memory_of_lucid_dreams_essence)

  unless Talent(booming_voice_talent) and Spell(demoralizing_shout)
  {
   #anima_of_death,if=buff.last_stand.up
   if BuffPresent(last_stand_buff) Spell(anima_of_death)

   unless Spell(dragon_roar) or Spell(revenge)
   {
    #use_item,name=grongs_primal_rage,if=buff.avatar.down|cooldown.thunder_clap.remains>=4
    if BuffExpires(avatar_buff) or SpellCooldown(thunder_clap) >= 4 ProtectionUseItemActions()
   }
  }
 }
}

AddFunction ProtectionAoeCdPostConditions
{
 Spell(thunder_clap) or Talent(booming_voice_talent) and Spell(demoralizing_shout) or Spell(dragon_roar) or Spell(revenge) or Spell(ravager) or SpellCooldown(shield_slam) == 0 and BuffExpires(shield_block_buff) and Spell(shield_block) or Spell(shield_slam)
}

### actions.default

AddFunction ProtectionDefaultMainActions
{
 #ignore_pain,if=rage.deficit<25+20*talent.booming_voice.enabled*cooldown.demoralizing_shout.ready
 if RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } Spell(ignore_pain)
 #concentrated_flame,if=buff.avatar.down
 if BuffExpires(avatar_buff) Spell(concentrated_flame_essence)
 #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
 if Enemies() >= 3 ProtectionAoeMainActions()

 unless Enemies() >= 3 and ProtectionAoeMainPostConditions()
 {
  #call_action_list,name=st
  ProtectionStMainActions()
 }
}

AddFunction ProtectionDefaultMainPostConditions
{
 Enemies() >= 3 and ProtectionAoeMainPostConditions() or ProtectionStMainPostConditions()
}

AddFunction ProtectionDefaultShortCdActions
{
 #auto_attack
 ProtectionGetInMeleeRange()

 unless TimeInCombat() == 0 and Spell(intercept) or RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } and Spell(ignore_pain)
 {
  #worldvein_resonance,if=cooldown.avatar.remains<=2
  if SpellCooldown(avatar) <= 2 Spell(worldvein_resonance_essence)
  #ripple_in_space
  Spell(ripple_in_space_essence)

  unless BuffExpires(avatar_buff) and Spell(concentrated_flame_essence)
  {
   #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
   if Enemies() >= 3 ProtectionAoeShortCdActions()

   unless Enemies() >= 3 and ProtectionAoeShortCdPostConditions()
   {
    #call_action_list,name=st
    ProtectionStShortCdActions()
   }
  }
 }
}

AddFunction ProtectionDefaultShortCdPostConditions
{
 TimeInCombat() == 0 and Spell(intercept) or RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } and Spell(ignore_pain) or BuffExpires(avatar_buff) and Spell(concentrated_flame_essence) or Enemies() >= 3 and ProtectionAoeShortCdPostConditions() or ProtectionStShortCdPostConditions()
}

AddFunction ProtectionDefaultCdActions
{
 ProtectionInterruptActions()

 unless TimeInCombat() == 0 and Spell(intercept)
 {
  #use_items,if=cooldown.avatar.remains<=gcd|buff.avatar.up
  if SpellCooldown(avatar) <= GCD() or BuffPresent(avatar_buff) ProtectionUseItemActions()
  #blood_fury
  Spell(blood_fury_ap)
  #berserking
  Spell(berserking)
  #arcane_torrent
  Spell(arcane_torrent_rage)
  #lights_judgment
  Spell(lights_judgment)
  #fireblood
  Spell(fireblood)
  #ancestral_call
  Spell(ancestral_call)
  #potion,if=buff.avatar.up|target.time_to_die<25
  if { BuffPresent(avatar_buff) or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_superior_battle_potion_of_strength usable=1)

  unless RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } and Spell(ignore_pain) or SpellCooldown(avatar) <= 2 and Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence)
  {
   #memory_of_lucid_dreams
   Spell(memory_of_lucid_dreams_essence)

   unless BuffExpires(avatar_buff) and Spell(concentrated_flame_essence)
   {
    #last_stand,if=cooldown.anima_of_death.remains<=2
    if SpellCooldown(anima_of_death) <= 2 Spell(last_stand)
    #avatar
    Spell(avatar)
    #run_action_list,name=aoe,if=spell_targets.thunder_clap>=3
    if Enemies() >= 3 ProtectionAoeCdActions()

    unless Enemies() >= 3 and ProtectionAoeCdPostConditions()
    {
     #call_action_list,name=st
     ProtectionStCdActions()
    }
   }
  }
 }
}

AddFunction ProtectionDefaultCdPostConditions
{
 TimeInCombat() == 0 and Spell(intercept) or RageDeficit() < 25 + 20 * TalentPoints(booming_voice_talent) * { SpellCooldown(demoralizing_shout) == 0 } and Spell(ignore_pain) or SpellCooldown(avatar) <= 2 and Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence) or BuffExpires(avatar_buff) and Spell(concentrated_flame_essence) or Enemies() >= 3 and ProtectionAoeCdPostConditions() or ProtectionStCdPostConditions()
}

### Protection icons.

AddCheckBox(opt_warrior_protection_aoe L(AOE) default specialization=protection)

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=shortcd specialization=protection
{
 if not InCombat() ProtectionPrecombatShortCdActions()
 unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
 {
  ProtectionDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_warrior_protection_aoe help=shortcd specialization=protection
{
 if not InCombat() ProtectionPrecombatShortCdActions()
 unless not InCombat() and ProtectionPrecombatShortCdPostConditions()
 {
  ProtectionDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=protection
{
 if not InCombat() ProtectionPrecombatMainActions()
 unless not InCombat() and ProtectionPrecombatMainPostConditions()
 {
  ProtectionDefaultMainActions()
 }
}

AddIcon checkbox=opt_warrior_protection_aoe help=aoe specialization=protection
{
 if not InCombat() ProtectionPrecombatMainActions()
 unless not InCombat() and ProtectionPrecombatMainPostConditions()
 {
  ProtectionDefaultMainActions()
 }
}

AddIcon checkbox=!opt_warrior_protection_aoe enemies=1 help=cd specialization=protection
{
 if not InCombat() ProtectionPrecombatCdActions()
 unless not InCombat() and ProtectionPrecombatCdPostConditions()
 {
  ProtectionDefaultCdActions()
 }
}

AddIcon checkbox=opt_warrior_protection_aoe help=cd specialization=protection
{
 if not InCombat() ProtectionPrecombatCdActions()
 unless not InCombat() and ProtectionPrecombatCdPostConditions()
 {
  ProtectionDefaultCdActions()
 }
}

### Required symbols
# ancestral_call
# anima_of_death
# arcane_torrent_rage
# avatar
# avatar_buff
# berserking
# blood_fury_ap
# booming_voice_talent
# concentrated_flame_essence
# demoralizing_shout
# devastate
# dragon_roar
# fireblood
# guardian_of_azeroth
# heroic_leap
# ignore_pain
# intercept
# intimidating_shout
# item_superior_battle_potion_of_strength
# last_stand
# last_stand_buff
# lights_judgment
# memory_of_lucid_dreams_essence
# pummel
# quaking_palm
# ravager
# razor_coral
# revenge
# ripple_in_space_essence
# shield_block
# shield_block_buff
# shield_slam
# shockwave
# storm_bolt
# thunder_clap
# unstoppable_force_talent
# war_stomp
# worldvein_resonance_essence
]]
    OvaleScripts:RegisterScript("WARRIOR", "protection", name, desc, code, "script")
end
