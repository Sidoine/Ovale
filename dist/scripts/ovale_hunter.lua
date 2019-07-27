local __exports = LibStub:NewLibrary("ovale/scripts/ovale_hunter", 80201)
if not __exports then return end
__exports.registerHunter = function(OvaleScripts)
    do
        local name = "sc_t23_hunter_beast_mastery"
        local desc = "[8.2] Simulationcraft: T23_Hunter_Beast_Mastery"
        local code = [[
# Based on SimulationCraft profile "T23_Hunter_Beast_Mastery".
#	class=hunter
#	spec=beast_mastery
#	talents=1303011

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=beast_mastery)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=beast_mastery)

AddFunction BeastmasteryInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counter_shot) and target.IsInterruptible() Spell(counter_shot)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction BeastmasteryUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction BeastmasterySummonPet
{
 if pet.IsDead()
 {
  Spell(revive_pet)
 }
 if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
}

### actions.st

AddFunction BeastmasteryStMainActions
{
 #barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<gcd|cooldown.bestial_wrath.remains&(full_recharge_time<gcd|azerite.primal_instincts.enabled&cooldown.aspect_of_the_wild.remains<gcd)
 if pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) < GCD() or SpellCooldown(bestial_wrath) > 0 and { SpellFullRecharge(barbed_shot) < GCD() or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } Spell(barbed_shot)
 #concentrated_flame,if=focus+focus.regen*gcd<focus.max&buff.bestial_wrath.down&(!dot.concentrated_flame_burn.remains&!action.concentrated_flame.in_flight)|full_recharge_time<gcd|target.time_to_die<5
 if Focus() + FocusRegenRate() * GCD() < MaxFocus() and BuffExpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() or target.TimeToDie() < 5 Spell(concentrated_flame_essence)
 #kill_command
 if pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() Spell(kill_command)
 #chimaera_shot
 Spell(chimaera_shot)
 #dire_beast
 Spell(dire_beast)
 #barbed_shot,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.cat.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|azerite.dance_of_death.rank>1&buff.dance_of_death.down&crit_pct_current>40|target.time_to_die<9
 if pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 Spell(barbed_shot)
 #cobra_shot,if=(focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost|cooldown.kill_command.remains>1+gcd|buff.memory_of_lucid_dreams.up)&cooldown.kill_command.remains>1
 if { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() or BuffPresent(memory_of_lucid_dreams_essence_buff) } and SpellCooldown(kill_command) > 1 Spell(cobra_shot)
 #barbed_shot,if=charges_fractional>1.4
 if Charges(barbed_shot count=0) > 1.4 Spell(barbed_shot)
}

AddFunction BeastmasteryStMainPostConditions
{
}

AddFunction BeastmasteryStShortCdActions
{
 unless { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) < GCD() or SpellCooldown(bestial_wrath) > 0 and { SpellFullRecharge(barbed_shot) < GCD() or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } } and Spell(barbed_shot) or { Focus() + FocusRegenRate() * GCD() < MaxFocus() and BuffExpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() or target.TimeToDie() < 5 } and Spell(concentrated_flame_essence)
 {
  #a_murder_of_crows,if=cooldown.bestial_wrath.remains
  if SpellCooldown(bestial_wrath) > 0 Spell(a_murder_of_crows)
  #focused_azerite_beam,if=buff.bestial_wrath.down|target.time_to_die<5
  if BuffExpires(bestial_wrath_buff) or target.TimeToDie() < 5 Spell(focused_azerite_beam)
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10|target.time_to_die<5
  if BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 or target.TimeToDie() < 5 Spell(the_unbound_force)
  #bestial_wrath
  Spell(bestial_wrath)

  unless pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(chimaera_shot) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 } and Spell(barbed_shot)
  {
   #purifying_blast,if=buff.bestial_wrath.down|target.time_to_die<8
   if BuffExpires(bestial_wrath_buff) or target.TimeToDie() < 8 Spell(purifying_blast)
   #barrage
   Spell(barrage)

   unless { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() or BuffPresent(memory_of_lucid_dreams_essence_buff) } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot)
   {
    #spitting_cobra
    Spell(spitting_cobra)
   }
  }
 }
}

AddFunction BeastmasteryStShortCdPostConditions
{
 { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) < GCD() or SpellCooldown(bestial_wrath) > 0 and { SpellFullRecharge(barbed_shot) < GCD() or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } } and Spell(barbed_shot) or { Focus() + FocusRegenRate() * GCD() < MaxFocus() and BuffExpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() or target.TimeToDie() < 5 } and Spell(concentrated_flame_essence) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(chimaera_shot) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 } and Spell(barbed_shot) or { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() or BuffPresent(memory_of_lucid_dreams_essence_buff) } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot) or Charges(barbed_shot count=0) > 1.4 and Spell(barbed_shot)
}

AddFunction BeastmasteryStCdActions
{
 unless { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) < GCD() or SpellCooldown(bestial_wrath) > 0 and { SpellFullRecharge(barbed_shot) < GCD() or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } } and Spell(barbed_shot) or { Focus() + FocusRegenRate() * GCD() < MaxFocus() and BuffExpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() or target.TimeToDie() < 5 } and Spell(concentrated_flame_essence)
 {
  #aspect_of_the_wild,if=cooldown.barbed_shot.charges<2|pet.cat.buff.frenzy.stack>2|!azerite.primal_instincts.enabled
  if SpellCharges(barbed_shot) < 2 or pet.BuffStacks(pet_frenzy_buff) > 2 or not HasAzeriteTrait(primal_instincts_trait) Spell(aspect_of_the_wild)
  #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
  if BuffPresent(aspect_of_the_wild_buff) and BuffPresent(bestial_wrath_buff) or target.TimeToDie() < 15 Spell(stampede)

  unless SpellCooldown(bestial_wrath) > 0 and Spell(a_murder_of_crows) or { BuffExpires(bestial_wrath_buff) or target.TimeToDie() < 5 } and Spell(focused_azerite_beam) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 or target.TimeToDie() < 5 } and Spell(the_unbound_force) or Spell(bestial_wrath) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(chimaera_shot) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 } and Spell(barbed_shot) or { BuffExpires(bestial_wrath_buff) or target.TimeToDie() < 8 } and Spell(purifying_blast)
  {
   #blood_of_the_enemy
   Spell(blood_of_the_enemy)
  }
 }
}

AddFunction BeastmasteryStCdPostConditions
{
 { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) < GCD() or SpellCooldown(bestial_wrath) > 0 and { SpellFullRecharge(barbed_shot) < GCD() or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } } and Spell(barbed_shot) or { Focus() + FocusRegenRate() * GCD() < MaxFocus() and BuffExpires(bestial_wrath_buff) and not target.DebuffRemaining(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() or target.TimeToDie() < 5 } and Spell(concentrated_flame_essence) or SpellCooldown(bestial_wrath) > 0 and Spell(a_murder_of_crows) or { BuffExpires(bestial_wrath_buff) or target.TimeToDie() < 5 } and Spell(focused_azerite_beam) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 or target.TimeToDie() < 5 } and Spell(the_unbound_force) or Spell(bestial_wrath) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(chimaera_shot) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 } and Spell(barbed_shot) or { BuffExpires(bestial_wrath_buff) or target.TimeToDie() < 8 } and Spell(purifying_blast) or Spell(barrage) or { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() or BuffPresent(memory_of_lucid_dreams_essence_buff) } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot) or Spell(spitting_cobra) or Charges(barbed_shot count=0) > 1.4 and Spell(barbed_shot)
}

### actions.precombat

AddFunction BeastmasteryPrecombatMainActions
{
}

AddFunction BeastmasteryPrecombatMainPostConditions
{
}

AddFunction BeastmasteryPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #summon_pet
 BeastmasterySummonPet()
 #worldvein_resonance
 Spell(worldvein_resonance_essence)
 #focused_azerite_beam,if=!raid_event.invulnerable.exists
 if not 0 Spell(focused_azerite_beam)
 #bestial_wrath,precast_time=1.5,if=azerite.primal_instincts.enabled&!essence.essence_of_the_focusing_iris.major&(equipped.azsharas_font_of_power|!equipped.pocketsized_computation_device|!cooldown.cyclotronic_blast.duration)
 if HasAzeriteTrait(primal_instincts_trait) and not AzeriteEssenceIsMajor(essence_of_the_focusing_iris_essence_id) and { HasEquippedItem(azsharas_font_of_power_item) or not HasEquippedItem(pocket_sized_computation_device_item) or not SpellCooldownDuration(cyclotronic_blast) } Spell(bestial_wrath)
}

AddFunction BeastmasteryPrecombatShortCdPostConditions
{
}

AddFunction BeastmasteryPrecombatCdActions
{
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)

 unless Spell(worldvein_resonance_essence)
 {
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)
  #memory_of_lucid_dreams
  Spell(memory_of_lucid_dreams_essence)
  #use_item,name=azsharas_font_of_power
  BeastmasteryUseItemActions()
  #use_item,effect_name=cyclotronic_blast,if=!raid_event.invulnerable.exists
  if not 0 BeastmasteryUseItemActions()

  unless not 0 and Spell(focused_azerite_beam)
  {
   #aspect_of_the_wild,precast_time=1.1,if=!azerite.primal_instincts.enabled&!essence.essence_of_the_focusing_iris.major&(equipped.azsharas_font_of_power|!equipped.pocketsized_computation_device|!cooldown.cyclotronic_blast.duration)
   if not HasAzeriteTrait(primal_instincts_trait) and not AzeriteEssenceIsMajor(essence_of_the_focusing_iris_essence_id) and { HasEquippedItem(azsharas_font_of_power_item) or not HasEquippedItem(pocket_sized_computation_device_item) or not SpellCooldownDuration(cyclotronic_blast) } Spell(aspect_of_the_wild)
  }
 }
}

AddFunction BeastmasteryPrecombatCdPostConditions
{
 Spell(worldvein_resonance_essence) or not 0 and Spell(focused_azerite_beam) or HasAzeriteTrait(primal_instincts_trait) and not AzeriteEssenceIsMajor(essence_of_the_focusing_iris_essence_id) and { HasEquippedItem(azsharas_font_of_power_item) or not HasEquippedItem(pocket_sized_computation_device_item) or not SpellCooldownDuration(cyclotronic_blast) } and Spell(bestial_wrath)
}

### actions.cleave

AddFunction BeastmasteryCleaveMainActions
{
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max
 if pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() Spell(barbed_shot)
 #multishot,if=gcd.max-pet.cat.buff.beast_cleave.remains>0.25
 if GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 Spell(multishot_bm)
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=full_recharge_time<gcd.max&cooldown.bestial_wrath.remains
 if SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 Spell(barbed_shot)
 #chimaera_shot
 Spell(chimaera_shot)
 #kill_command,if=active_enemies<4|!azerite.rapid_reload.enabled
 if { Enemies() < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() Spell(kill_command)
 #dire_beast
 Spell(dire_beast)
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.cat.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|charges_fractional>1.4|target.time_to_die<9
 if pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 Spell(barbed_shot)
 #concentrated_flame
 Spell(concentrated_flame_essence)
 #multishot,if=azerite.rapid_reload.enabled&active_enemies>2
 if HasAzeriteTrait(rapid_reload_trait) and Enemies() > 2 Spell(multishot_bm)
 #cobra_shot,if=cooldown.kill_command.remains>focus.time_to_max&(active_enemies<3|!azerite.rapid_reload.enabled)
 if SpellCooldown(kill_command) > TimeToMaxFocus() and { Enemies() < 3 or not HasAzeriteTrait(rapid_reload_trait) } Spell(cobra_shot)
}

AddFunction BeastmasteryCleaveMainPostConditions
{
}

AddFunction BeastmasteryCleaveShortCdActions
{
 unless pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 and Spell(barbed_shot)
 {
  #bestial_wrath,if=cooldown.aspect_of_the_wild.remains_guess>20|talent.one_with_the_pack.enabled|target.time_to_die<15
  if SpellCooldown(aspect_of_the_wild) > 20 or Talent(one_with_the_pack_talent) or target.TimeToDie() < 15 Spell(bestial_wrath)

  unless Spell(chimaera_shot)
  {
   #a_murder_of_crows
   Spell(a_murder_of_crows)
   #barrage
   Spell(barrage)

   unless { Enemies() < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 } and Spell(barbed_shot)
   {
    #focused_azerite_beam
    Spell(focused_azerite_beam)
    #purifying_blast
    Spell(purifying_blast)

    unless Spell(concentrated_flame_essence)
    {
     #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
     if BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 Spell(the_unbound_force)

     unless HasAzeriteTrait(rapid_reload_trait) and Enemies() > 2 and Spell(multishot_bm) or SpellCooldown(kill_command) > TimeToMaxFocus() and { Enemies() < 3 or not HasAzeriteTrait(rapid_reload_trait) } and Spell(cobra_shot)
     {
      #spitting_cobra
      Spell(spitting_cobra)
     }
    }
   }
  }
 }
}

AddFunction BeastmasteryCleaveShortCdPostConditions
{
 pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 and Spell(barbed_shot) or Spell(chimaera_shot) or { Enemies() < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 } and Spell(barbed_shot) or Spell(concentrated_flame_essence) or HasAzeriteTrait(rapid_reload_trait) and Enemies() > 2 and Spell(multishot_bm) or SpellCooldown(kill_command) > TimeToMaxFocus() and { Enemies() < 3 or not HasAzeriteTrait(rapid_reload_trait) } and Spell(cobra_shot)
}

AddFunction BeastmasteryCleaveCdActions
{
 unless pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 and Spell(barbed_shot)
 {
  #aspect_of_the_wild
  Spell(aspect_of_the_wild)
  #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
  if BuffPresent(aspect_of_the_wild_buff) and BuffPresent(bestial_wrath_buff) or target.TimeToDie() < 15 Spell(stampede)

  unless { SpellCooldown(aspect_of_the_wild) > 20 or Talent(one_with_the_pack_talent) or target.TimeToDie() < 15 } and Spell(bestial_wrath) or Spell(chimaera_shot) or Spell(a_murder_of_crows) or Spell(barrage) or { Enemies() < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 } and Spell(barbed_shot) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(concentrated_flame_essence)
  {
   #blood_of_the_enemy
   Spell(blood_of_the_enemy)
  }
 }
}

AddFunction BeastmasteryCleaveCdPostConditions
{
 pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 and Spell(barbed_shot) or { SpellCooldown(aspect_of_the_wild) > 20 or Talent(one_with_the_pack_talent) or target.TimeToDie() < 15 } and Spell(bestial_wrath) or Spell(chimaera_shot) or Spell(a_murder_of_crows) or Spell(barrage) or { Enemies() < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 } and Spell(barbed_shot) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(concentrated_flame_essence) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or HasAzeriteTrait(rapid_reload_trait) and Enemies() > 2 and Spell(multishot_bm) or SpellCooldown(kill_command) > TimeToMaxFocus() and { Enemies() < 3 or not HasAzeriteTrait(rapid_reload_trait) } and Spell(cobra_shot) or Spell(spitting_cobra)
}

### actions.cds

AddFunction BeastmasteryCdsMainActions
{
}

AddFunction BeastmasteryCdsMainPostConditions
{
}

AddFunction BeastmasteryCdsShortCdActions
{
 #worldvein_resonance,if=buff.lifeblood.stack<4
 if BuffStacks(lifeblood_buff) < 4 Spell(worldvein_resonance_essence)
 #ripple_in_space
 Spell(ripple_in_space_essence)
}

AddFunction BeastmasteryCdsShortCdPostConditions
{
}

AddFunction BeastmasteryCdsCdActions
{
 #ancestral_call,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(ancestral_call)
 #fireblood,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(fireblood)
 #berserking,if=buff.aspect_of_the_wild.up&(target.time_to_die>cooldown.berserking.duration+duration|(target.health.pct<35|!talent.killer_instinct.enabled))|target.time_to_die<13
 if BuffPresent(aspect_of_the_wild_buff) and { target.TimeToDie() > SpellCooldownDuration(berserking) + BaseDuration(berserking) or target.HealthPercent() < 35 or not Talent(killer_instinct_talent) } or target.TimeToDie() < 13 Spell(berserking)
 #blood_fury,if=buff.aspect_of_the_wild.up&(target.time_to_die>cooldown.blood_fury.duration+duration|(target.health.pct<35|!talent.killer_instinct.enabled))|target.time_to_die<16
 if BuffPresent(aspect_of_the_wild_buff) and { target.TimeToDie() > SpellCooldownDuration(blood_fury_ap) + BaseDuration(blood_fury_ap) or target.HealthPercent() < 35 or not Talent(killer_instinct_talent) } or target.TimeToDie() < 16 Spell(blood_fury_ap)
 #lights_judgment,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains>gcd.max|!pet.cat.buff.frenzy.up
 if pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) > GCD() or not pet.BuffPresent(pet_frenzy_buff) Spell(lights_judgment)
 #potion,if=buff.bestial_wrath.up&buff.aspect_of_the_wild.up&(target.health.pct<35|!talent.killer_instinct.enabled)|target.time_to_die<25
 if { BuffPresent(bestial_wrath_buff) and BuffPresent(aspect_of_the_wild_buff) and { target.HealthPercent() < 35 or not Talent(killer_instinct_talent) } or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)

 unless BuffStacks(lifeblood_buff) < 4 and Spell(worldvein_resonance_essence)
 {
  #guardian_of_azeroth,if=cooldown.aspect_of_the_wild.remains<10|target.time_to_die>cooldown+duration|target.time_to_die<30
  if SpellCooldown(aspect_of_the_wild) < 10 or target.TimeToDie() > SpellCooldown(guardian_of_azeroth) + BaseDuration(guardian_of_azeroth) or target.TimeToDie() < 30 Spell(guardian_of_azeroth)

  unless Spell(ripple_in_space_essence)
  {
   #memory_of_lucid_dreams
   Spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction BeastmasteryCdsCdPostConditions
{
 BuffStacks(lifeblood_buff) < 4 and Spell(worldvein_resonance_essence) or Spell(ripple_in_space_essence)
}

### actions.default

AddFunction BeastmasteryDefaultMainActions
{
 #call_action_list,name=cds
 BeastmasteryCdsMainActions()

 unless BeastmasteryCdsMainPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if Enemies() < 2 BeastmasteryStMainActions()

  unless Enemies() < 2 and BeastmasteryStMainPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if Enemies() > 1 BeastmasteryCleaveMainActions()
  }
 }
}

AddFunction BeastmasteryDefaultMainPostConditions
{
 BeastmasteryCdsMainPostConditions() or Enemies() < 2 and BeastmasteryStMainPostConditions() or Enemies() > 1 and BeastmasteryCleaveMainPostConditions()
}

AddFunction BeastmasteryDefaultShortCdActions
{
 #call_action_list,name=cds
 BeastmasteryCdsShortCdActions()

 unless BeastmasteryCdsShortCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if Enemies() < 2 BeastmasteryStShortCdActions()

  unless Enemies() < 2 and BeastmasteryStShortCdPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if Enemies() > 1 BeastmasteryCleaveShortCdActions()
  }
 }
}

AddFunction BeastmasteryDefaultShortCdPostConditions
{
 BeastmasteryCdsShortCdPostConditions() or Enemies() < 2 and BeastmasteryStShortCdPostConditions() or Enemies() > 1 and BeastmasteryCleaveShortCdPostConditions()
}

AddFunction BeastmasteryDefaultCdActions
{
 BeastmasteryInterruptActions()
 #auto_shot
 #use_items
 BeastmasteryUseItemActions()
 #use_item,effect_name=cyclotronic_blast,if=!buff.bestial_wrath.up
 if not BuffPresent(bestial_wrath_buff) BeastmasteryUseItemActions()
 #use_item,name=ashvanes_razor_coral,if=buff.aspect_of_the_wild.remains>15|debuff.razor_coral_debuff.down|target.time_to_die<20
 if BuffRemaining(aspect_of_the_wild_buff) > 15 or target.DebuffExpires(razor_coral) or target.TimeToDie() < 20 BeastmasteryUseItemActions()
 #call_action_list,name=cds
 BeastmasteryCdsCdActions()

 unless BeastmasteryCdsCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if Enemies() < 2 BeastmasteryStCdActions()

  unless Enemies() < 2 and BeastmasteryStCdPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if Enemies() > 1 BeastmasteryCleaveCdActions()
  }
 }
}

AddFunction BeastmasteryDefaultCdPostConditions
{
 BeastmasteryCdsCdPostConditions() or Enemies() < 2 and BeastmasteryStCdPostConditions() or Enemies() > 1 and BeastmasteryCleaveCdPostConditions()
}

### Beastmastery icons.

AddCheckBox(opt_hunter_beast_mastery_aoe L(AOE) default specialization=beast_mastery)

AddIcon checkbox=!opt_hunter_beast_mastery_aoe enemies=1 help=shortcd specialization=beast_mastery
{
 if not InCombat() BeastmasteryPrecombatShortCdActions()
 unless not InCombat() and BeastmasteryPrecombatShortCdPostConditions()
 {
  BeastmasteryDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=shortcd specialization=beast_mastery
{
 if not InCombat() BeastmasteryPrecombatShortCdActions()
 unless not InCombat() and BeastmasteryPrecombatShortCdPostConditions()
 {
  BeastmasteryDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=beast_mastery
{
 if not InCombat() BeastmasteryPrecombatMainActions()
 unless not InCombat() and BeastmasteryPrecombatMainPostConditions()
 {
  BeastmasteryDefaultMainActions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=aoe specialization=beast_mastery
{
 if not InCombat() BeastmasteryPrecombatMainActions()
 unless not InCombat() and BeastmasteryPrecombatMainPostConditions()
 {
  BeastmasteryDefaultMainActions()
 }
}

AddIcon checkbox=!opt_hunter_beast_mastery_aoe enemies=1 help=cd specialization=beast_mastery
{
 if not InCombat() BeastmasteryPrecombatCdActions()
 unless not InCombat() and BeastmasteryPrecombatCdPostConditions()
 {
  BeastmasteryDefaultCdActions()
 }
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=cd specialization=beast_mastery
{
 if not InCombat() BeastmasteryPrecombatCdActions()
 unless not InCombat() and BeastmasteryPrecombatCdPostConditions()
 {
  BeastmasteryDefaultCdActions()
 }
}

### Required symbols
# a_murder_of_crows
# ancestral_call
# aspect_of_the_wild
# aspect_of_the_wild_buff
# azsharas_font_of_power_item
# barbed_shot
# barrage
# berserking
# bestial_wrath
# bestial_wrath_buff
# blood_fury_ap
# blood_of_the_enemy
# chimaera_shot
# cobra_shot
# concentrated_flame_burn_debuff
# concentrated_flame_essence
# counter_shot
# cyclotronic_blast
# dance_of_death_buff
# dance_of_death_trait
# dire_beast
# essence_of_the_focusing_iris_essence_id
# fireblood
# focused_azerite_beam
# guardian_of_azeroth
# item_unbridled_fury
# kill_command
# killer_instinct_talent
# lifeblood_buff
# lights_judgment
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# multishot_bm
# one_with_the_pack_talent
# pet_beast_cleave_buff
# pet_frenzy_buff
# pocket_sized_computation_device_item
# primal_instincts_trait
# purifying_blast
# quaking_palm
# rapid_reload_trait
# razor_coral
# reckless_force_buff
# reckless_force_counter
# revive_pet
# ripple_in_space_essence
# spitting_cobra
# stampede
# the_unbound_force
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("HUNTER", "beast_mastery", name, desc, code, "script")
    end
    do
        local name = "sc_t23_hunter_marksmanship"
        local desc = "[8.2] Simulationcraft: T23_Hunter_Marksmanship"
        local code = [[
# Based on SimulationCraft profile "T23_Hunter_Marksmanship".
#	class=hunter
#	spec=marksmanship
#	talents=1103031

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=marksmanship)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=marksmanship)

AddFunction MarksmanshipInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counter_shot) and target.IsInterruptible() Spell(counter_shot)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction MarksmanshipUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.trickshots

AddFunction MarksmanshipTrickshotsMainActions
{
 #aimed_shot,if=buff.trick_shots.up&ca_execute&buff.double_tap.up
 if BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) Spell(aimed_shot)
 #rapid_fire,if=buff.trick_shots.up&(azerite.focused_fire.enabled|azerite.in_the_rhythm.rank>1|azerite.surging_shots.enabled|talent.streamline.enabled)
 if BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } Spell(rapid_fire)
 #aimed_shot,if=buff.trick_shots.up&(buff.precise_shots.down|cooldown.aimed_shot.full_recharge_time<action.aimed_shot.cast_time|buff.trueshot.up)
 if BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } Spell(aimed_shot)
 #rapid_fire,if=buff.trick_shots.up
 if BuffPresent(trick_shots_buff) Spell(rapid_fire)
 #multishot,if=buff.trick_shots.down|buff.precise_shots.up&!buff.trueshot.up|focus>70
 if BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 Spell(multishot_mm)
 #concentrated_flame
 Spell(concentrated_flame_essence)
 #serpent_sting,if=refreshable&!action.serpent_sting.in_flight
 if target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) Spell(serpent_sting_mm)
 #steady_shot
 Spell(steady_shot)
}

AddFunction MarksmanshipTrickshotsMainPostConditions
{
}

AddFunction MarksmanshipTrickshotsShortCdActions
{
 #barrage
 Spell(barrage)
 #explosive_shot
 Spell(explosive_shot)

 unless BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 } and Spell(multishot_mm)
 {
  #focused_azerite_beam
  Spell(focused_azerite_beam)
  #purifying_blast
  Spell(purifying_blast)

  unless Spell(concentrated_flame_essence)
  {
   #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
   if BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 Spell(the_unbound_force)
   #piercing_shot
   Spell(piercing_shot)
   #a_murder_of_crows
   Spell(a_murder_of_crows)
  }
 }
}

AddFunction MarksmanshipTrickshotsShortCdPostConditions
{
 BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 } and Spell(multishot_mm) or Spell(concentrated_flame_essence) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or Spell(steady_shot)
}

AddFunction MarksmanshipTrickshotsCdActions
{
 unless Spell(barrage) or Spell(explosive_shot) or BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 } and Spell(multishot_mm) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(concentrated_flame_essence)
 {
  #blood_of_the_enemy
  Spell(blood_of_the_enemy)
 }
}

AddFunction MarksmanshipTrickshotsCdPostConditions
{
 Spell(barrage) or Spell(explosive_shot) or BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 } and Spell(multishot_mm) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(concentrated_flame_essence) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or Spell(piercing_shot) or Spell(a_murder_of_crows) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or Spell(steady_shot)
}

### actions.st

AddFunction MarksmanshipStMainActions
{
 #serpent_sting,if=refreshable&!action.serpent_sting.in_flight
 if target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) Spell(serpent_sting_mm)
 #rapid_fire,if=buff.trueshot.down|focus<70
 if BuffExpires(trueshot_buff) or Focus() < 70 Spell(rapid_fire)
 #arcane_shot,if=buff.trueshot.up&buff.master_marksman.up&!buff.memory_of_lucid_dreams.up
 if BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) Spell(arcane_shot)
 #aimed_shot,if=buff.trueshot.up|(buff.double_tap.down|ca_execute)&buff.precise_shots.down|full_recharge_time<cast_time&cooldown.trueshot.remains
 if BuffPresent(trueshot_buff) or { BuffExpires(double_tap_buff) or Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } } and BuffExpires(precise_shots_buff) or SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) and SpellCooldown(trueshot) > 0 Spell(aimed_shot)
 #arcane_shot,if=buff.trueshot.up&buff.master_marksman.up&buff.memory_of_lucid_dreams.up
 if BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and BuffPresent(memory_of_lucid_dreams_essence_buff) Spell(arcane_shot)
 #concentrated_flame,if=!buff.trueshot.up
 if not BuffPresent(trueshot_buff) Spell(concentrated_flame_essence)
 #arcane_shot,if=buff.trueshot.down&(buff.precise_shots.up&(focus>41|buff.master_marksman.up)|(focus>50&azerite.focused_fire.enabled|focus>75)&(cooldown.trueshot.remains>5|focus>80)|target.time_to_die<5)
 if BuffExpires(trueshot_buff) and { BuffPresent(precise_shots_buff) and { Focus() > 41 or BuffPresent(master_marksman_buff) } or { Focus() > 50 and HasAzeriteTrait(focused_fire_trait) or Focus() > 75 } and { SpellCooldown(trueshot) > 5 or Focus() > 80 } or target.TimeToDie() < 5 } Spell(arcane_shot)
 #steady_shot
 Spell(steady_shot)
}

AddFunction MarksmanshipStMainPostConditions
{
}

AddFunction MarksmanshipStShortCdActions
{
 #explosive_shot
 Spell(explosive_shot)
 #barrage,if=active_enemies>1
 if Enemies() > 1 Spell(barrage)
 #a_murder_of_crows
 Spell(a_murder_of_crows)

 unless target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(trueshot_buff) or Focus() < 70 } and Spell(rapid_fire)
 {
  #focused_azerite_beam,if=!buff.trueshot.up
  if not BuffPresent(trueshot_buff) Spell(focused_azerite_beam)

  unless BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or { BuffPresent(trueshot_buff) or { BuffExpires(double_tap_buff) or Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } } and BuffExpires(precise_shots_buff) or SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) and SpellCooldown(trueshot) > 0 } and Spell(aimed_shot) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot)
  {
   #piercing_shot
   Spell(piercing_shot)
   #purifying_blast,if=!buff.trueshot.up
   if not BuffPresent(trueshot_buff) Spell(purifying_blast)

   unless not BuffPresent(trueshot_buff) and Spell(concentrated_flame_essence)
   {
    #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
    if BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 Spell(the_unbound_force)
   }
  }
 }
}

AddFunction MarksmanshipStShortCdPostConditions
{
 target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(trueshot_buff) or Focus() < 70 } and Spell(rapid_fire) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or { BuffPresent(trueshot_buff) or { BuffExpires(double_tap_buff) or Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } } and BuffExpires(precise_shots_buff) or SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) and SpellCooldown(trueshot) > 0 } and Spell(aimed_shot) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or not BuffPresent(trueshot_buff) and Spell(concentrated_flame_essence) or BuffExpires(trueshot_buff) and { BuffPresent(precise_shots_buff) and { Focus() > 41 or BuffPresent(master_marksman_buff) } or { Focus() > 50 and HasAzeriteTrait(focused_fire_trait) or Focus() > 75 } and { SpellCooldown(trueshot) > 5 or Focus() > 80 } or target.TimeToDie() < 5 } and Spell(arcane_shot) or Spell(steady_shot)
}

AddFunction MarksmanshipStCdActions
{
 unless Spell(explosive_shot) or Enemies() > 1 and Spell(barrage) or Spell(a_murder_of_crows) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(trueshot_buff) or Focus() < 70 } and Spell(rapid_fire)
 {
  #blood_of_the_enemy,if=buff.trueshot.up&(buff.unerring_vision.stack>4|!azerite.unerring_vision.enabled)|target.time_to_die<11
  if BuffPresent(trueshot_buff) and { BuffStacks(unerring_vision_buff) > 4 or not HasAzeriteTrait(unerring_vision_trait) } or target.TimeToDie() < 11 Spell(blood_of_the_enemy)
 }
}

AddFunction MarksmanshipStCdPostConditions
{
 Spell(explosive_shot) or Enemies() > 1 and Spell(barrage) or Spell(a_murder_of_crows) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(trueshot_buff) or Focus() < 70 } and Spell(rapid_fire) or not BuffPresent(trueshot_buff) and Spell(focused_azerite_beam) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or { BuffPresent(trueshot_buff) or { BuffExpires(double_tap_buff) or Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } } and BuffExpires(precise_shots_buff) or SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) and SpellCooldown(trueshot) > 0 } and Spell(aimed_shot) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or Spell(piercing_shot) or not BuffPresent(trueshot_buff) and Spell(purifying_blast) or not BuffPresent(trueshot_buff) and Spell(concentrated_flame_essence) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or BuffExpires(trueshot_buff) and { BuffPresent(precise_shots_buff) and { Focus() > 41 or BuffPresent(master_marksman_buff) } or { Focus() > 50 and HasAzeriteTrait(focused_fire_trait) or Focus() > 75 } and { SpellCooldown(trueshot) > 5 or Focus() > 80 } or target.TimeToDie() < 5 } and Spell(arcane_shot) or Spell(steady_shot)
}

### actions.precombat

AddFunction MarksmanshipPrecombatMainActions
{
 #hunters_mark
 Spell(hunters_mark)
 #aimed_shot,if=active_enemies<3
 if Enemies() < 3 Spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatMainPostConditions
{
}

AddFunction MarksmanshipPrecombatShortCdActions
{
 unless Spell(hunters_mark)
 {
  #double_tap,precast_time=10
  Spell(double_tap)
  #worldvein_resonance
  Spell(worldvein_resonance_essence)
 }
}

AddFunction MarksmanshipPrecombatShortCdPostConditions
{
 Spell(hunters_mark) or Enemies() < 3 and Spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)

 unless Spell(hunters_mark) or Spell(double_tap) or Spell(worldvein_resonance_essence)
 {
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)
  #memory_of_lucid_dreams
  Spell(memory_of_lucid_dreams_essence)
  #trueshot,precast_time=1.5,if=active_enemies>2
  if Enemies() > 2 Spell(trueshot)
 }
}

AddFunction MarksmanshipPrecombatCdPostConditions
{
 Spell(hunters_mark) or Spell(double_tap) or Spell(worldvein_resonance_essence) or Enemies() < 3 and Spell(aimed_shot)
}

### actions.cds

AddFunction MarksmanshipCdsMainActions
{
 #hunters_mark,if=debuff.hunters_mark.down&!buff.trueshot.up
 if target.DebuffExpires(hunters_mark_debuff) and not BuffPresent(trueshot_buff) Spell(hunters_mark)
}

AddFunction MarksmanshipCdsMainPostConditions
{
}

AddFunction MarksmanshipCdsShortCdActions
{
 unless target.DebuffExpires(hunters_mark_debuff) and not BuffPresent(trueshot_buff) and Spell(hunters_mark)
 {
  #double_tap,if=cooldown.rapid_fire.remains<gcd|cooldown.rapid_fire.remains<cooldown.aimed_shot.remains|target.time_to_die<20
  if SpellCooldown(rapid_fire) < GCD() or SpellCooldown(rapid_fire) < SpellCooldown(aimed_shot) or target.TimeToDie() < 20 Spell(double_tap)
  #worldvein_resonance,if=buff.lifeblood.stack<4&!buff.trueshot.up
  if BuffStacks(lifeblood_buff) < 4 and not BuffPresent(trueshot_buff) Spell(worldvein_resonance_essence)
  #ripple_in_space,if=cooldown.trueshot.remains<7
  if SpellCooldown(trueshot) < 7 Spell(ripple_in_space_essence)
 }
}

AddFunction MarksmanshipCdsShortCdPostConditions
{
 target.DebuffExpires(hunters_mark_debuff) and not BuffPresent(trueshot_buff) and Spell(hunters_mark)
}

AddFunction MarksmanshipCdsCdActions
{
 unless target.DebuffExpires(hunters_mark_debuff) and not BuffPresent(trueshot_buff) and Spell(hunters_mark) or { SpellCooldown(rapid_fire) < GCD() or SpellCooldown(rapid_fire) < SpellCooldown(aimed_shot) or target.TimeToDie() < 20 } and Spell(double_tap)
 {
  #berserking,if=buff.trueshot.up&(target.time_to_die>cooldown.berserking.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<13
  if BuffPresent(trueshot_buff) and { target.TimeToDie() > SpellCooldownDuration(berserking) + BaseDuration(berserking) or target.HealthPercent() < 20 or not Talent(careful_aim_talent) } or target.TimeToDie() < 13 Spell(berserking)
  #blood_fury,if=buff.trueshot.up&(target.time_to_die>cooldown.blood_fury.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<16
  if BuffPresent(trueshot_buff) and { target.TimeToDie() > SpellCooldownDuration(blood_fury_ap) + BaseDuration(blood_fury_ap) or target.HealthPercent() < 20 or not Talent(careful_aim_talent) } or target.TimeToDie() < 16 Spell(blood_fury_ap)
  #ancestral_call,if=buff.trueshot.up&(target.time_to_die>cooldown.ancestral_call.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<16
  if BuffPresent(trueshot_buff) and { target.TimeToDie() > SpellCooldownDuration(ancestral_call) + BaseDuration(ancestral_call) or target.HealthPercent() < 20 or not Talent(careful_aim_talent) } or target.TimeToDie() < 16 Spell(ancestral_call)
  #fireblood,if=buff.trueshot.up&(target.time_to_die>cooldown.fireblood.duration+duration|(target.health.pct<20|!talent.careful_aim.enabled))|target.time_to_die<9
  if BuffPresent(trueshot_buff) and { target.TimeToDie() > SpellCooldownDuration(fireblood) + BaseDuration(fireblood) or target.HealthPercent() < 20 or not Talent(careful_aim_talent) } or target.TimeToDie() < 9 Spell(fireblood)
  #lights_judgment
  Spell(lights_judgment)

  unless BuffStacks(lifeblood_buff) < 4 and not BuffPresent(trueshot_buff) and Spell(worldvein_resonance_essence)
  {
   #guardian_of_azeroth,if=(ca_execute|target.time_to_die>210)&(buff.trueshot.up|cooldown.trueshot.remains<16)|target.time_to_die<30
   if { Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } or target.TimeToDie() > 210 } and { BuffPresent(trueshot_buff) or SpellCooldown(trueshot) < 16 } or target.TimeToDie() < 30 Spell(guardian_of_azeroth)

   unless SpellCooldown(trueshot) < 7 and Spell(ripple_in_space_essence)
   {
    #memory_of_lucid_dreams,if=!buff.trueshot.up
    if not BuffPresent(trueshot_buff) Spell(memory_of_lucid_dreams_essence)
    #potion,if=buff.trueshot.react&buff.bloodlust.react|buff.trueshot.up&ca_execute|target.time_to_die<25
    if { BuffPresent(trueshot_buff) and BuffPresent(bloodlust) or BuffPresent(trueshot_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
    #trueshot,if=focus>60&(buff.precise_shots.down&cooldown.rapid_fire.remains&target.time_to_die>cooldown.trueshot.duration_guess+duration|target.health.pct<20|!talent.careful_aim.enabled)|target.time_to_die<15
    if Focus() > 60 and { BuffExpires(precise_shots_buff) and SpellCooldown(rapid_fire) > 0 and target.TimeToDie() > 0 + BaseDuration(trueshot) or target.HealthPercent() < 20 or not Talent(careful_aim_talent) } or target.TimeToDie() < 15 Spell(trueshot)
   }
  }
 }
}

AddFunction MarksmanshipCdsCdPostConditions
{
 target.DebuffExpires(hunters_mark_debuff) and not BuffPresent(trueshot_buff) and Spell(hunters_mark) or { SpellCooldown(rapid_fire) < GCD() or SpellCooldown(rapid_fire) < SpellCooldown(aimed_shot) or target.TimeToDie() < 20 } and Spell(double_tap) or BuffStacks(lifeblood_buff) < 4 and not BuffPresent(trueshot_buff) and Spell(worldvein_resonance_essence) or SpellCooldown(trueshot) < 7 and Spell(ripple_in_space_essence)
}

### actions.default

AddFunction MarksmanshipDefaultMainActions
{
 #call_action_list,name=cds
 MarksmanshipCdsMainActions()

 unless MarksmanshipCdsMainPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if Enemies() < 3 MarksmanshipStMainActions()

  unless Enemies() < 3 and MarksmanshipStMainPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if Enemies() > 2 MarksmanshipTrickshotsMainActions()
  }
 }
}

AddFunction MarksmanshipDefaultMainPostConditions
{
 MarksmanshipCdsMainPostConditions() or Enemies() < 3 and MarksmanshipStMainPostConditions() or Enemies() > 2 and MarksmanshipTrickshotsMainPostConditions()
}

AddFunction MarksmanshipDefaultShortCdActions
{
 #call_action_list,name=cds
 MarksmanshipCdsShortCdActions()

 unless MarksmanshipCdsShortCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if Enemies() < 3 MarksmanshipStShortCdActions()

  unless Enemies() < 3 and MarksmanshipStShortCdPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if Enemies() > 2 MarksmanshipTrickshotsShortCdActions()
  }
 }
}

AddFunction MarksmanshipDefaultShortCdPostConditions
{
 MarksmanshipCdsShortCdPostConditions() or Enemies() < 3 and MarksmanshipStShortCdPostConditions() or Enemies() > 2 and MarksmanshipTrickshotsShortCdPostConditions()
}

AddFunction MarksmanshipDefaultCdActions
{
 MarksmanshipInterruptActions()
 #auto_shot
 #use_item,name=galecallers_boon,if=buff.trueshot.up|!talent.calling_the_shots.enabled|target.time_to_die<10
 if BuffPresent(trueshot_buff) or not Talent(calling_the_shots_talent) or target.TimeToDie() < 10 MarksmanshipUseItemActions()
 #use_item,name=pocketsized_computation_device,if=!buff.trueshot.up&!essence.blood_of_the_enemy.major.rank3|debuff.blood_of_the_enemy.up|target.time_to_die<5
 if not BuffPresent(trueshot_buff) and not AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) or target.DebuffPresent(blood_of_the_enemy) or target.TimeToDie() < 5 MarksmanshipUseItemActions()
 #use_items,if=buff.trueshot.up|!talent.calling_the_shots.enabled|target.time_to_die<20
 if BuffPresent(trueshot_buff) or not Talent(calling_the_shots_talent) or target.TimeToDie() < 20 MarksmanshipUseItemActions()
 #call_action_list,name=cds
 MarksmanshipCdsCdActions()

 unless MarksmanshipCdsCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if Enemies() < 3 MarksmanshipStCdActions()

  unless Enemies() < 3 and MarksmanshipStCdPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if Enemies() > 2 MarksmanshipTrickshotsCdActions()
  }
 }
}

AddFunction MarksmanshipDefaultCdPostConditions
{
 MarksmanshipCdsCdPostConditions() or Enemies() < 3 and MarksmanshipStCdPostConditions() or Enemies() > 2 and MarksmanshipTrickshotsCdPostConditions()
}

### Marksmanship icons.

AddCheckBox(opt_hunter_marksmanship_aoe L(AOE) default specialization=marksmanship)

AddIcon checkbox=!opt_hunter_marksmanship_aoe enemies=1 help=shortcd specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatShortCdActions()
 unless not InCombat() and MarksmanshipPrecombatShortCdPostConditions()
 {
  MarksmanshipDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=shortcd specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatShortCdActions()
 unless not InCombat() and MarksmanshipPrecombatShortCdPostConditions()
 {
  MarksmanshipDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatMainActions()
 unless not InCombat() and MarksmanshipPrecombatMainPostConditions()
 {
  MarksmanshipDefaultMainActions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=aoe specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatMainActions()
 unless not InCombat() and MarksmanshipPrecombatMainPostConditions()
 {
  MarksmanshipDefaultMainActions()
 }
}

AddIcon checkbox=!opt_hunter_marksmanship_aoe enemies=1 help=cd specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatCdActions()
 unless not InCombat() and MarksmanshipPrecombatCdPostConditions()
 {
  MarksmanshipDefaultCdActions()
 }
}

AddIcon checkbox=opt_hunter_marksmanship_aoe help=cd specialization=marksmanship
{
 if not InCombat() MarksmanshipPrecombatCdActions()
 unless not InCombat() and MarksmanshipPrecombatCdPostConditions()
 {
  MarksmanshipDefaultCdActions()
 }
}

### Required symbols
# a_murder_of_crows
# aimed_shot
# ancestral_call
# arcane_shot
# barrage
# berserking
# blood_fury_ap
# blood_of_the_enemy
# blood_of_the_enemy_essence_id
# bloodlust
# calling_the_shots_talent
# careful_aim_talent
# concentrated_flame_essence
# counter_shot
# double_tap
# double_tap_buff
# explosive_shot
# fireblood
# focused_azerite_beam
# focused_fire_trait
# guardian_of_azeroth
# hunters_mark
# hunters_mark_debuff
# in_the_rhythm_trait
# item_unbridled_fury
# lifeblood_buff
# lights_judgment
# master_marksman_buff
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# multishot_mm
# piercing_shot
# precise_shots_buff
# purifying_blast
# quaking_palm
# rapid_fire
# reckless_force_buff
# reckless_force_counter
# ripple_in_space_essence
# serpent_sting_mm
# serpent_sting_mm_debuff
# steady_shot
# streamline_talent
# surging_shots_trait
# the_unbound_force
# trick_shots_buff
# trueshot
# trueshot_buff
# unerring_vision_buff
# unerring_vision_trait
# war_stomp
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("HUNTER", "marksmanship", name, desc, code, "script")
    end
    do
        local name = "sc_t23_hunter_survival"
        local desc = "[8.2] Simulationcraft: T23_Hunter_Survival"
        local code = [[
# Based on SimulationCraft profile "T23_Hunter_Survival".
#	class=hunter
#	spec=survival
#	talents=1101021

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)


AddFunction carve_cdr
{
 if Enemies() < 5 Enemies()
 unless Enemies() < 5 5
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=survival)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=survival)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=survival)
AddCheckBox(opt_harpoon SpellName(harpoon) default specialization=survival)

AddFunction SurvivalInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(muzzle) and target.IsInterruptible() Spell(muzzle)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
 }
}

AddFunction SurvivalUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction SurvivalSummonPet
{
 if pet.IsDead()
 {
  Spell(revive_pet)
 }
 if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
}

AddFunction SurvivalGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(raptor_strike)
 {
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.wfi

AddFunction SurvivalWfiMainActions
{
 #harpoon,if=focus+cast_regen<focus.max&talent.terms_of_engagement.enabled
 if Focus() + FocusCastingRegen(harpoon) < MaxFocus() and Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) Spell(harpoon)
 #mongoose_bite,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() Spell(mongoose_bite)
 #raptor_strike,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() Spell(raptor_strike)
 #serpent_sting,if=buff.vipers_venom.up&buff.vipers_venom.remains<1.5*gcd|!dot.serpent_sting.ticking
 if BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < 1.5 * GCD() or not target.DebuffPresent(serpent_sting_sv_debuff) Spell(serpent_sting_sv)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max|(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3)
 if SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 Spell(wildfire_bomb)
 #kill_command,if=focus+cast_regen<focus.max-focus.regen
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - FocusRegenRate() Spell(kill_command_survival)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd
 if SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() Spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.up&dot.serpent_sting.remains<4*gcd
 if BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() Spell(serpent_sting_sv)
 #mongoose_bite,if=dot.shrapnel_bomb.ticking|buff.mongoose_fury.stack=5
 if target.DebuffPresent(shrapnel_bomb_debuff) or BuffStacks(mongoose_fury_buff) == 5 Spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.shrapnel&dot.serpent_sting.remains>5*gcd
 if SpellUsable(270335) and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * GCD() Spell(wildfire_bomb)
 #serpent_sting,if=refreshable
 if target.Refreshable(serpent_sting_sv_debuff) Spell(serpent_sting_sv)
 #chakrams,if=!buff.mongoose_fury.remains
 if not BuffPresent(mongoose_fury_buff) Spell(chakrams)
 #mongoose_bite
 Spell(mongoose_bite)
 #raptor_strike
 Spell(raptor_strike)
 #serpent_sting,if=buff.vipers_venom.up
 if BuffPresent(vipers_venom_buff) Spell(serpent_sting_sv)
 #wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel
 if SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) Spell(wildfire_bomb)
}

AddFunction SurvivalWfiMainPostConditions
{
}

AddFunction SurvivalWfiShortCdActions
{
 unless Focus() + FocusCastingRegen(harpoon) < MaxFocus() and Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(mongoose_bite) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(raptor_strike) or { BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < 1.5 * GCD() or not target.DebuffPresent(serpent_sting_sv_debuff) } and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - FocusRegenRate() and Spell(kill_command_survival)
 {
  #a_murder_of_crows
  Spell(a_murder_of_crows)
  #steel_trap,if=focus+cast_regen<focus.max
  if Focus() + FocusCastingRegen(steel_trap) < MaxFocus() Spell(steel_trap)
 }
}

AddFunction SurvivalWfiShortCdPostConditions
{
 Focus() + FocusCastingRegen(harpoon) < MaxFocus() and Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(mongoose_bite) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(raptor_strike) or { BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < 1.5 * GCD() or not target.DebuffPresent(serpent_sting_sv_debuff) } and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - FocusRegenRate() and Spell(kill_command_survival) or SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() and Spell(wildfire_bomb) or BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() and Spell(serpent_sting_sv) or { target.DebuffPresent(shrapnel_bomb_debuff) or BuffStacks(mongoose_fury_buff) == 5 } and Spell(mongoose_bite) or SpellUsable(270335) and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * GCD() and Spell(wildfire_bomb) or target.Refreshable(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or not BuffPresent(mongoose_fury_buff) and Spell(chakrams) or Spell(mongoose_bite) or Spell(raptor_strike) or BuffPresent(vipers_venom_buff) and Spell(serpent_sting_sv) or { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) } and Spell(wildfire_bomb)
}

AddFunction SurvivalWfiCdActions
{
 unless Focus() + FocusCastingRegen(harpoon) < MaxFocus() and Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(mongoose_bite) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(raptor_strike) or { BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < 1.5 * GCD() or not target.DebuffPresent(serpent_sting_sv_debuff) } and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - FocusRegenRate() and Spell(kill_command_survival) or Spell(a_murder_of_crows) or Focus() + FocusCastingRegen(steel_trap) < MaxFocus() and Spell(steel_trap) or SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() and Spell(wildfire_bomb)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalWfiCdPostConditions
{
 Focus() + FocusCastingRegen(harpoon) < MaxFocus() and Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(mongoose_bite) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(raptor_strike) or { BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < 1.5 * GCD() or not target.DebuffPresent(serpent_sting_sv_debuff) } and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() or SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - FocusRegenRate() and Spell(kill_command_survival) or Spell(a_murder_of_crows) or Focus() + FocusCastingRegen(steel_trap) < MaxFocus() and Spell(steel_trap) or SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() and Spell(wildfire_bomb) or BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() and Spell(serpent_sting_sv) or { target.DebuffPresent(shrapnel_bomb_debuff) or BuffStacks(mongoose_fury_buff) == 5 } and Spell(mongoose_bite) or SpellUsable(270335) and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * GCD() and Spell(wildfire_bomb) or target.Refreshable(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or not BuffPresent(mongoose_fury_buff) and Spell(chakrams) or Spell(mongoose_bite) or Spell(raptor_strike) or BuffPresent(vipers_venom_buff) and Spell(serpent_sting_sv) or { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) } and Spell(wildfire_bomb)
}

### actions.st

AddFunction SurvivalStMainActions
{
 #harpoon,if=talent.terms_of_engagement.enabled
 if Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) Spell(harpoon)
 #raptor_strike,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } Spell(raptor_strike)
 #mongoose_bite,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } Spell(mongoose_bite)
 #kill_command,if=focus+cast_regen<focus.max
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() Spell(kill_command_survival)
 #wildfire_bomb,if=focus+cast_regen<focus.max&!ticking&!buff.memory_of_lucid_dreams.up&(full_recharge_time<1.5*gcd|!dot.wildfire_bomb.ticking&!buff.coordinated_assault.up)
 if Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } Spell(wildfire_bomb)
 #mongoose_bite,if=buff.mongoose_fury.stack>5&!cooldown.coordinated_assault.remains
 if BuffStacks(mongoose_fury_buff) > 5 and not SpellCooldown(coordinated_assault) > 0 Spell(mongoose_bite)
 #serpent_sting,if=buff.vipers_venom.up&dot.serpent_sting.remains<4*gcd|dot.serpent_sting.refreshable&!buff.coordinated_assault.up
 if BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) Spell(serpent_sting_sv)
 #mongoose_bite,if=buff.mongoose_fury.up|focus+cast_regen>focus.max-20&talent.vipers_venom.enabled|focus+cast_regen>focus.max-1&talent.terms_of_engagement.enabled|buff.coordinated_assault.up
 if BuffPresent(mongoose_fury_buff) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 20 and Talent(vipers_venom_talent) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 1 and Talent(terms_of_engagement_talent) or BuffPresent(coordinated_assault_buff) Spell(mongoose_bite)
 #raptor_strike
 Spell(raptor_strike)
 #wildfire_bomb,if=dot.wildfire_bomb.refreshable
 if target.DebuffRefreshable(wildfire_bomb_debuff) Spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.up
 if BuffPresent(vipers_venom_buff) Spell(serpent_sting_sv)
}

AddFunction SurvivalStMainPostConditions
{
}

AddFunction SurvivalStShortCdActions
{
 unless Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon)
 {
  #flanking_strike,if=focus+cast_regen<focus.max
  if Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() Spell(flanking_strike)

  unless BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(raptor_strike) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(mongoose_bite) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and Spell(kill_command_survival)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if Focus() + FocusCastingRegen(steel_trap) < MaxFocus() Spell(steel_trap)

   unless Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(wildfire_bomb) or BuffStacks(mongoose_fury_buff) > 5 and not SpellCooldown(coordinated_assault) > 0 and Spell(mongoose_bite) or { BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(serpent_sting_sv)
   {
    #a_murder_of_crows,if=!buff.coordinated_assault.up
    if not BuffPresent(coordinated_assault_buff) Spell(a_murder_of_crows)
   }
  }
 }
}

AddFunction SurvivalStShortCdPostConditions
{
 Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(raptor_strike) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(mongoose_bite) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and Spell(kill_command_survival) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(wildfire_bomb) or BuffStacks(mongoose_fury_buff) > 5 and not SpellCooldown(coordinated_assault) > 0 and Spell(mongoose_bite) or { BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(serpent_sting_sv) or { BuffPresent(mongoose_fury_buff) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 20 and Talent(vipers_venom_talent) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 1 and Talent(terms_of_engagement_talent) or BuffPresent(coordinated_assault_buff) } and Spell(mongoose_bite) or Spell(raptor_strike) or target.DebuffRefreshable(wildfire_bomb_debuff) and Spell(wildfire_bomb) or BuffPresent(vipers_venom_buff) and Spell(serpent_sting_sv)
}

AddFunction SurvivalStCdActions
{
 unless Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() and Spell(flanking_strike) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(raptor_strike) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(mongoose_bite) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and Spell(kill_command_survival) or Focus() + FocusCastingRegen(steel_trap) < MaxFocus() and Spell(steel_trap) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(wildfire_bomb) or BuffStacks(mongoose_fury_buff) > 5 and not SpellCooldown(coordinated_assault) > 0 and Spell(mongoose_bite) or { BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(serpent_sting_sv) or not BuffPresent(coordinated_assault_buff) and Spell(a_murder_of_crows)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalStCdPostConditions
{
 Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() and Spell(flanking_strike) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(raptor_strike) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(mongoose_bite) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and Spell(kill_command_survival) or Focus() + FocusCastingRegen(steel_trap) < MaxFocus() and Spell(steel_trap) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(wildfire_bomb) or BuffStacks(mongoose_fury_buff) > 5 and not SpellCooldown(coordinated_assault) > 0 and Spell(mongoose_bite) or { BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or target.DebuffRefreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(serpent_sting_sv) or not BuffPresent(coordinated_assault_buff) and Spell(a_murder_of_crows) or { BuffPresent(mongoose_fury_buff) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 20 and Talent(vipers_venom_talent) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 1 and Talent(terms_of_engagement_talent) or BuffPresent(coordinated_assault_buff) } and Spell(mongoose_bite) or Spell(raptor_strike) or target.DebuffRefreshable(wildfire_bomb_debuff) and Spell(wildfire_bomb) or BuffPresent(vipers_venom_buff) and Spell(serpent_sting_sv)
}

### actions.precombat

AddFunction SurvivalPrecombatMainActions
{
 #harpoon
 if CheckBoxOn(opt_harpoon) Spell(harpoon)
}

AddFunction SurvivalPrecombatMainPostConditions
{
}

AddFunction SurvivalPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #summon_pet
 SurvivalSummonPet()
 #steel_trap
 Spell(steel_trap)
}

AddFunction SurvivalPrecombatShortCdPostConditions
{
 CheckBoxOn(opt_harpoon) and Spell(harpoon)
}

AddFunction SurvivalPrecombatCdActions
{
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
}

AddFunction SurvivalPrecombatCdPostConditions
{
 Spell(steel_trap) or CheckBoxOn(opt_harpoon) and Spell(harpoon)
}

### actions.cleave

AddFunction SurvivalCleaveMainActions
{
 #carve,if=dot.shrapnel_bomb.ticking
 if target.DebuffPresent(shrapnel_bomb_debuff) Spell(carve)
 #wildfire_bomb,if=!talent.guerrilla_tactics.enabled|full_recharge_time<gcd
 if not Talent(guerrilla_tactics_talent) or SpellFullRecharge(wildfire_bomb) < GCD() Spell(wildfire_bomb)
 #mongoose_bite,target_if=max:debuff.latent_poison.stack,if=debuff.latent_poison.stack=10
 if target.DebuffStacks(latent_poison) == 10 Spell(mongoose_bite)
 #chakrams
 Spell(chakrams)
 #kill_command,target_if=min:bloodseeker.remains,if=focus+cast_regen<focus.max
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() Spell(kill_command_survival)
 #butchery,if=full_recharge_time<gcd|!talent.wildfire_infusion.enabled|dot.shrapnel_bomb.ticking&dot.internal_bleeding.stack<3
 if SpellFullRecharge(butchery) < GCD() or not Talent(wildfire_infusion_talent) or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 Spell(butchery)
 #carve,if=talent.guerrilla_tactics.enabled
 if Talent(guerrilla_tactics_talent) Spell(carve)
 #wildfire_bomb,if=dot.wildfire_bomb.refreshable|talent.wildfire_infusion.enabled
 if target.DebuffRefreshable(wildfire_bomb_debuff) or Talent(wildfire_infusion_talent) Spell(wildfire_bomb)
 #serpent_sting,target_if=min:remains,if=buff.vipers_venom.react
 if BuffPresent(vipers_venom_buff) Spell(serpent_sting_sv)
 #carve,if=cooldown.wildfire_bomb.remains>variable.carve_cdr%2
 if SpellCooldown(wildfire_bomb) > carve_cdr() / 2 Spell(carve)
 #harpoon,if=talent.terms_of_engagement.enabled
 if Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) Spell(harpoon)
 #serpent_sting,target_if=min:remains,if=refreshable&buff.tip_of_the_spear.stack<3
 if target.Refreshable(serpent_sting_sv_debuff) and BuffStacks(tip_of_the_spear_buff) < 3 Spell(serpent_sting_sv)
 #mongoose_bite,target_if=max:debuff.latent_poison.stack
 Spell(mongoose_bite)
 #raptor_strike,target_if=max:debuff.latent_poison.stack
 Spell(raptor_strike)
}

AddFunction SurvivalCleaveMainPostConditions
{
}

AddFunction SurvivalCleaveShortCdActions
{
 #variable,name=carve_cdr,op=setif,value=active_enemies,value_else=5,condition=active_enemies<5
 #a_murder_of_crows
 Spell(a_murder_of_crows)

 unless target.DebuffPresent(shrapnel_bomb_debuff) and Spell(carve) or { not Talent(guerrilla_tactics_talent) or SpellFullRecharge(wildfire_bomb) < GCD() } and Spell(wildfire_bomb) or target.DebuffStacks(latent_poison) == 10 and Spell(mongoose_bite) or Spell(chakrams) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and Spell(kill_command_survival) or { SpellFullRecharge(butchery) < GCD() or not Talent(wildfire_infusion_talent) or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and Spell(butchery) or Talent(guerrilla_tactics_talent) and Spell(carve)
 {
  #flanking_strike,if=focus+cast_regen<focus.max
  if Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() Spell(flanking_strike)

  unless { target.DebuffRefreshable(wildfire_bomb_debuff) or Talent(wildfire_infusion_talent) } and Spell(wildfire_bomb) or BuffPresent(vipers_venom_buff) and Spell(serpent_sting_sv) or SpellCooldown(wildfire_bomb) > carve_cdr() / 2 and Spell(carve)
  {
   #steel_trap
   Spell(steel_trap)
  }
 }
}

AddFunction SurvivalCleaveShortCdPostConditions
{
 target.DebuffPresent(shrapnel_bomb_debuff) and Spell(carve) or { not Talent(guerrilla_tactics_talent) or SpellFullRecharge(wildfire_bomb) < GCD() } and Spell(wildfire_bomb) or target.DebuffStacks(latent_poison) == 10 and Spell(mongoose_bite) or Spell(chakrams) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and Spell(kill_command_survival) or { SpellFullRecharge(butchery) < GCD() or not Talent(wildfire_infusion_talent) or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and Spell(butchery) or Talent(guerrilla_tactics_talent) and Spell(carve) or { target.DebuffRefreshable(wildfire_bomb_debuff) or Talent(wildfire_infusion_talent) } and Spell(wildfire_bomb) or BuffPresent(vipers_venom_buff) and Spell(serpent_sting_sv) or SpellCooldown(wildfire_bomb) > carve_cdr() / 2 and Spell(carve) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or target.Refreshable(serpent_sting_sv_debuff) and BuffStacks(tip_of_the_spear_buff) < 3 and Spell(serpent_sting_sv) or Spell(mongoose_bite) or Spell(raptor_strike)
}

AddFunction SurvivalCleaveCdActions
{
 unless Spell(a_murder_of_crows)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalCleaveCdPostConditions
{
 Spell(a_murder_of_crows) or target.DebuffPresent(shrapnel_bomb_debuff) and Spell(carve) or { not Talent(guerrilla_tactics_talent) or SpellFullRecharge(wildfire_bomb) < GCD() } and Spell(wildfire_bomb) or target.DebuffStacks(latent_poison) == 10 and Spell(mongoose_bite) or Spell(chakrams) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and Spell(kill_command_survival) or { SpellFullRecharge(butchery) < GCD() or not Talent(wildfire_infusion_talent) or target.DebuffPresent(shrapnel_bomb_debuff) and target.DebuffStacks(internal_bleeding_debuff) < 3 } and Spell(butchery) or Talent(guerrilla_tactics_talent) and Spell(carve) or Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() and Spell(flanking_strike) or { target.DebuffRefreshable(wildfire_bomb_debuff) or Talent(wildfire_infusion_talent) } and Spell(wildfire_bomb) or BuffPresent(vipers_venom_buff) and Spell(serpent_sting_sv) or SpellCooldown(wildfire_bomb) > carve_cdr() / 2 and Spell(carve) or Spell(steel_trap) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or target.Refreshable(serpent_sting_sv_debuff) and BuffStacks(tip_of_the_spear_buff) < 3 and Spell(serpent_sting_sv) or Spell(mongoose_bite) or Spell(raptor_strike)
}

### actions.cds

AddFunction SurvivalCdsMainActions
{
 #concentrated_flame,if=full_recharge_time<1*gcd
 if SpellFullRecharge(concentrated_flame_essence) < 1 * GCD() Spell(concentrated_flame_essence)
}

AddFunction SurvivalCdsMainPostConditions
{
}

AddFunction SurvivalCdsShortCdActions
{
 #aspect_of_the_eagle,if=target.distance>=6
 if target.Distance() >= 6 Spell(aspect_of_the_eagle)
 #focused_azerite_beam
 Spell(focused_azerite_beam)
 #purifying_blast
 Spell(purifying_blast)
 #ripple_in_space
 Spell(ripple_in_space_essence)

 unless SpellFullRecharge(concentrated_flame_essence) < 1 * GCD() and Spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
  #worldvein_resonance
  Spell(worldvein_resonance_essence)
 }
}

AddFunction SurvivalCdsShortCdPostConditions
{
 SpellFullRecharge(concentrated_flame_essence) < 1 * GCD() and Spell(concentrated_flame_essence)
}

AddFunction SurvivalCdsCdActions
{
 #blood_fury,if=cooldown.coordinated_assault.remains>30
 if SpellCooldown(coordinated_assault) > 30 Spell(blood_fury_ap)
 #ancestral_call,if=cooldown.coordinated_assault.remains>30
 if SpellCooldown(coordinated_assault) > 30 Spell(ancestral_call)
 #fireblood,if=cooldown.coordinated_assault.remains>30
 if SpellCooldown(coordinated_assault) > 30 Spell(fireblood)
 #lights_judgment
 Spell(lights_judgment)
 #berserking,if=cooldown.coordinated_assault.remains>60|time_to_die<13
 if SpellCooldown(coordinated_assault) > 60 or target.TimeToDie() < 13 Spell(berserking)
 #potion,if=buff.coordinated_assault.up&(buff.berserking.up|buff.blood_fury.up|!race.troll&!race.orc)|time_to_die<26
 if { BuffPresent(coordinated_assault_buff) and { BuffPresent(berserking_buff) or BuffPresent(blood_fury_ap_buff) or not Race(Troll) and not Race(Orc) } or target.TimeToDie() < 26 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)

 unless target.Distance() >= 6 and Spell(aspect_of_the_eagle)
 {
  #use_item,name=ashvanes_razor_coral,if=buff.memory_of_lucid_dreams.up|buff.guardian_of_azeroth.up|debuff.razor_coral_debuff.down|target.time_to_die<20
  if BuffPresent(memory_of_lucid_dreams_essence_buff) or BuffPresent(guardian_of_azeroth_buff) or target.DebuffExpires(razor_coral) or target.TimeToDie() < 20 SurvivalUseItemActions()

  unless Spell(focused_azerite_beam)
  {
   #memory_of_lucid_dreams,if=focus<focus.max-30&buff.coordinated_assault.up
   if Focus() < MaxFocus() - 30 and BuffPresent(coordinated_assault_buff) Spell(memory_of_lucid_dreams_essence)
   #blood_of_the_enemy,if=buff.coordinated_assault.up
   if BuffPresent(coordinated_assault_buff) Spell(blood_of_the_enemy)

   unless Spell(purifying_blast)
   {
    #guardian_of_azeroth
    Spell(guardian_of_azeroth)
   }
  }
 }
}

AddFunction SurvivalCdsCdPostConditions
{
 target.Distance() >= 6 and Spell(aspect_of_the_eagle) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(ripple_in_space_essence) or SpellFullRecharge(concentrated_flame_essence) < 1 * GCD() and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or Spell(worldvein_resonance_essence)
}

### actions.apwfi

AddFunction SurvivalApwfiMainActions
{
 #mongoose_bite,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() Spell(mongoose_bite)
 #raptor_strike,if=buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd
 if BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() Spell(raptor_strike)
 #serpent_sting,if=!dot.serpent_sting.ticking
 if not target.DebuffPresent(serpent_sting_sv_debuff) Spell(serpent_sting_sv)
 #wildfire_bomb,if=full_recharge_time<1.5*gcd|focus+cast_regen<focus.max&(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3)
 if SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } Spell(wildfire_bomb)
 #mongoose_bite,if=buff.mongoose_fury.remains&next_wi_bomb.pheromone
 if BuffPresent(mongoose_fury_buff) and SpellUsable(270323) Spell(mongoose_bite)
 #kill_command,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max-20
 if SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 20 Spell(kill_command_survival)
 #raptor_strike,if=buff.tip_of_the_spear.stack=3|dot.shrapnel_bomb.ticking
 if BuffStacks(tip_of_the_spear_buff) == 3 or target.DebuffPresent(shrapnel_bomb_debuff) Spell(raptor_strike)
 #mongoose_bite,if=dot.shrapnel_bomb.ticking
 if target.DebuffPresent(shrapnel_bomb_debuff) Spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.shrapnel&focus>30&dot.serpent_sting.remains>5*gcd
 if SpellUsable(270335) and Focus() > 30 and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * GCD() Spell(wildfire_bomb)
 #chakrams,if=!buff.mongoose_fury.remains
 if not BuffPresent(mongoose_fury_buff) Spell(chakrams)
 #serpent_sting,if=refreshable
 if target.Refreshable(serpent_sting_sv_debuff) Spell(serpent_sting_sv)
 #kill_command,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost)
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } Spell(kill_command_survival)
 #raptor_strike
 Spell(raptor_strike)
 #mongoose_bite,if=buff.mongoose_fury.up|focus>40|dot.shrapnel_bomb.ticking
 if BuffPresent(mongoose_fury_buff) or Focus() > 40 or target.DebuffPresent(shrapnel_bomb_debuff) Spell(mongoose_bite)
 #wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel&focus>50
 if SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 Spell(wildfire_bomb)
}

AddFunction SurvivalApwfiMainPostConditions
{
}

AddFunction SurvivalApwfiShortCdActions
{
 unless BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(mongoose_bite) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(raptor_strike) or not target.DebuffPresent(serpent_sting_sv_debuff) and Spell(serpent_sting_sv)
 {
  #a_murder_of_crows
  Spell(a_murder_of_crows)

  unless { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb) or BuffPresent(mongoose_fury_buff) and SpellUsable(270323) and Spell(mongoose_bite) or SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 20 and Spell(kill_command_survival)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if Focus() + FocusCastingRegen(steel_trap) < MaxFocus() Spell(steel_trap)
  }
 }
}

AddFunction SurvivalApwfiShortCdPostConditions
{
 BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(mongoose_bite) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(raptor_strike) or not target.DebuffPresent(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb) or BuffPresent(mongoose_fury_buff) and SpellUsable(270323) and Spell(mongoose_bite) or SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 20 and Spell(kill_command_survival) or { BuffStacks(tip_of_the_spear_buff) == 3 or target.DebuffPresent(shrapnel_bomb_debuff) } and Spell(raptor_strike) or target.DebuffPresent(shrapnel_bomb_debuff) and Spell(mongoose_bite) or SpellUsable(270335) and Focus() > 30 and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * GCD() and Spell(wildfire_bomb) or not BuffPresent(mongoose_fury_buff) and Spell(chakrams) or target.Refreshable(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or Spell(raptor_strike) or { BuffPresent(mongoose_fury_buff) or Focus() > 40 or target.DebuffPresent(shrapnel_bomb_debuff) } and Spell(mongoose_bite) or { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 } and Spell(wildfire_bomb)
}

AddFunction SurvivalApwfiCdActions
{
 unless BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(mongoose_bite) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(raptor_strike) or not target.DebuffPresent(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or Spell(a_murder_of_crows) or { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalApwfiCdPostConditions
{
 BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(mongoose_bite) or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() and Spell(raptor_strike) or not target.DebuffPresent(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or Spell(a_murder_of_crows) or { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb) or BuffPresent(mongoose_fury_buff) and SpellUsable(270323) and Spell(mongoose_bite) or SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 20 and Spell(kill_command_survival) or Focus() + FocusCastingRegen(steel_trap) < MaxFocus() and Spell(steel_trap) or { BuffStacks(tip_of_the_spear_buff) == 3 or target.DebuffPresent(shrapnel_bomb_debuff) } and Spell(raptor_strike) or target.DebuffPresent(shrapnel_bomb_debuff) and Spell(mongoose_bite) or SpellUsable(270335) and Focus() > 30 and target.DebuffRemaining(serpent_sting_sv_debuff) > 5 * GCD() and Spell(wildfire_bomb) or not BuffPresent(mongoose_fury_buff) and Spell(chakrams) or target.Refreshable(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or Spell(raptor_strike) or { BuffPresent(mongoose_fury_buff) or Focus() > 40 or target.DebuffPresent(shrapnel_bomb_debuff) } and Spell(mongoose_bite) or { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 } and Spell(wildfire_bomb)
}

### actions.apst

AddFunction SurvivalApstMainActions
{
 #mongoose_bite,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } Spell(mongoose_bite)
 #raptor_strike,if=buff.coordinated_assault.up&(buff.coordinated_assault.remains<1.5*gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<1.5*gcd)
 if BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } Spell(raptor_strike)
 #kill_command,if=full_recharge_time<1.5*gcd&focus+cast_regen<focus.max-10
 if SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 10 Spell(kill_command_survival)
 #wildfire_bomb,if=focus+cast_regen<focus.max&!ticking&!buff.memory_of_lucid_dreams.up&(full_recharge_time<1.5*gcd|!dot.wildfire_bomb.ticking&!buff.coordinated_assault.up)
 if Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } Spell(wildfire_bomb)
 #serpent_sting,if=!dot.serpent_sting.ticking&!buff.coordinated_assault.up
 if not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) Spell(serpent_sting_sv)
 #kill_command,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost)
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } Spell(kill_command_survival)
 #serpent_sting,if=refreshable&!buff.coordinated_assault.up&buff.mongoose_fury.stack<5
 if target.Refreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and BuffStacks(mongoose_fury_buff) < 5 Spell(serpent_sting_sv)
 #mongoose_bite,if=buff.mongoose_fury.up|focus+cast_regen>focus.max-10|buff.coordinated_assault.up
 if BuffPresent(mongoose_fury_buff) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 10 or BuffPresent(coordinated_assault_buff) Spell(mongoose_bite)
 #raptor_strike
 Spell(raptor_strike)
 #wildfire_bomb,if=!ticking
 if not target.DebuffPresent(wildfire_bomb_debuff) Spell(wildfire_bomb)
}

AddFunction SurvivalApstMainPostConditions
{
}

AddFunction SurvivalApstShortCdActions
{
 unless BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(mongoose_bite) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(raptor_strike)
 {
  #flanking_strike,if=focus+cast_regen<focus.max
  if Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() Spell(flanking_strike)

  unless SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 10 and Spell(kill_command_survival)
  {
   #steel_trap,if=focus+cast_regen<focus.max
   if Focus() + FocusCastingRegen(steel_trap) < MaxFocus() Spell(steel_trap)

   unless Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(wildfire_bomb) or not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or target.Refreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and BuffStacks(mongoose_fury_buff) < 5 and Spell(serpent_sting_sv)
   {
    #a_murder_of_crows,if=!buff.coordinated_assault.up
    if not BuffPresent(coordinated_assault_buff) Spell(a_murder_of_crows)
   }
  }
 }
}

AddFunction SurvivalApstShortCdPostConditions
{
 BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(mongoose_bite) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(raptor_strike) or SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 10 and Spell(kill_command_survival) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(wildfire_bomb) or not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or target.Refreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and BuffStacks(mongoose_fury_buff) < 5 and Spell(serpent_sting_sv) or { BuffPresent(mongoose_fury_buff) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 10 or BuffPresent(coordinated_assault_buff) } and Spell(mongoose_bite) or Spell(raptor_strike) or not target.DebuffPresent(wildfire_bomb_debuff) and Spell(wildfire_bomb)
}

AddFunction SurvivalApstCdActions
{
 unless BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(mongoose_bite) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(raptor_strike) or Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() and Spell(flanking_strike) or SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 10 and Spell(kill_command_survival) or Focus() + FocusCastingRegen(steel_trap) < MaxFocus() and Spell(steel_trap) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(wildfire_bomb) or not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or target.Refreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and BuffStacks(mongoose_fury_buff) < 5 and Spell(serpent_sting_sv) or not BuffPresent(coordinated_assault_buff) and Spell(a_murder_of_crows)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalApstCdPostConditions
{
 BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(mongoose_bite) or BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < 1.5 * GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < 1.5 * GCD() } and Spell(raptor_strike) or Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() and Spell(flanking_strike) or SpellFullRecharge(kill_command_survival) < 1.5 * GCD() and Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() - 10 and Spell(kill_command_survival) or Focus() + FocusCastingRegen(steel_trap) < MaxFocus() and Spell(steel_trap) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and { SpellFullRecharge(wildfire_bomb) < 1.5 * GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(wildfire_bomb) or not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or target.Refreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and BuffStacks(mongoose_fury_buff) < 5 and Spell(serpent_sting_sv) or not BuffPresent(coordinated_assault_buff) and Spell(a_murder_of_crows) or { BuffPresent(mongoose_fury_buff) or Focus() + FocusCastingRegen(mongoose_bite) > MaxFocus() - 10 or BuffPresent(coordinated_assault_buff) } and Spell(mongoose_bite) or Spell(raptor_strike) or not target.DebuffPresent(wildfire_bomb_debuff) and Spell(wildfire_bomb)
}

### actions.default

AddFunction SurvivalDefaultMainActions
{
 #call_action_list,name=cds
 SurvivalCdsMainActions()

 unless SurvivalCdsMainPostConditions()
 {
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) SurvivalApwfiMainActions()

  unless Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) and SurvivalApwfiMainPostConditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if Enemies() < 3 and Talent(chakrams_talent) SurvivalWfiMainActions()

   unless Enemies() < 3 and Talent(chakrams_talent) and SurvivalWfiMainPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) SurvivalStMainActions()

    unless Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalStMainPostConditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) SurvivalApstMainActions()

     unless Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalApstMainPostConditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) SurvivalApwfiMainActions()

      unless Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalApwfiMainPostConditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) SurvivalWfiMainActions()

       unless Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalWfiMainPostConditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1
        if Enemies() > 1 SurvivalCleaveMainActions()

        unless Enemies() > 1 and SurvivalCleaveMainPostConditions()
        {
         #concentrated_flame
         Spell(concentrated_flame_essence)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SurvivalDefaultMainPostConditions
{
 SurvivalCdsMainPostConditions() or Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) and SurvivalApwfiMainPostConditions() or Enemies() < 3 and Talent(chakrams_talent) and SurvivalWfiMainPostConditions() or Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalStMainPostConditions() or Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalApstMainPostConditions() or Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalApwfiMainPostConditions() or Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalWfiMainPostConditions() or Enemies() > 1 and SurvivalCleaveMainPostConditions()
}

AddFunction SurvivalDefaultShortCdActions
{
 #auto_attack
 SurvivalGetInMeleeRange()
 #call_action_list,name=cds
 SurvivalCdsShortCdActions()

 unless SurvivalCdsShortCdPostConditions()
 {
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) SurvivalApwfiShortCdActions()

  unless Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) and SurvivalApwfiShortCdPostConditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if Enemies() < 3 and Talent(chakrams_talent) SurvivalWfiShortCdActions()

   unless Enemies() < 3 and Talent(chakrams_talent) and SurvivalWfiShortCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) SurvivalStShortCdActions()

    unless Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalStShortCdPostConditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) SurvivalApstShortCdActions()

     unless Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalApstShortCdPostConditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) SurvivalApwfiShortCdActions()

      unless Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalApwfiShortCdPostConditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) SurvivalWfiShortCdActions()

       unless Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalWfiShortCdPostConditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1
        if Enemies() > 1 SurvivalCleaveShortCdActions()
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SurvivalDefaultShortCdPostConditions
{
 SurvivalCdsShortCdPostConditions() or Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) and SurvivalApwfiShortCdPostConditions() or Enemies() < 3 and Talent(chakrams_talent) and SurvivalWfiShortCdPostConditions() or Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalStShortCdPostConditions() or Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalApstShortCdPostConditions() or Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalApwfiShortCdPostConditions() or Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalWfiShortCdPostConditions() or Enemies() > 1 and SurvivalCleaveShortCdPostConditions() or Spell(concentrated_flame_essence)
}

AddFunction SurvivalDefaultCdActions
{
 SurvivalInterruptActions()
 #use_items
 SurvivalUseItemActions()
 #call_action_list,name=cds
 SurvivalCdsCdActions()

 unless SurvivalCdsCdPostConditions()
 {
  #call_action_list,name=apwfi,if=active_enemies<3&talent.chakrams.enabled&talent.alpha_predator.enabled
  if Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) SurvivalApwfiCdActions()

  unless Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) and SurvivalApwfiCdPostConditions()
  {
   #call_action_list,name=wfi,if=active_enemies<3&talent.chakrams.enabled
   if Enemies() < 3 and Talent(chakrams_talent) SurvivalWfiCdActions()

   unless Enemies() < 3 and Talent(chakrams_talent) and SurvivalWfiCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<3&!talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
    if Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) SurvivalStCdActions()

    unless Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalStCdPostConditions()
    {
     #call_action_list,name=apst,if=active_enemies<3&talent.alpha_predator.enabled&!talent.wildfire_infusion.enabled
     if Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) SurvivalApstCdActions()

     unless Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalApstCdPostConditions()
     {
      #call_action_list,name=apwfi,if=active_enemies<3&talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
      if Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) SurvivalApwfiCdActions()

      unless Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalApwfiCdPostConditions()
      {
       #call_action_list,name=wfi,if=active_enemies<3&!talent.alpha_predator.enabled&talent.wildfire_infusion.enabled
       if Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) SurvivalWfiCdActions()

       unless Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalWfiCdPostConditions()
       {
        #call_action_list,name=cleave,if=active_enemies>1
        if Enemies() > 1 SurvivalCleaveCdActions()

        unless Enemies() > 1 and SurvivalCleaveCdPostConditions() or Spell(concentrated_flame_essence)
        {
         #arcane_torrent
         Spell(arcane_torrent_focus)
        }
       }
      }
     }
    }
   }
  }
 }
}

AddFunction SurvivalDefaultCdPostConditions
{
 SurvivalCdsCdPostConditions() or Enemies() < 3 and Talent(chakrams_talent) and Talent(alpha_predator_talent) and SurvivalApwfiCdPostConditions() or Enemies() < 3 and Talent(chakrams_talent) and SurvivalWfiCdPostConditions() or Enemies() < 3 and not Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalStCdPostConditions() or Enemies() < 3 and Talent(alpha_predator_talent) and not Talent(wildfire_infusion_talent) and SurvivalApstCdPostConditions() or Enemies() < 3 and Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalApwfiCdPostConditions() or Enemies() < 3 and not Talent(alpha_predator_talent) and Talent(wildfire_infusion_talent) and SurvivalWfiCdPostConditions() or Enemies() > 1 and SurvivalCleaveCdPostConditions() or Spell(concentrated_flame_essence)
}

### Survival icons.

AddCheckBox(opt_hunter_survival_aoe L(AOE) default specialization=survival)

AddIcon checkbox=!opt_hunter_survival_aoe enemies=1 help=shortcd specialization=survival
{
 if not InCombat() SurvivalPrecombatShortCdActions()
 unless not InCombat() and SurvivalPrecombatShortCdPostConditions()
 {
  SurvivalDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=shortcd specialization=survival
{
 if not InCombat() SurvivalPrecombatShortCdActions()
 unless not InCombat() and SurvivalPrecombatShortCdPostConditions()
 {
  SurvivalDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=survival
{
 if not InCombat() SurvivalPrecombatMainActions()
 unless not InCombat() and SurvivalPrecombatMainPostConditions()
 {
  SurvivalDefaultMainActions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=aoe specialization=survival
{
 if not InCombat() SurvivalPrecombatMainActions()
 unless not InCombat() and SurvivalPrecombatMainPostConditions()
 {
  SurvivalDefaultMainActions()
 }
}

AddIcon checkbox=!opt_hunter_survival_aoe enemies=1 help=cd specialization=survival
{
 if not InCombat() SurvivalPrecombatCdActions()
 unless not InCombat() and SurvivalPrecombatCdPostConditions()
 {
  SurvivalDefaultCdActions()
 }
}

AddIcon checkbox=opt_hunter_survival_aoe help=cd specialization=survival
{
 if not InCombat() SurvivalPrecombatCdActions()
 unless not InCombat() and SurvivalPrecombatCdPostConditions()
 {
  SurvivalDefaultCdActions()
 }
}

### Required symbols
# a_murder_of_crows
# alpha_predator_talent
# ancestral_call
# arcane_torrent_focus
# aspect_of_the_eagle
# berserking
# berserking_buff
# blood_fury_ap
# blood_fury_ap_buff
# blood_of_the_enemy
# blur_of_talons_buff
# butchery
# carve
# chakrams
# chakrams_talent
# concentrated_flame_essence
# coordinated_assault
# coordinated_assault_buff
# fireblood
# flanking_strike
# focused_azerite_beam
# guardian_of_azeroth
# guardian_of_azeroth_buff
# guerrilla_tactics_talent
# harpoon
# internal_bleeding_debuff
# item_unbridled_fury
# kill_command_survival
# latent_poison
# lights_judgment
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_buff
# mongoose_bite
# mongoose_fury_buff
# muzzle
# purifying_blast
# quaking_palm
# raptor_strike
# razor_coral
# reckless_force_buff
# revive_pet
# ripple_in_space_essence
# serpent_sting_sv
# serpent_sting_sv_debuff
# shrapnel_bomb_debuff
# steel_trap
# terms_of_engagement_talent
# the_unbound_force
# tip_of_the_spear_buff
# vipers_venom_buff
# vipers_venom_talent
# war_stomp
# wildfire_bomb
# wildfire_bomb_debuff
# wildfire_infusion_talent
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("HUNTER", "survival", name, desc, code, "script")
    end
end
