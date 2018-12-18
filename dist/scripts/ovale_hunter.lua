local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_pr_hunter_beast_mastery"
    local desc = "[8.1] Simulationcraft: PR_Hunter_Beast_Mastery"
    local code = [[
# Based on SimulationCraft profile "PR_Hunter_Beast_Mastery".
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
  if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
  Spell(revive_pet)
 }
 if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
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
 #bestial_wrath,precast_time=1.5,if=azerite.primal_instincts.enabled
 if HasAzeriteTrait(primal_instincts_trait) Spell(bestial_wrath)
}

AddFunction BeastmasteryPrecombatShortCdPostConditions
{
}

AddFunction BeastmasteryPrecombatCdActions
{
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #aspect_of_the_wild,precast_time=1.1,if=!azerite.primal_instincts.enabled
 if not HasAzeriteTrait(primal_instincts_trait) Spell(aspect_of_the_wild)
}

AddFunction BeastmasteryPrecombatCdPostConditions
{
 HasAzeriteTrait(primal_instincts_trait) and Spell(bestial_wrath)
}

### actions.default

AddFunction BeastmasteryDefaultMainActions
{
 #barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max|full_recharge_time<gcd.max&cooldown.bestial_wrath.remains
 if pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 Spell(barbed_shot)
 #multishot,if=spell_targets>2&gcd.max-pet.cat.buff.beast_cleave.remains>0.25
 if Enemies() > 2 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 Spell(multishot_bm)
 #chimaera_shot,if=spell_targets>1
 if Enemies() > 1 Spell(chimaera_shot)
 #multishot,if=spell_targets>1&gcd.max-pet.cat.buff.beast_cleave.remains>0.25
 if Enemies() > 1 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 Spell(multishot_bm)
 #kill_command
 if pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() Spell(kill_command)
 #chimaera_shot
 Spell(chimaera_shot)
 #dire_beast
 Spell(dire_beast)
 #barbed_shot,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<6&azerite.primal_instincts.enabled|target.time_to_die<9
 if pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < 6 and HasAzeriteTrait(primal_instincts_trait) or target.TimeToDie() < 9 Spell(barbed_shot)
 #cobra_shot,if=(active_enemies<2|cooldown.kill_command.remains>focus.time_to_max)&(focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost|cooldown.kill_command.remains>1+gcd)&cooldown.kill_command.remains>1
 if { Enemies() < 2 or SpellCooldown(kill_command) > TimeToMaxFocus() } and { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() } and SpellCooldown(kill_command) > 1 Spell(cobra_shot)
}

AddFunction BeastmasteryDefaultMainPostConditions
{
}

AddFunction BeastmasteryDefaultShortCdActions
{
 unless { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 } and Spell(barbed_shot)
 {
  #spitting_cobra
  Spell(spitting_cobra)
  #a_murder_of_crows,if=active_enemies=1
  if Enemies() == 1 Spell(a_murder_of_crows)

  unless Enemies() > 2 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm)
  {
   #bestial_wrath,if=cooldown.aspect_of_the_wild.remains>20|target.time_to_die<15
   if SpellCooldown(aspect_of_the_wild) > 20 or target.TimeToDie() < 15 Spell(bestial_wrath)
   #barrage,if=active_enemies>1
   if Enemies() > 1 Spell(barrage)

   unless Enemies() > 1 and Spell(chimaera_shot) or Enemies() > 1 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(chimaera_shot)
   {
    #a_murder_of_crows
    Spell(a_murder_of_crows)

    unless Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < 6 and HasAzeriteTrait(primal_instincts_trait) or target.TimeToDie() < 9 } and Spell(barbed_shot)
    {
     #barrage
     Spell(barrage)
    }
   }
  }
 }
}

AddFunction BeastmasteryDefaultShortCdPostConditions
{
 { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 } and Spell(barbed_shot) or Enemies() > 2 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or Enemies() > 1 and Spell(chimaera_shot) or Enemies() > 1 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(chimaera_shot) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < 6 and HasAzeriteTrait(primal_instincts_trait) or target.TimeToDie() < 9 } and Spell(barbed_shot) or { Enemies() < 2 or SpellCooldown(kill_command) > TimeToMaxFocus() } and { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot)
}

AddFunction BeastmasteryDefaultCdActions
{
 BeastmasteryInterruptActions()
 #auto_shot
 #use_items
 BeastmasteryUseItemActions()
 #berserking,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(berserking)
 #blood_fury,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(blood_fury_ap)
 #ancestral_call,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(ancestral_call)
 #fireblood,if=cooldown.bestial_wrath.remains>30
 if SpellCooldown(bestial_wrath) > 30 Spell(fireblood)
 #potion,if=buff.bestial_wrath.up&buff.aspect_of_the_wild.up&(target.health.pct<35|!talent.killer_instinct.enabled)|target.time_to_die<25
 if { BuffPresent(bestial_wrath_buff) and BuffPresent(aspect_of_the_wild_buff) and { target.HealthPercent() < 35 or not Talent(killer_instinct_talent) } or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)

 unless { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 } and Spell(barbed_shot)
 {
  #lights_judgment
  Spell(lights_judgment)

  unless Spell(spitting_cobra)
  {
   #aspect_of_the_wild
   Spell(aspect_of_the_wild)

   unless Enemies() == 1 and Spell(a_murder_of_crows)
   {
    #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
    if BuffPresent(aspect_of_the_wild_buff) and BuffPresent(bestial_wrath_buff) or target.TimeToDie() < 15 Spell(stampede)

    unless Enemies() > 2 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or { SpellCooldown(aspect_of_the_wild) > 20 or target.TimeToDie() < 15 } and Spell(bestial_wrath) or Enemies() > 1 and Spell(barrage) or Enemies() > 1 and Spell(chimaera_shot) or Enemies() > 1 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(chimaera_shot) or Spell(a_murder_of_crows) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < 6 and HasAzeriteTrait(primal_instincts_trait) or target.TimeToDie() < 9 } and Spell(barbed_shot) or Spell(barrage) or { Enemies() < 2 or SpellCooldown(kill_command) > TimeToMaxFocus() } and { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot)
    {
     #arcane_torrent
     Spell(arcane_torrent_focus)
    }
   }
  }
 }
}

AddFunction BeastmasteryDefaultCdPostConditions
{
 { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 } and Spell(barbed_shot) or Spell(spitting_cobra) or Enemies() == 1 and Spell(a_murder_of_crows) or Enemies() > 2 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or { SpellCooldown(aspect_of_the_wild) > 20 or target.TimeToDie() < 15 } and Spell(bestial_wrath) or Enemies() > 1 and Spell(barrage) or Enemies() > 1 and Spell(chimaera_shot) or Enemies() > 1 and GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(chimaera_shot) or Spell(a_murder_of_crows) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < 6 and HasAzeriteTrait(primal_instincts_trait) or target.TimeToDie() < 9 } and Spell(barbed_shot) or Spell(barrage) or { Enemies() < 2 or SpellCooldown(kill_command) > TimeToMaxFocus() } and { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot)
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
# arcane_torrent_focus
# aspect_of_the_wild
# aspect_of_the_wild_buff
# barbed_shot
# barrage
# battle_potion_of_agility
# berserking
# bestial_wrath
# bestial_wrath_buff
# blood_fury_ap
# chimaera_shot
# cobra_shot
# counter_shot
# dire_beast
# fireblood
# kill_command
# killer_instinct_talent
# lights_judgment
# multishot_bm
# pet_beast_cleave_buff
# pet_frenzy_buff
# primal_instincts_trait
# quaking_palm
# revive_pet
# spitting_cobra
# stampede
# war_stomp
]]
    OvaleScripts:RegisterScript("HUNTER", "beast_mastery", name, desc, code, "script")
end
do
    local name = "sc_pr_hunter_marksmanship"
    local desc = "[8.1] Simulationcraft: PR_Hunter_Marksmanship"
    local code = [[
# Based on SimulationCraft profile "PR_Hunter_Marksmanship".
#	class=hunter
#	spec=marksmanship
#	talents=2103012

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

AddFunction MarksmanshipSummonPet
{
 if pet.IsDead()
 {
  if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
  Spell(revive_pet)
 }
 if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
}

### actions.trickshots

AddFunction MarksmanshipTrickshotsMainActions
{
 #rapid_fire,if=buff.trick_shots.up&(azerite.focused_fire.enabled|azerite.in_the_rhythm.rank>1|azerite.surging_shots.enabled|talent.streamline.enabled)
 if BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } Spell(rapid_fire)
 #aimed_shot,if=buff.trick_shots.up&(buff.precise_shots.down|cooldown.aimed_shot.full_recharge_time<action.aimed_shot.cast_time)
 if BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) } Spell(aimed_shot)
 #rapid_fire,if=buff.trick_shots.up
 if BuffPresent(trick_shots_buff) Spell(rapid_fire)
 #multishot,if=buff.trick_shots.down|buff.precise_shots.up|focus>70
 if BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) or Focus() > 70 Spell(multishot_mm)
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

 unless BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) or Focus() > 70 } and Spell(multishot_mm)
 {
  #piercing_shot
  Spell(piercing_shot)
  #a_murder_of_crows
  Spell(a_murder_of_crows)
 }
}

AddFunction MarksmanshipTrickshotsShortCdPostConditions
{
 BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) or Focus() > 70 } and Spell(multishot_mm) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or Spell(steady_shot)
}

AddFunction MarksmanshipTrickshotsCdActions
{
}

AddFunction MarksmanshipTrickshotsCdPostConditions
{
 Spell(barrage) or Spell(explosive_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) or Focus() > 70 } and Spell(multishot_mm) or Spell(piercing_shot) or Spell(a_murder_of_crows) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or Spell(steady_shot)
}

### actions.st

AddFunction MarksmanshipStMainActions
{
 #serpent_sting,if=refreshable&!action.serpent_sting.in_flight
 if target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) Spell(serpent_sting_mm)
 #aimed_shot,if=buff.precise_shots.down|cooldown.aimed_shot.full_recharge_time<action.aimed_shot.cast_time
 if BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) Spell(aimed_shot)
 #rapid_fire,if=focus+cast_regen<focus.max|azerite.focused_fire.enabled|azerite.in_the_rhythm.rank>1|azerite.surging_shots.enabled|talent.streamline.enabled|buff.trueshot.up
 if Focus() + FocusCastingRegen(rapid_fire) < MaxFocus() or HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) or BuffPresent(trueshot_buff) Spell(rapid_fire)
 #arcane_shot,if=focus>60|buff.precise_shots.up
 if Focus() > 60 or BuffPresent(precise_shots_buff) Spell(arcane_shot)
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

 unless target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) } and Spell(aimed_shot) or { Focus() + FocusCastingRegen(rapid_fire) < MaxFocus() or HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) or BuffPresent(trueshot_buff) } and Spell(rapid_fire)
 {
  #piercing_shot
  Spell(piercing_shot)
 }
}

AddFunction MarksmanshipStShortCdPostConditions
{
 target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) } and Spell(aimed_shot) or { Focus() + FocusCastingRegen(rapid_fire) < MaxFocus() or HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) or BuffPresent(trueshot_buff) } and Spell(rapid_fire) or { Focus() > 60 or BuffPresent(precise_shots_buff) } and Spell(arcane_shot) or Spell(steady_shot)
}

AddFunction MarksmanshipStCdActions
{
}

AddFunction MarksmanshipStCdPostConditions
{
 Spell(explosive_shot) or Enemies() > 1 and Spell(barrage) or Spell(a_murder_of_crows) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) } and Spell(aimed_shot) or { Focus() + FocusCastingRegen(rapid_fire) < MaxFocus() or HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) or BuffPresent(trueshot_buff) } and Spell(rapid_fire) or Spell(piercing_shot) or { Focus() > 60 or BuffPresent(precise_shots_buff) } and Spell(arcane_shot) or Spell(steady_shot)
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
 #flask
 #augmentation
 #food
 #summon_pet,if=active_enemies<3
 if Enemies() < 3 MarksmanshipSummonPet()

 unless Spell(hunters_mark)
 {
  #double_tap,precast_time=10
  Spell(double_tap)
 }
}

AddFunction MarksmanshipPrecombatShortCdPostConditions
{
 Spell(hunters_mark) or Enemies() < 3 and Spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatCdActions
{
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)

 unless Spell(hunters_mark) or Spell(double_tap)
 {
  #trueshot,precast_time=1.5,if=active_enemies>2
  if Enemies() > 2 Spell(trueshot)
 }
}

AddFunction MarksmanshipPrecombatCdPostConditions
{
 Spell(hunters_mark) or Spell(double_tap) or Enemies() < 3 and Spell(aimed_shot)
}

### actions.cds

AddFunction MarksmanshipCdsMainActions
{
 #hunters_mark,if=debuff.hunters_mark.down
 if target.DebuffExpires(hunters_mark_debuff) Spell(hunters_mark)
}

AddFunction MarksmanshipCdsMainPostConditions
{
}

AddFunction MarksmanshipCdsShortCdActions
{
 unless target.DebuffExpires(hunters_mark_debuff) and Spell(hunters_mark)
 {
  #double_tap,if=target.time_to_die<15|cooldown.aimed_shot.remains<gcd&(buff.trueshot.up&(buff.unerring_vision.stack>7|!azerite.unerring_vision.enabled)|!talent.calling_the_shots.enabled)&(!azerite.surging_shots.enabled&!talent.streamline.enabled&!azerite.focused_fire.enabled)
  if target.TimeToDie() < 15 or SpellCooldown(aimed_shot) < GCD() and { BuffPresent(trueshot_buff) and { BuffStacks(unerring_vision_buff) > 7 or not HasAzeriteTrait(unerring_vision_trait) } or not Talent(calling_the_shots_talent) } and not HasAzeriteTrait(surging_shots_trait) and not Talent(streamline_talent) and not HasAzeriteTrait(focused_fire_trait) Spell(double_tap)
  #double_tap,if=cooldown.rapid_fire.remains<gcd&(buff.trueshot.up&(buff.unerring_vision.stack>7|!azerite.unerring_vision.enabled)|!talent.calling_the_shots.enabled)&(azerite.surging_shots.enabled|talent.streamline.enabled|azerite.focused_fire.enabled)
  if SpellCooldown(rapid_fire) < GCD() and { BuffPresent(trueshot_buff) and { BuffStacks(unerring_vision_buff) > 7 or not HasAzeriteTrait(unerring_vision_trait) } or not Talent(calling_the_shots_talent) } and { HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) or HasAzeriteTrait(focused_fire_trait) } Spell(double_tap)
 }
}

AddFunction MarksmanshipCdsShortCdPostConditions
{
 target.DebuffExpires(hunters_mark_debuff) and Spell(hunters_mark)
}

AddFunction MarksmanshipCdsCdActions
{
 unless target.DebuffExpires(hunters_mark_debuff) and Spell(hunters_mark) or { target.TimeToDie() < 15 or SpellCooldown(aimed_shot) < GCD() and { BuffPresent(trueshot_buff) and { BuffStacks(unerring_vision_buff) > 7 or not HasAzeriteTrait(unerring_vision_trait) } or not Talent(calling_the_shots_talent) } and not HasAzeriteTrait(surging_shots_trait) and not Talent(streamline_talent) and not HasAzeriteTrait(focused_fire_trait) } and Spell(double_tap) or SpellCooldown(rapid_fire) < GCD() and { BuffPresent(trueshot_buff) and { BuffStacks(unerring_vision_buff) > 7 or not HasAzeriteTrait(unerring_vision_trait) } or not Talent(calling_the_shots_talent) } and { HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) or HasAzeriteTrait(focused_fire_trait) } and Spell(double_tap)
 {
  #berserking,if=cooldown.trueshot.remains>60
  if SpellCooldown(trueshot) > 60 Spell(berserking)
  #blood_fury,if=cooldown.trueshot.remains>30
  if SpellCooldown(trueshot) > 30 Spell(blood_fury_ap)
  #ancestral_call,if=cooldown.trueshot.remains>30
  if SpellCooldown(trueshot) > 30 Spell(ancestral_call)
  #fireblood,if=cooldown.trueshot.remains>30
  if SpellCooldown(trueshot) > 30 Spell(fireblood)
  #lights_judgment
  Spell(lights_judgment)
  #potion,if=buff.trueshot.react&buff.bloodlust.react|buff.trueshot.up&target.health.pct<20&talent.careful_aim.enabled|target.time_to_die<25
  if { BuffPresent(trueshot_buff) and BuffPresent(burst_haste_buff any=1) or BuffPresent(trueshot_buff) and target.HealthPercent() < 20 and Talent(careful_aim_talent) or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
  #trueshot,if=cooldown.rapid_fire.remains&target.time_to_die>cooldown.trueshot.duration_guess+duration|(target.health.pct<20|!talent.careful_aim.enabled)|target.time_to_die<15
  if SpellCooldown(rapid_fire) > 0 and target.TimeToDie() > 0 + BaseDuration(trueshot) or target.HealthPercent() < 20 or not Talent(careful_aim_talent) or target.TimeToDie() < 15 Spell(trueshot)
 }
}

AddFunction MarksmanshipCdsCdPostConditions
{
 target.DebuffExpires(hunters_mark_debuff) and Spell(hunters_mark) or { target.TimeToDie() < 15 or SpellCooldown(aimed_shot) < GCD() and { BuffPresent(trueshot_buff) and { BuffStacks(unerring_vision_buff) > 7 or not HasAzeriteTrait(unerring_vision_trait) } or not Talent(calling_the_shots_talent) } and not HasAzeriteTrait(surging_shots_trait) and not Talent(streamline_talent) and not HasAzeriteTrait(focused_fire_trait) } and Spell(double_tap) or SpellCooldown(rapid_fire) < GCD() and { BuffPresent(trueshot_buff) and { BuffStacks(unerring_vision_buff) > 7 or not HasAzeriteTrait(unerring_vision_trait) } or not Talent(calling_the_shots_talent) } and { HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) or HasAzeriteTrait(focused_fire_trait) } and Spell(double_tap)
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
# battle_potion_of_agility
# berserking
# blood_fury_ap
# calling_the_shots_talent
# careful_aim_talent
# counter_shot
# double_tap
# explosive_shot
# fireblood
# focused_fire_trait
# hunters_mark
# hunters_mark_debuff
# in_the_rhythm_trait
# lights_judgment
# multishot_mm
# piercing_shot
# precise_shots_buff
# quaking_palm
# rapid_fire
# revive_pet
# serpent_sting_mm
# serpent_sting_mm_debuff
# steady_shot
# streamline_talent
# surging_shots_trait
# trick_shots_buff
# trueshot
# trueshot_buff
# unerring_vision_buff
# unerring_vision_trait
# war_stomp
]]
    OvaleScripts:RegisterScript("HUNTER", "marksmanship", name, desc, code, "script")
end
do
    local name = "sc_pr_hunter_survival"
    local desc = "[8.1] Simulationcraft: PR_Hunter_Survival"
    local code = [[
# Based on SimulationCraft profile "PR_Hunter_Survival".
#	class=hunter
#	spec=survival
#	talents=3101022

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
  if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
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

### actions.wfi_st

AddFunction SurvivalWfistMainActions
{
 #mongoose_bite,if=azerite.wilderness_survival.enabled&next_wi_bomb.volatile&dot.serpent_sting.remains>2.1*gcd&dot.serpent_sting.remains<3.5*gcd&cooldown.wildfire_bomb.remains>2.5*gcd
 if HasAzeriteTrait(wilderness_survival_trait) and SpellUsable(271045) and target.DebuffRemaining(serpent_sting_sv_debuff) > 2.1 * GCD() and target.DebuffRemaining(serpent_sting_sv_debuff) < 3.5 * GCD() and SpellCooldown(wildfire_bomb) > 2.5 * GCD() Spell(mongoose_bite)
 #wildfire_bomb,if=full_recharge_time<gcd|(focus+cast_regen<focus.max)&(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3)
 if SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } Spell(wildfire_bomb)
 #kill_command,if=focus+cast_regen<focus.max&buff.tip_of_the_spear.stack<3&(!talent.alpha_predator.enabled|buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost)
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and { not Talent(alpha_predator_talent) or BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } Spell(kill_command_survival)
 #raptor_strike,if=dot.internal_bleeding.stack<3&dot.shrapnel_bomb.ticking&!talent.mongoose_bite.enabled
 if target.DebuffStacks(internal_bleeding_debuff) < 3 and target.DebuffPresent(shrapnel_bomb_debuff) and not Talent(mongoose_bite_talent) Spell(raptor_strike)
 #wildfire_bomb,if=next_wi_bomb.shrapnel&buff.mongoose_fury.down&(cooldown.kill_command.remains>gcd|focus>60)&!dot.serpent_sting.refreshable
 if SpellUsable(270335) and BuffExpires(mongoose_fury_buff) and { SpellCooldown(kill_command_survival) > GCD() or Focus() > 60 } and not target.DebuffRefreshable(serpent_sting_sv_debuff) Spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.react|refreshable&(!talent.mongoose_bite.enabled|!talent.vipers_venom.enabled|next_wi_bomb.volatile&!dot.shrapnel_bomb.ticking|azerite.latent_poison.enabled|azerite.venomous_fangs.enabled|buff.mongoose_fury.stack=5)
 if BuffPresent(vipers_venom_buff) or target.Refreshable(serpent_sting_sv_debuff) and { not Talent(mongoose_bite_talent) or not Talent(vipers_venom_talent) or SpellUsable(271045) and not target.DebuffPresent(shrapnel_bomb_debuff) or HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) or BuffStacks(mongoose_fury_buff) == 5 } Spell(serpent_sting_sv)
 #harpoon,if=talent.terms_of_engagement.enabled
 if Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) Spell(harpoon)
 #mongoose_bite,if=buff.mongoose_fury.up|focus>60|dot.shrapnel_bomb.ticking
 if BuffPresent(mongoose_fury_buff) or Focus() > 60 or target.DebuffPresent(shrapnel_bomb_debuff) Spell(mongoose_bite)
 #raptor_strike
 Spell(raptor_strike)
 #serpent_sting,if=refreshable
 if target.Refreshable(serpent_sting_sv_debuff) Spell(serpent_sting_sv)
 #wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel&focus>50
 if SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 Spell(wildfire_bomb)
}

AddFunction SurvivalWfistMainPostConditions
{
}

AddFunction SurvivalWfistShortCdActions
{
 #a_murder_of_crows
 Spell(a_murder_of_crows)

 unless HasAzeriteTrait(wilderness_survival_trait) and SpellUsable(271045) and target.DebuffRemaining(serpent_sting_sv_debuff) > 2.1 * GCD() and target.DebuffRemaining(serpent_sting_sv_debuff) < 3.5 * GCD() and SpellCooldown(wildfire_bomb) > 2.5 * GCD() and Spell(mongoose_bite) or { SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and { not Talent(alpha_predator_talent) or BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or target.DebuffStacks(internal_bleeding_debuff) < 3 and target.DebuffPresent(shrapnel_bomb_debuff) and not Talent(mongoose_bite_talent) and Spell(raptor_strike) or SpellUsable(270335) and BuffExpires(mongoose_fury_buff) and { SpellCooldown(kill_command_survival) > GCD() or Focus() > 60 } and not target.DebuffRefreshable(serpent_sting_sv_debuff) and Spell(wildfire_bomb)
 {
  #steel_trap
  Spell(steel_trap)
  #flanking_strike,if=focus+cast_regen<focus.max
  if Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() Spell(flanking_strike)
 }
}

AddFunction SurvivalWfistShortCdPostConditions
{
 HasAzeriteTrait(wilderness_survival_trait) and SpellUsable(271045) and target.DebuffRemaining(serpent_sting_sv_debuff) > 2.1 * GCD() and target.DebuffRemaining(serpent_sting_sv_debuff) < 3.5 * GCD() and SpellCooldown(wildfire_bomb) > 2.5 * GCD() and Spell(mongoose_bite) or { SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and { not Talent(alpha_predator_talent) or BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or target.DebuffStacks(internal_bleeding_debuff) < 3 and target.DebuffPresent(shrapnel_bomb_debuff) and not Talent(mongoose_bite_talent) and Spell(raptor_strike) or SpellUsable(270335) and BuffExpires(mongoose_fury_buff) and { SpellCooldown(kill_command_survival) > GCD() or Focus() > 60 } and not target.DebuffRefreshable(serpent_sting_sv_debuff) and Spell(wildfire_bomb) or { BuffPresent(vipers_venom_buff) or target.Refreshable(serpent_sting_sv_debuff) and { not Talent(mongoose_bite_talent) or not Talent(vipers_venom_talent) or SpellUsable(271045) and not target.DebuffPresent(shrapnel_bomb_debuff) or HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) or BuffStacks(mongoose_fury_buff) == 5 } } and Spell(serpent_sting_sv) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 or target.DebuffPresent(shrapnel_bomb_debuff) } and Spell(mongoose_bite) or Spell(raptor_strike) or target.Refreshable(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 } and Spell(wildfire_bomb)
}

AddFunction SurvivalWfistCdActions
{
 unless Spell(a_murder_of_crows)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalWfistCdPostConditions
{
 Spell(a_murder_of_crows) or HasAzeriteTrait(wilderness_survival_trait) and SpellUsable(271045) and target.DebuffRemaining(serpent_sting_sv_debuff) > 2.1 * GCD() and target.DebuffRemaining(serpent_sting_sv_debuff) < 3.5 * GCD() and SpellCooldown(wildfire_bomb) > 2.5 * GCD() and Spell(mongoose_bite) or { SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and BuffStacks(tip_of_the_spear_buff) < 3 and { not Talent(alpha_predator_talent) or BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or target.DebuffStacks(internal_bleeding_debuff) < 3 and target.DebuffPresent(shrapnel_bomb_debuff) and not Talent(mongoose_bite_talent) and Spell(raptor_strike) or SpellUsable(270335) and BuffExpires(mongoose_fury_buff) and { SpellCooldown(kill_command_survival) > GCD() or Focus() > 60 } and not target.DebuffRefreshable(serpent_sting_sv_debuff) and Spell(wildfire_bomb) or Spell(steel_trap) or Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() and Spell(flanking_strike) or { BuffPresent(vipers_venom_buff) or target.Refreshable(serpent_sting_sv_debuff) and { not Talent(mongoose_bite_talent) or not Talent(vipers_venom_talent) or SpellUsable(271045) and not target.DebuffPresent(shrapnel_bomb_debuff) or HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) or BuffStacks(mongoose_fury_buff) == 5 } } and Spell(serpent_sting_sv) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 or target.DebuffPresent(shrapnel_bomb_debuff) } and Spell(mongoose_bite) or Spell(raptor_strike) or target.Refreshable(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 } and Spell(wildfire_bomb)
}

### actions.st

AddFunction SurvivalStMainActions
{
 #mongoose_bite,if=talent.birds_of_prey.enabled&buff.coordinated_assault.up&(buff.coordinated_assault.remains<gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd)
 if Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } Spell(mongoose_bite)
 #raptor_strike,if=talent.birds_of_prey.enabled&buff.coordinated_assault.up&(buff.coordinated_assault.remains<gcd|buff.blur_of_talons.up&buff.blur_of_talons.remains<gcd)
 if Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } Spell(raptor_strike)
 #serpent_sting,if=buff.vipers_venom.react&buff.vipers_venom.remains<gcd
 if BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < GCD() Spell(serpent_sting_sv)
 #kill_command,if=focus+cast_regen<focus.max&(!talent.alpha_predator.enabled|full_recharge_time<gcd)
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { not Talent(alpha_predator_talent) or SpellFullRecharge(kill_command_survival) < GCD() } Spell(kill_command_survival)
 #wildfire_bomb,if=focus+cast_regen<focus.max&(full_recharge_time<gcd|!dot.wildfire_bomb.ticking&(buff.mongoose_fury.down|full_recharge_time<4.5*gcd))
 if Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellFullRecharge(wildfire_bomb) < GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and { BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < 4.5 * GCD() } } Spell(wildfire_bomb)
 #serpent_sting,if=buff.vipers_venom.react&dot.serpent_sting.remains<4*gcd|!talent.vipers_venom.enabled&!dot.serpent_sting.ticking&!buff.coordinated_assault.up
 if BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or not Talent(vipers_venom_talent) and not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) Spell(serpent_sting_sv)
 #serpent_sting,if=refreshable&(azerite.latent_poison.rank>2|azerite.latent_poison.enabled&azerite.venomous_fangs.enabled|(azerite.latent_poison.enabled|azerite.venomous_fangs.enabled)&(!azerite.blur_of_talons.enabled|!talent.birds_of_prey.enabled|!buff.coordinated_assault.up))
 if target.Refreshable(serpent_sting_sv_debuff) and { AzeriteTraitRank(latent_poison_trait) > 2 or HasAzeriteTrait(latent_poison_trait) and HasAzeriteTrait(venomous_fangs_trait) or { HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) } and { not HasAzeriteTrait(blur_of_talons_trait) or not Talent(birds_of_prey_talent) or not BuffPresent(coordinated_assault_buff) } } Spell(serpent_sting_sv)
 #harpoon,if=talent.terms_of_engagement.enabled
 if Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) Spell(harpoon)
 #chakrams
 Spell(chakrams)
 #kill_command,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<4|focus<action.mongoose_bite.cost)
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 4 or Focus() < PowerCost(mongoose_bite) } Spell(kill_command_survival)
 #mongoose_bite,if=buff.mongoose_fury.up|focus>60
 if BuffPresent(mongoose_fury_buff) or Focus() > 60 Spell(mongoose_bite)
 #raptor_strike
 Spell(raptor_strike)
 #serpent_sting,if=dot.serpent_sting.refreshable&!buff.coordinated_assault.up
 if target.DebuffRefreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) Spell(serpent_sting_sv)
 #wildfire_bomb,if=dot.wildfire_bomb.refreshable
 if target.DebuffRefreshable(wildfire_bomb_debuff) Spell(wildfire_bomb)
}

AddFunction SurvivalStMainPostConditions
{
}

AddFunction SurvivalStShortCdActions
{
 #a_murder_of_crows
 Spell(a_murder_of_crows)

 unless Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } and Spell(mongoose_bite) or Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } and Spell(raptor_strike) or BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < GCD() and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { not Talent(alpha_predator_talent) or SpellFullRecharge(kill_command_survival) < GCD() } and Spell(kill_command_survival) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellFullRecharge(wildfire_bomb) < GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and { BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < 4.5 * GCD() } } and Spell(wildfire_bomb) or { BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or not Talent(vipers_venom_talent) and not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(serpent_sting_sv) or target.Refreshable(serpent_sting_sv_debuff) and { AzeriteTraitRank(latent_poison_trait) > 2 or HasAzeriteTrait(latent_poison_trait) and HasAzeriteTrait(venomous_fangs_trait) or { HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) } and { not HasAzeriteTrait(blur_of_talons_trait) or not Talent(birds_of_prey_talent) or not BuffPresent(coordinated_assault_buff) } } and Spell(serpent_sting_sv)
 {
  #steel_trap
  Spell(steel_trap)

  unless Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or Spell(chakrams)
  {
   #flanking_strike,if=focus+cast_regen<focus.max
   if Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() Spell(flanking_strike)
  }
 }
}

AddFunction SurvivalStShortCdPostConditions
{
 Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } and Spell(mongoose_bite) or Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } and Spell(raptor_strike) or BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < GCD() and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { not Talent(alpha_predator_talent) or SpellFullRecharge(kill_command_survival) < GCD() } and Spell(kill_command_survival) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellFullRecharge(wildfire_bomb) < GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and { BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < 4.5 * GCD() } } and Spell(wildfire_bomb) or { BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or not Talent(vipers_venom_talent) and not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(serpent_sting_sv) or target.Refreshable(serpent_sting_sv_debuff) and { AzeriteTraitRank(latent_poison_trait) > 2 or HasAzeriteTrait(latent_poison_trait) and HasAzeriteTrait(venomous_fangs_trait) or { HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) } and { not HasAzeriteTrait(blur_of_talons_trait) or not Talent(birds_of_prey_talent) or not BuffPresent(coordinated_assault_buff) } } and Spell(serpent_sting_sv) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or Spell(chakrams) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 4 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 } and Spell(mongoose_bite) or Spell(raptor_strike) or target.DebuffRefreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and Spell(serpent_sting_sv) or target.DebuffRefreshable(wildfire_bomb_debuff) and Spell(wildfire_bomb)
}

AddFunction SurvivalStCdActions
{
 unless Spell(a_murder_of_crows) or Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } and Spell(mongoose_bite) or Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } and Spell(raptor_strike) or BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < GCD() and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { not Talent(alpha_predator_talent) or SpellFullRecharge(kill_command_survival) < GCD() } and Spell(kill_command_survival) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellFullRecharge(wildfire_bomb) < GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and { BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < 4.5 * GCD() } } and Spell(wildfire_bomb) or { BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or not Talent(vipers_venom_talent) and not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(serpent_sting_sv) or target.Refreshable(serpent_sting_sv_debuff) and { AzeriteTraitRank(latent_poison_trait) > 2 or HasAzeriteTrait(latent_poison_trait) and HasAzeriteTrait(venomous_fangs_trait) or { HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) } and { not HasAzeriteTrait(blur_of_talons_trait) or not Talent(birds_of_prey_talent) or not BuffPresent(coordinated_assault_buff) } } and Spell(serpent_sting_sv) or Spell(steel_trap) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalStCdPostConditions
{
 Spell(a_murder_of_crows) or Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } and Spell(mongoose_bite) or Talent(birds_of_prey_talent) and BuffPresent(coordinated_assault_buff) and { BuffRemaining(coordinated_assault_buff) < GCD() or BuffPresent(blur_of_talons_buff) and BuffRemaining(blur_of_talons_buff) < GCD() } and Spell(raptor_strike) or BuffPresent(vipers_venom_buff) and BuffRemaining(vipers_venom_buff) < GCD() and Spell(serpent_sting_sv) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { not Talent(alpha_predator_talent) or SpellFullRecharge(kill_command_survival) < GCD() } and Spell(kill_command_survival) or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellFullRecharge(wildfire_bomb) < GCD() or not target.DebuffPresent(wildfire_bomb_debuff) and { BuffExpires(mongoose_fury_buff) or SpellFullRecharge(wildfire_bomb) < 4.5 * GCD() } } and Spell(wildfire_bomb) or { BuffPresent(vipers_venom_buff) and target.DebuffRemaining(serpent_sting_sv_debuff) < 4 * GCD() or not Talent(vipers_venom_talent) and not target.DebuffPresent(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) } and Spell(serpent_sting_sv) or target.Refreshable(serpent_sting_sv_debuff) and { AzeriteTraitRank(latent_poison_trait) > 2 or HasAzeriteTrait(latent_poison_trait) and HasAzeriteTrait(venomous_fangs_trait) or { HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) } and { not HasAzeriteTrait(blur_of_talons_trait) or not Talent(birds_of_prey_talent) or not BuffPresent(coordinated_assault_buff) } } and Spell(serpent_sting_sv) or Spell(steel_trap) or Talent(terms_of_engagement_talent) and CheckBoxOn(opt_harpoon) and Spell(harpoon) or Spell(chakrams) or Focus() + FocusCastingRegen(flanking_strike) < MaxFocus() and Spell(flanking_strike) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 4 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 } and Spell(mongoose_bite) or Spell(raptor_strike) or target.DebuffRefreshable(serpent_sting_sv_debuff) and not BuffPresent(coordinated_assault_buff) and Spell(serpent_sting_sv) or target.DebuffRefreshable(wildfire_bomb_debuff) and Spell(wildfire_bomb)
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
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction SurvivalPrecombatCdPostConditions
{
 Spell(steel_trap) or CheckBoxOn(opt_harpoon) and Spell(harpoon)
}

### actions.mb_ap_wfi_st

AddFunction SurvivalMbapwfistMainActions
{
 #serpent_sting,if=!dot.serpent_sting.ticking
 if not target.DebuffPresent(serpent_sting_sv_debuff) Spell(serpent_sting_sv)
 #wildfire_bomb,if=full_recharge_time<gcd|(focus+cast_regen<focus.max)&(next_wi_bomb.volatile&dot.serpent_sting.ticking&dot.serpent_sting.refreshable|next_wi_bomb.pheromone&!buff.mongoose_fury.up&focus+cast_regen<focus.max-action.kill_command.cast_regen*3)
 if SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } Spell(wildfire_bomb)
 #mongoose_bite,if=buff.mongoose_fury.remains&next_wi_bomb.pheromone
 if BuffPresent(mongoose_fury_buff) and SpellUsable(270323) Spell(mongoose_bite)
 #kill_command,if=focus+cast_regen<focus.max&(buff.mongoose_fury.stack<5|focus<action.mongoose_bite.cost)
 if Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } Spell(kill_command_survival)
 #wildfire_bomb,if=next_wi_bomb.shrapnel&focus>60&dot.serpent_sting.remains>3*gcd
 if SpellUsable(270335) and Focus() > 60 and target.DebuffRemaining(serpent_sting_sv_debuff) > 3 * GCD() Spell(wildfire_bomb)
 #serpent_sting,if=refreshable&(next_wi_bomb.volatile&!dot.shrapnel_bomb.ticking|azerite.latent_poison.enabled|azerite.venomous_fangs.enabled)
 if target.Refreshable(serpent_sting_sv_debuff) and { SpellUsable(271045) and not target.DebuffPresent(shrapnel_bomb_debuff) or HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) } Spell(serpent_sting_sv)
 #mongoose_bite,if=buff.mongoose_fury.up|focus>60|dot.shrapnel_bomb.ticking
 if BuffPresent(mongoose_fury_buff) or Focus() > 60 or target.DebuffPresent(shrapnel_bomb_debuff) Spell(mongoose_bite)
 #serpent_sting,if=refreshable
 if target.Refreshable(serpent_sting_sv_debuff) Spell(serpent_sting_sv)
 #wildfire_bomb,if=next_wi_bomb.volatile&dot.serpent_sting.ticking|next_wi_bomb.pheromone|next_wi_bomb.shrapnel&focus>50
 if SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 Spell(wildfire_bomb)
}

AddFunction SurvivalMbapwfistMainPostConditions
{
}

AddFunction SurvivalMbapwfistShortCdActions
{
 unless not target.DebuffPresent(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb)
 {
  #a_murder_of_crows
  Spell(a_murder_of_crows)
  #steel_trap
  Spell(steel_trap)
 }
}

AddFunction SurvivalMbapwfistShortCdPostConditions
{
 not target.DebuffPresent(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb) or BuffPresent(mongoose_fury_buff) and SpellUsable(270323) and Spell(mongoose_bite) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or SpellUsable(270335) and Focus() > 60 and target.DebuffRemaining(serpent_sting_sv_debuff) > 3 * GCD() and Spell(wildfire_bomb) or target.Refreshable(serpent_sting_sv_debuff) and { SpellUsable(271045) and not target.DebuffPresent(shrapnel_bomb_debuff) or HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) } and Spell(serpent_sting_sv) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 or target.DebuffPresent(shrapnel_bomb_debuff) } and Spell(mongoose_bite) or target.Refreshable(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 } and Spell(wildfire_bomb)
}

AddFunction SurvivalMbapwfistCdActions
{
 unless not target.DebuffPresent(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb)
 {
  #coordinated_assault
  Spell(coordinated_assault)
 }
}

AddFunction SurvivalMbapwfistCdPostConditions
{
 not target.DebuffPresent(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellFullRecharge(wildfire_bomb) < GCD() or Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() and { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) and target.DebuffRefreshable(serpent_sting_sv_debuff) or SpellUsable(270323) and not BuffPresent(mongoose_fury_buff) and Focus() + FocusCastingRegen(wildfire_bomb) < MaxFocus() - FocusCastingRegen(kill_command_survival) * 3 } } and Spell(wildfire_bomb) or Spell(a_murder_of_crows) or Spell(steel_trap) or BuffPresent(mongoose_fury_buff) and SpellUsable(270323) and Spell(mongoose_bite) or Focus() + FocusCastingRegen(kill_command_survival) < MaxFocus() and { BuffStacks(mongoose_fury_buff) < 5 or Focus() < PowerCost(mongoose_bite) } and Spell(kill_command_survival) or SpellUsable(270335) and Focus() > 60 and target.DebuffRemaining(serpent_sting_sv_debuff) > 3 * GCD() and Spell(wildfire_bomb) or target.Refreshable(serpent_sting_sv_debuff) and { SpellUsable(271045) and not target.DebuffPresent(shrapnel_bomb_debuff) or HasAzeriteTrait(latent_poison_trait) or HasAzeriteTrait(venomous_fangs_trait) } and Spell(serpent_sting_sv) or { BuffPresent(mongoose_fury_buff) or Focus() > 60 or target.DebuffPresent(shrapnel_bomb_debuff) } and Spell(mongoose_bite) or target.Refreshable(serpent_sting_sv_debuff) and Spell(serpent_sting_sv) or { SpellUsable(271045) and target.DebuffPresent(serpent_sting_sv_debuff) or SpellUsable(270323) or SpellUsable(270335) and Focus() > 50 } and Spell(wildfire_bomb)
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
}

AddFunction SurvivalCdsMainPostConditions
{
}

AddFunction SurvivalCdsShortCdActions
{
 #aspect_of_the_eagle,if=target.distance>=6
 if target.Distance() >= 6 Spell(aspect_of_the_eagle)
}

AddFunction SurvivalCdsShortCdPostConditions
{
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
 #berserking,if=cooldown.coordinated_assault.remains>60|time_to_die<11
 if SpellCooldown(coordinated_assault) > 60 or target.TimeToDie() < 11 Spell(berserking)
 #potion,if=buff.coordinated_assault.up&(buff.berserking.up|buff.blood_fury.up|!race.troll&!race.orc)|time_to_die<26
 if { BuffPresent(coordinated_assault_buff) and { BuffPresent(berserking_buff) or BuffPresent(blood_fury_ap_buff) or not Race(Troll) and not Race(Orc) } or target.TimeToDie() < 26 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction SurvivalCdsCdPostConditions
{
 target.Distance() >= 6 and Spell(aspect_of_the_eagle)
}

### actions.default

AddFunction SurvivalDefaultMainActions
{
 #call_action_list,name=cds
 SurvivalCdsMainActions()

 unless SurvivalCdsMainPostConditions()
 {
  #call_action_list,name=mb_ap_wfi_st,if=active_enemies<3&talent.wildfire_infusion.enabled&talent.alpha_predator.enabled&talent.mongoose_bite.enabled
  if Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) SurvivalMbapwfistMainActions()

  unless Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) and SurvivalMbapwfistMainPostConditions()
  {
   #call_action_list,name=wfi_st,if=active_enemies<3&talent.wildfire_infusion.enabled
   if Enemies() < 3 and Talent(wildfire_infusion_talent) SurvivalWfistMainActions()

   unless Enemies() < 3 and Talent(wildfire_infusion_talent) and SurvivalWfistMainPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<2
    if Enemies() < 2 SurvivalStMainActions()

    unless Enemies() < 2 and SurvivalStMainPostConditions()
    {
     #call_action_list,name=cleave,if=active_enemies>1
     if Enemies() > 1 SurvivalCleaveMainActions()
    }
   }
  }
 }
}

AddFunction SurvivalDefaultMainPostConditions
{
 SurvivalCdsMainPostConditions() or Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) and SurvivalMbapwfistMainPostConditions() or Enemies() < 3 and Talent(wildfire_infusion_talent) and SurvivalWfistMainPostConditions() or Enemies() < 2 and SurvivalStMainPostConditions() or Enemies() > 1 and SurvivalCleaveMainPostConditions()
}

AddFunction SurvivalDefaultShortCdActions
{
 #auto_attack
 SurvivalGetInMeleeRange()
 #call_action_list,name=cds
 SurvivalCdsShortCdActions()

 unless SurvivalCdsShortCdPostConditions()
 {
  #call_action_list,name=mb_ap_wfi_st,if=active_enemies<3&talent.wildfire_infusion.enabled&talent.alpha_predator.enabled&talent.mongoose_bite.enabled
  if Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) SurvivalMbapwfistShortCdActions()

  unless Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) and SurvivalMbapwfistShortCdPostConditions()
  {
   #call_action_list,name=wfi_st,if=active_enemies<3&talent.wildfire_infusion.enabled
   if Enemies() < 3 and Talent(wildfire_infusion_talent) SurvivalWfistShortCdActions()

   unless Enemies() < 3 and Talent(wildfire_infusion_talent) and SurvivalWfistShortCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<2
    if Enemies() < 2 SurvivalStShortCdActions()

    unless Enemies() < 2 and SurvivalStShortCdPostConditions()
    {
     #call_action_list,name=cleave,if=active_enemies>1
     if Enemies() > 1 SurvivalCleaveShortCdActions()
    }
   }
  }
 }
}

AddFunction SurvivalDefaultShortCdPostConditions
{
 SurvivalCdsShortCdPostConditions() or Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) and SurvivalMbapwfistShortCdPostConditions() or Enemies() < 3 and Talent(wildfire_infusion_talent) and SurvivalWfistShortCdPostConditions() or Enemies() < 2 and SurvivalStShortCdPostConditions() or Enemies() > 1 and SurvivalCleaveShortCdPostConditions()
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
  #call_action_list,name=mb_ap_wfi_st,if=active_enemies<3&talent.wildfire_infusion.enabled&talent.alpha_predator.enabled&talent.mongoose_bite.enabled
  if Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) SurvivalMbapwfistCdActions()

  unless Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) and SurvivalMbapwfistCdPostConditions()
  {
   #call_action_list,name=wfi_st,if=active_enemies<3&talent.wildfire_infusion.enabled
   if Enemies() < 3 and Talent(wildfire_infusion_talent) SurvivalWfistCdActions()

   unless Enemies() < 3 and Talent(wildfire_infusion_talent) and SurvivalWfistCdPostConditions()
   {
    #call_action_list,name=st,if=active_enemies<2
    if Enemies() < 2 SurvivalStCdActions()

    unless Enemies() < 2 and SurvivalStCdPostConditions()
    {
     #call_action_list,name=cleave,if=active_enemies>1
     if Enemies() > 1 SurvivalCleaveCdActions()

     unless Enemies() > 1 and SurvivalCleaveCdPostConditions()
     {
      #arcane_torrent
      Spell(arcane_torrent_focus)
     }
    }
   }
  }
 }
}

AddFunction SurvivalDefaultCdPostConditions
{
 SurvivalCdsCdPostConditions() or Enemies() < 3 and Talent(wildfire_infusion_talent) and Talent(alpha_predator_talent) and Talent(mongoose_bite_talent) and SurvivalMbapwfistCdPostConditions() or Enemies() < 3 and Talent(wildfire_infusion_talent) and SurvivalWfistCdPostConditions() or Enemies() < 2 and SurvivalStCdPostConditions() or Enemies() > 1 and SurvivalCleaveCdPostConditions()
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
# battle_potion_of_agility
# berserking
# berserking_buff
# birds_of_prey_talent
# blood_fury_ap
# blood_fury_ap_buff
# blur_of_talons_buff
# blur_of_talons_trait
# butchery
# carve
# chakrams
# coordinated_assault
# coordinated_assault_buff
# fireblood
# flanking_strike
# guerrilla_tactics_talent
# harpoon
# internal_bleeding_debuff
# kill_command_survival
# latent_poison
# latent_poison_trait
# lights_judgment
# mongoose_bite
# mongoose_bite_talent
# mongoose_fury_buff
# muzzle
# quaking_palm
# raptor_strike
# revive_pet
# serpent_sting_sv
# serpent_sting_sv_debuff
# shrapnel_bomb_debuff
# steel_trap
# terms_of_engagement_talent
# tip_of_the_spear_buff
# venomous_fangs_trait
# vipers_venom_buff
# vipers_venom_talent
# war_stomp
# wilderness_survival_trait
# wildfire_bomb
# wildfire_bomb_debuff
# wildfire_infusion_talent
]]
    OvaleScripts:RegisterScript("HUNTER", "survival", name, desc, code, "script")
end
