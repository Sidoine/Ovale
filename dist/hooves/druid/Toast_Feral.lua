local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidFeralToast = function(OvaleScripts)
do
	local name = "toast_feral"
	local desc = "[Toast][8.2] Druid: Feral"
	local code = [[
# Based on SimulationCraft profile "T24_Druid_Feral".
#    class=druid
#    spec=feral
#    talents=2000122
	
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

Define(travel_form 783)
Define(travel_form_buff 783)

# Feral
AddIcon specialization=2 help=main
{
# Pre-combat stuff
if not BuffPresent(travel_form)
{
#mark_of_the_wild,if=!aura.str_agi_int.up
# if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
# CHANGE: Cast Healing Touch to gain Bloodtalons buff if less than 20s remaining on the buff.
#healing_touch,if=talent.bloodtalons.enabled
#if Talent(bloodtalons_talent) Spell(healing_touch)
# if Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 20 and not InCombat() and Speed() == 0 Spell(healing_touch)
if target.Present() and not target.IsDead() and not target.IsFriend()
{
#bloodtalons_talent
#if Talent(bloodtalons_talent) and BuffRemains(bloodtalons_buff) <= CastTime(regrowth) and not InCombat() and { Speed() == 0 or CanMove() > 0 } Spell(regrowth)
#cat_form
#if not BuffPresent(cat_form) Spell(cat_form)
#prowl
if not { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and not InCombat() Spell(prowl)
}
#not bloodtalons_talent
if not { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and not Talent(bloodtalons_talent) and { HealthPercent() < 100 and { not BuffPresent(regrowth_buff) or not InCombat() } or HealthPercent() < 80 } and CastTime(regrowth) <= 0 Spell(regrowth)
}

# Interrupt
#if InCombat() and not mounted() and not BuffPresent(travel_form) InterruptActions()

# Rotation
if target.InRange(rake) and HasFullControl() and target.Present()
{
#cat_form
#if not BuffPresent(cat_form) Spell(cat_form)

# Cooldowns
if BuffPresent(cat_form)
{
if Boss()
{
FeralDefaultCdActions()
}

# Short Cooldowns
FeralDefaultShortCdActions()

# Default Actions
FeralDefaultMainActions()
}
}
#if InCombat() and target.Present() and not target.IsFriend() and not target.InRange(rake) and target.InRange(wild_charge) and { TimeInCombat() < 6 or Falling() } Spell(wild_charge)
#if CheckBoxOn(travers) Travel()
}
AddFunction Boss
{
IsBossFight() or target.Classification(worldboss) or target.Classification(rareelite) or BuffPresent(burst_haste_buff any=1) or { target.IsPvP() and not target.IsFriend() } 
}

AddFunction opener_done
{
 target.DebuffPresent(rip_debuff)
}

AddFunction use_thrash
{
 if HasAzeriteTrait(wild_fleshrending_trait) 2
 0
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=feral)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=feral)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=feral)


AddFunction FeralUseHeartEssence
{
 Spell(concentrated_flame_essence)
}

AddFunction FeralGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
 {
  if target.InRange(wild_charge) Spell(wild_charge)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.default

AddFunction FeralDefaultMainActions
{
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 FeralOpenerMainActions()

 unless opener_done() == 0 and FeralOpenerMainPostConditions()
 {
  #cat_form,if=!buff.cat_form.up
  if not BuffPresent(cat_form_buff) Spell(cat_form)
  #rake,if=buff.prowl.up|buff.shadowmeld.up
  if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
  #call_action_list,name=cooldowns
  FeralCooldownsMainActions()

  unless FeralCooldownsMainPostConditions()
  {
   #ferocious_bite,target_if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&(talent.sabertooth.enabled)
   if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and Talent(sabertooth_talent) Spell(ferocious_bite)
   #regrowth,if=combo_points=5&buff.predatory_swiftness.up&talent.bloodtalons.enabled&buff.bloodtalons.down
   if ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } Spell(regrowth)
   #run_action_list,name=finishers,if=combo_points>4
   if ComboPoints() > 4 FeralFinishersMainActions()

   unless ComboPoints() > 4 and FeralFinishersMainPostConditions()
   {
    #run_action_list,name=generators
    FeralGeneratorsMainActions()
   }
  }
 }
}

AddFunction FeralDefaultMainPostConditions
{
 opener_done() == 0 and FeralOpenerMainPostConditions() or FeralCooldownsMainPostConditions() or ComboPoints() > 4 and FeralFinishersMainPostConditions() or FeralGeneratorsMainPostConditions()
}

AddFunction FeralDefaultShortCdActions
{
 #auto_attack,if=!buff.prowl.up&!buff.shadowmeld.up
 if not BuffPresent(prowl_buff) and not BuffPresent(shadowmeld_buff) FeralGetInMeleeRange()
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 FeralOpenerShortCdActions()

 unless opener_done() == 0 and FeralOpenerShortCdPostConditions() or not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
 {
  #call_action_list,name=cooldowns
  FeralCooldownsShortCdActions()

  unless FeralCooldownsShortCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and Talent(sabertooth_talent) and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth)
  {
   #run_action_list,name=finishers,if=combo_points>4
   if ComboPoints() > 4 FeralFinishersShortCdActions()

   unless ComboPoints() > 4 and FeralFinishersShortCdPostConditions()
   {
    #run_action_list,name=generators
    FeralGeneratorsShortCdActions()
   }
  }
 }
}

AddFunction FeralDefaultShortCdPostConditions
{
 opener_done() == 0 and FeralOpenerShortCdPostConditions() or not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or FeralCooldownsShortCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and Talent(sabertooth_talent) and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or ComboPoints() > 4 and FeralFinishersShortCdPostConditions() or FeralGeneratorsShortCdPostConditions()
}

AddFunction FeralDefaultCdActions
{
 #FeralInterruptActions()
 #run_action_list,name=opener,if=variable.opener_done=0
 if opener_done() == 0 FeralOpenerCdActions()

 unless opener_done() == 0 and FeralOpenerCdPostConditions() or not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake)
 {
  #call_action_list,name=cooldowns
  FeralCooldownsCdActions()

  unless FeralCooldownsCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and Talent(sabertooth_talent) and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth)
  {
   #run_action_list,name=finishers,if=combo_points>4
   if ComboPoints() > 4 FeralFinishersCdActions()

   unless ComboPoints() > 4 and FeralFinishersCdPostConditions()
   {
    #run_action_list,name=generators
    FeralGeneratorsCdActions()
   }
  }
 }
}

AddFunction FeralDefaultCdPostConditions
{
 opener_done() == 0 and FeralOpenerCdPostConditions() or not BuffPresent(cat_form_buff) and Spell(cat_form) or { BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) } and Spell(rake) or FeralCooldownsCdPostConditions() or target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 and Talent(sabertooth_talent) and Spell(ferocious_bite) or ComboPoints() == 5 and BuffPresent(predatory_swiftness_buff) and Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or ComboPoints() > 4 and FeralFinishersCdPostConditions() or FeralGeneratorsCdPostConditions()
}

### actions.cooldowns

AddFunction FeralCooldownsMainActions
{
 #thorns,if=active_enemies>desired_targets|raid_event.adds.in>45
 if enemies(tagged=1) > Enemies(tagged=1) or 600 > 45 Spell(thorns)
 #the_unbound_force,if=buff.reckless_force.up|buff.tigers_fury.up
 if BuffPresent(reckless_force_buff) or BuffPresent(tigers_fury_buff) Spell(the_unbound_force)
 #blood_of_the_enemy,if=buff.tigers_fury.up
 if BuffPresent(tigers_fury_buff) Spell(blood_of_the_enemy)
 #focused_azerite_beam,if=active_enemies>desired_targets|(raid_event.adds.in>90&energy.deficit>=50)
 if enemies(tagged=1) > Enemies(tagged=1) or 600 > 90 and EnergyDeficit() >= 50 Spell(focused_azerite_beam)
 #purifying_blast,if=active_enemies>desired_targets|raid_event.adds.in>60
 if enemies(tagged=1) > Enemies(tagged=1) or 600 > 60 Spell(purifying_blast)
}

AddFunction FeralCooldownsMainPostConditions
{
}

AddFunction FeralCooldownsShortCdActions
{
 #tigers_fury,if=energy.deficit>=60
 if EnergyDeficit() >= 60 Spell(tigers_fury)

 unless { enemies(tagged=1) > Enemies(tagged=1) or 600 > 45 } and Spell(thorns) or { BuffPresent(reckless_force_buff) or BuffPresent(tigers_fury_buff) } and Spell(the_unbound_force) or BuffPresent(tigers_fury_buff) and Spell(blood_of_the_enemy)
 {
  #feral_frenzy,if=combo_points=0
  if ComboPoints() == 0 Spell(feral_frenzy)
 }
}

AddFunction FeralCooldownsShortCdPostConditions
{
 { enemies(tagged=1) > Enemies(tagged=1) or 600 > 45 } and Spell(thorns) or { BuffPresent(reckless_force_buff) or BuffPresent(tigers_fury_buff) } and Spell(the_unbound_force) or BuffPresent(tigers_fury_buff) and Spell(blood_of_the_enemy) or { enemies(tagged=1) > Enemies(tagged=1) or 600 > 90 and EnergyDeficit() >= 50 } and Spell(focused_azerite_beam) or { enemies(tagged=1) > Enemies(tagged=1) or 600 > 60 } and Spell(purifying_blast)
}

AddFunction FeralCooldownsCdActions
{
 #berserk,if=energy>=30&(cooldown.tigers_fury.remains>5|buff.tigers_fury.up)
 if Energy() >= 30 and { SpellCooldown(tigers_fury) > 5 or BuffPresent(tigers_fury_buff) } Spell(berserk)
 #berserking
 Spell(berserking)

 unless { enemies(tagged=1) > Enemies(tagged=1) or 600 > 45 } and Spell(thorns) or { BuffPresent(reckless_force_buff) or BuffPresent(tigers_fury_buff) } and Spell(the_unbound_force)
 {
  #memory_of_lucid_dreams,if=buff.tigers_fury.up&buff.berserk.down
  if BuffPresent(tigers_fury_buff) and BuffExpires(berserk_buff) Spell(memory_of_lucid_dreams_essence)

  unless BuffPresent(tigers_fury_buff) and Spell(blood_of_the_enemy) or ComboPoints() == 0 and Spell(feral_frenzy) or { enemies(tagged=1) > Enemies(tagged=1) or 600 > 90 and EnergyDeficit() >= 50 } and Spell(focused_azerite_beam) or { enemies(tagged=1) > Enemies(tagged=1) or 600 > 60 } and Spell(purifying_blast)
  {
   #heart_essence,if=buff.tigers_fury.up
   if BuffPresent(tigers_fury_buff) FeralUseHeartEssence()
   #incarnation,if=energy>=30&(cooldown.tigers_fury.remains>15|buff.tigers_fury.up)
   if Energy() >= 30 and { SpellCooldown(tigers_fury) > 15 or BuffPresent(tigers_fury_buff) } Spell(incarnation_king_of_the_jungle)
   #potion,if=target.time_to_die<65|(time_to_die<180&(buff.berserk.up|buff.incarnation.up))
   if { target.TimeToDie() < 65 or target.TimeToDie() < 180 and { BuffPresent(berserk_buff) or BuffPresent(incarnation_king_of_the_jungle_buff) } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_focused_resolve usable=1)
   #shadowmeld,if=combo_points<5&energy>=action.rake.cost&dot.rake.pmultiplier<2.1&buff.tigers_fury.up&(buff.bloodtalons.up|!talent.bloodtalons.enabled)&(!talent.incarnation.enabled|cooldown.incarnation.remains>18)&!buff.incarnation.up
   if ComboPoints() < 5 and Energy() >= PowerCost(rake) and target.DebuffPersistentMultiplier(rake_debuff) < 2.1 and BuffPresent(tigers_fury_buff) and { BuffPresent(bloodtalons_buff) or not Talent(bloodtalons_talent) } and { not Talent(incarnation_talent) or SpellCooldown(incarnation_king_of_the_jungle) > 18 } and not BuffPresent(incarnation_king_of_the_jungle_buff) Spell(shadowmeld)
   #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.time_to_pct_30<1.5|!debuff.conductive_ink_debuff.up&(debuff.razor_coral_debuff.stack>=25-10*debuff.blood_of_the_enemy.up|target.time_to_die<40)&buff.tigers_fury.remains>10
   #if target.DebuffExpires(razor_coral_debuff_debuff) or target.DebuffPresent(conductive_ink_debuff_debuff) and target.TimeToHealthPercent(30) < 1.5 or not #target.DebuffPresent(conductive_ink_debuff_debuff) and { target.DebuffStacks(razor_coral_debuff_debuff) >= 25 - 10 * target.DebuffPresent(blood_of_the_enemy_debuff) #or target.TimeToDie() < 40 } and BuffRemaining(tigers_fury_buff) > 10 FeralUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=(energy.deficit>=energy.regen*3)&buff.tigers_fury.down&!azerite.jungle_fury.enabled
   #if EnergyDeficit() >= EnergyRegenRate() * 3 and BuffExpires(tigers_fury_buff) and not HasAzeriteTrait(jungle_fury_trait) FeralUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.tigers_fury.up&azerite.jungle_fury.enabled
   #if BuffPresent(tigers_fury_buff) and HasAzeriteTrait(jungle_fury_trait) FeralUseItemActions()
   #use_item,effect_name=azsharas_font_of_power,if=energy.deficit>=50
   #if EnergyDeficit() >= 50 FeralUseItemActions()
   #use_items,if=buff.tigers_fury.up|target.time_to_die<20
   #if BuffPresent(tigers_fury_buff) or target.TimeToDie() < 20 FeralUseItemActions()
  }
 }
}

AddFunction FeralCooldownsCdPostConditions
{
 { enemies(tagged=1) > Enemies(tagged=1) or 600 > 45 } and Spell(thorns) or { BuffPresent(reckless_force_buff) or BuffPresent(tigers_fury_buff) } and Spell(the_unbound_force) or BuffPresent(tigers_fury_buff) and Spell(blood_of_the_enemy) or ComboPoints() == 0 and Spell(feral_frenzy) or { enemies(tagged=1) > Enemies(tagged=1) or 600 > 90 and EnergyDeficit() >= 50 } and Spell(focused_azerite_beam) or { enemies(tagged=1) > Enemies(tagged=1) or 600 > 60 } and Spell(purifying_blast)
}

### actions.finishers

AddFunction FeralFinishersMainActions
{
 #pool_resource,for_next=1
 #savage_roar,if=buff.savage_roar.down
 if BuffExpires(savage_roar_buff) Spell(savage_roar)
 unless BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
 {
  #pool_resource,for_next=1
  #primal_wrath,target_if=spell_targets.primal_wrath>1&dot.rip.remains<4
  if enemies(tagged=1) > 1 and target.DebuffRemaining(rip_debuff) < 4 Spell(primal_wrath)
  unless enemies(tagged=1) > 1 and target.DebuffRemaining(rip_debuff) < 4 and SpellUsable(primal_wrath) and SpellCooldown(primal_wrath) < TimeToEnergyFor(primal_wrath)
  {
   #pool_resource,for_next=1
   #primal_wrath,target_if=spell_targets.primal_wrath>=2
   if enemies(tagged=1) >= 2 Spell(primal_wrath)
   unless enemies(tagged=1) >= 2 and SpellUsable(primal_wrath) and SpellCooldown(primal_wrath) < TimeToEnergyFor(primal_wrath)
   {
    #pool_resource,for_next=1
    #rip,target_if=!ticking|(remains<=duration*0.3)&(!talent.sabertooth.enabled)|(remains<=duration*0.8&persistent_multiplier>dot.rip.pmultiplier)&target.time_to_die>8
    if not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 Spell(rip)
    unless { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip)
    {
     #pool_resource,for_next=1
     #savage_roar,if=buff.savage_roar.remains<12
     if BuffRemaining(savage_roar_buff) < 12 Spell(savage_roar)
     unless BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar)
     {
      #pool_resource,for_next=1
      #maim,if=buff.iron_jaws.up
      if BuffPresent(iron_jaws) Spell(maim)
      unless BuffPresent(iron_jaws) and SpellUsable(maim) and SpellCooldown(maim) < TimeToEnergyFor(maim)
      {
       #ferocious_bite,max_energy=1,target_if=max:druid.rip.ticks_gained_on_refresh
       if Energy() >= EnergyCost(ferocious_bite max=1) Spell(ferocious_bite)
      }
     }
    }
   }
  }
 }
}

AddFunction FeralFinishersMainPostConditions
{
}

AddFunction FeralFinishersShortCdActions
{
}

AddFunction FeralFinishersShortCdPostConditions
{
 BuffExpires(savage_roar_buff) and Spell(savage_roar) or not { BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { enemies(tagged=1) > 1 and target.DebuffRemaining(rip_debuff) < 4 and Spell(primal_wrath) or not { enemies(tagged=1) > 1 and target.DebuffRemaining(rip_debuff) < 4 and SpellUsable(primal_wrath) and SpellCooldown(primal_wrath) < TimeToEnergyFor(primal_wrath) } and { enemies(tagged=1) >= 2 and Spell(primal_wrath) or not { enemies(tagged=1) >= 2 and SpellUsable(primal_wrath) and SpellCooldown(primal_wrath) < TimeToEnergyFor(primal_wrath) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and Spell(rip) or not { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip) } and { BuffRemaining(savage_roar_buff) < 12 and Spell(savage_roar) or not { BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { BuffPresent(iron_jaws) and Spell(maim) or not { BuffPresent(iron_jaws) and SpellUsable(maim) and SpellCooldown(maim) < TimeToEnergyFor(maim) } and Energy() >= EnergyCost(ferocious_bite max=1) and Spell(ferocious_bite) } } } } }
}

AddFunction FeralFinishersCdActions
{
}

AddFunction FeralFinishersCdPostConditions
{
 BuffExpires(savage_roar_buff) and Spell(savage_roar) or not { BuffExpires(savage_roar_buff) and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { enemies(tagged=1) > 1 and target.DebuffRemaining(rip_debuff) < 4 and Spell(primal_wrath) or not { enemies(tagged=1) > 1 and target.DebuffRemaining(rip_debuff) < 4 and SpellUsable(primal_wrath) and SpellCooldown(primal_wrath) < TimeToEnergyFor(primal_wrath) } and { enemies(tagged=1) >= 2 and Spell(primal_wrath) or not { enemies(tagged=1) >= 2 and SpellUsable(primal_wrath) and SpellCooldown(primal_wrath) < TimeToEnergyFor(primal_wrath) } and { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and Spell(rip) or not { { not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 and not Talent(sabertooth_talent) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 } and SpellUsable(rip) and SpellCooldown(rip) < TimeToEnergyFor(rip) } and { BuffRemaining(savage_roar_buff) < 12 and Spell(savage_roar) or not { BuffRemaining(savage_roar_buff) < 12 and SpellUsable(savage_roar) and SpellCooldown(savage_roar) < TimeToEnergyFor(savage_roar) } and { BuffPresent(iron_jaws) and Spell(maim) or not { BuffPresent(iron_jaws) and SpellUsable(maim) and SpellCooldown(maim) < TimeToEnergyFor(maim) } and Energy() >= EnergyCost(ferocious_bite max=1) and Spell(ferocious_bite) } } } } }
}

### actions.generators

AddFunction FeralGeneratorsMainActions
{
 #regrowth,if=talent.bloodtalons.enabled&buff.predatory_swiftness.up&buff.bloodtalons.down&combo_points=4&dot.rake.remains<4
 if Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } Spell(regrowth)
 #regrowth,if=talent.bloodtalons.enabled&buff.bloodtalons.down&buff.predatory_swiftness.up&talent.lunar_inspiration.enabled&dot.rake.remains<1
 if Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and BuffPresent(predatory_swiftness_buff) and Talent(lunar_inspiration_talent) and target.DebuffRemaining(rake_debuff) < 1 and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } Spell(regrowth)
 #brutal_slash,if=spell_targets.brutal_slash>desired_targets
 if enemies(tagged=1) > Enemies(tagged=1) Spell(brutal_slash)
 #pool_resource,for_next=1
 #thrash_cat,if=(refreshable)&(spell_targets.thrash_cat>2)
 if target.Refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 Spell(thrash_cat)
 unless target.Refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
 {
  #pool_resource,for_next=1
  #thrash_cat,if=(talent.scent_of_blood.enabled&buff.scent_of_blood.down)&spell_targets.thrash_cat>3
  if Talent(scent_of_blood_talent) and BuffExpires(scent_of_blood_feral) and enemies(tagged=1) > 3 Spell(thrash_cat)
  unless Talent(scent_of_blood_talent) and BuffExpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
  {
   #pool_resource,for_next=1
   #swipe_cat,if=buff.scent_of_blood.up|(action.swipe_cat.damage*spell_targets.swipe_cat>(action.rake.damage+(action.rake_bleed.tick_damage*5)))
   if (not Talent(brutal_slash_talent) and (BuffPresent(scent_of_blood_feral) or Damage(swipe_cat) * enemies(tagged=1) > Damage(rake) + target.LastDamage(rake_debuff) * 5)) Spell(swipe_cat)
   unless { BuffPresent(scent_of_blood_feral) or Damage(swipe_cat) * enemies(tagged=1) > Damage(rake) + target.LastDamage(rake_debuff) * 5 } and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat)
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
      #moonfire_cat,if=buff.bloodtalons.up&buff.predatory_swiftness.down&combo_points<5
      if BuffPresent(bloodtalons_buff) and BuffExpires(predatory_swiftness_buff) and ComboPoints() < 5 Spell(moonfire_cat)
      #brutal_slash,if=(buff.tigers_fury.up&(raid_event.adds.in>(1+max_charges-charges_fractional)*recharge_time))
      if BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) Spell(brutal_slash)
      #moonfire_cat,target_if=refreshable
      if target.Refreshable(moonfire_cat_debuff) Spell(moonfire_cat)
      #pool_resource,for_next=1
      #thrash_cat,if=refreshable&((variable.use_thrash=2&(!buff.incarnation.up|azerite.wild_fleshrending.enabled))|spell_targets.thrash_cat>1)
      if target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } Spell(thrash_cat)
      unless target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat)
      {
       #thrash_cat,if=refreshable&variable.use_thrash=1&buff.clearcasting.react&(!buff.incarnation.up|azerite.wild_fleshrending.enabled)
       if target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } Spell(thrash_cat)
       #pool_resource,for_next=1
       #swipe_cat,if=spell_targets.swipe_cat>1
       if (enemies(tagged=1) > 1 and not Talent(brutal_slash_talent)) Spell(swipe_cat)
       if target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) Spell(shred)
      }
     }
    }
   }
  }
 }
}

AddFunction FeralGeneratorsMainPostConditions
{
}

AddFunction FeralGeneratorsShortCdActions
{
}

AddFunction FeralGeneratorsShortCdPostConditions
{
 Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and BuffPresent(predatory_swiftness_buff) and Talent(lunar_inspiration_talent) and target.DebuffRemaining(rake_debuff) < 1 and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or enemies(tagged=1) > Enemies(tagged=1) and Spell(brutal_slash) or target.Refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Talent(scent_of_blood_talent) and BuffExpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and Spell(thrash_cat) or not { Talent(scent_of_blood_talent) and BuffExpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { BuffPresent(scent_of_blood_feral) or Damage(swipe_cat) * enemies(tagged=1) > Damage(rake) + target.LastDamage(rake_debuff) * 5 } and Spell(swipe_cat) or not { { BuffPresent(scent_of_blood_feral) or Damage(swipe_cat) * enemies(tagged=1) > Damage(rake) + target.LastDamage(rake_debuff) * 5 } and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and Spell(rake) or not { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and Spell(rake) or not { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { BuffPresent(bloodtalons_buff) and BuffExpires(predatory_swiftness_buff) and ComboPoints() < 5 and Spell(moonfire_cat) or BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) and Spell(brutal_slash) or target.Refreshable(moonfire_cat_debuff) and Spell(moonfire_cat) or target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } and Spell(thrash_cat) or enemies(tagged=1) > 1 and Spell(swipe_cat) or not { enemies(tagged=1) > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) } and Spell(shred) } } } } } }
}

AddFunction FeralGeneratorsCdActions
{
}

AddFunction FeralGeneratorsCdPostConditions
{
 Talent(bloodtalons_talent) and BuffPresent(predatory_swiftness_buff) and BuffExpires(bloodtalons_buff) and ComboPoints() == 4 and target.DebuffRemaining(rake_debuff) < 4 and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or Talent(bloodtalons_talent) and BuffExpires(bloodtalons_buff) and BuffPresent(predatory_swiftness_buff) and Talent(lunar_inspiration_talent) and target.DebuffRemaining(rake_debuff) < 1 and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or enemies(tagged=1) > Enemies(tagged=1) and Spell(brutal_slash) or target.Refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and enemies(tagged=1) > 2 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { Talent(scent_of_blood_talent) and BuffExpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and Spell(thrash_cat) or not { Talent(scent_of_blood_talent) and BuffExpires(scent_of_blood_feral) and enemies(tagged=1) > 3 and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { { BuffPresent(scent_of_blood_feral) or Damage(swipe_cat) * enemies(tagged=1) > Damage(rake) + target.LastDamage(rake_debuff) * 5 } and Spell(swipe_cat) or not { { BuffPresent(scent_of_blood_feral) or Damage(swipe_cat) * enemies(tagged=1) > Damage(rake) + target.LastDamage(rake_debuff) * 5 } and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and Spell(rake) or not { { not target.DebuffPresent(rake_debuff) or not Talent(bloodtalons_talent) and target.DebuffRemaining(rake_debuff) < BaseDuration(rake_debuff) * 0.3 and target.TimeToDie() > 4 } and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and Spell(rake) or not { Talent(bloodtalons_talent) and BuffPresent(bloodtalons_buff) and target.DebuffRemaining(rake_debuff) <= 7 and PersistentMultiplier(rake_debuff) > target.DebuffPersistentMultiplier(rake_debuff) * 0.85 and target.TimeToDie() > 4 and SpellUsable(rake) and SpellCooldown(rake) < TimeToEnergyFor(rake) } and { BuffPresent(bloodtalons_buff) and BuffExpires(predatory_swiftness_buff) and ComboPoints() < 5 and Spell(moonfire_cat) or BuffPresent(tigers_fury_buff) and 600 > { 1 + SpellMaxCharges(brutal_slash) - Charges(brutal_slash count=0) } * SpellChargeCooldown(brutal_slash) and Spell(brutal_slash) or target.Refreshable(moonfire_cat_debuff) and Spell(moonfire_cat) or target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and Spell(thrash_cat) or not { target.Refreshable(thrash_cat_debuff) and { use_thrash() == 2 and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } or enemies(tagged=1) > 1 } and SpellUsable(thrash_cat) and SpellCooldown(thrash_cat) < TimeToEnergyFor(thrash_cat) } and { target.Refreshable(thrash_cat_debuff) and use_thrash() == 1 and BuffPresent(clearcasting_buff) and { not BuffPresent(incarnation_king_of_the_jungle_buff) or HasAzeriteTrait(wild_fleshrending_trait) } and Spell(thrash_cat) or enemies(tagged=1) > 1 and Spell(swipe_cat) or not { enemies(tagged=1) > 1 and SpellUsable(swipe_cat) and SpellCooldown(swipe_cat) < TimeToEnergyFor(swipe_cat) } and { target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() or BuffPresent(clearcasting_buff) } and Spell(shred) } } } } } }
}

### actions.opener

AddFunction FeralOpenerMainActions
{
 #rake,if=!ticking|buff.prowl.up
 if not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) Spell(rake)
 #variable,name=opener_done,value=dot.rip.ticking
 #wait,sec=0.001,if=dot.rip.ticking
 #moonfire_cat,if=!ticking
 if not target.DebuffPresent(moonfire_cat_debuff) Spell(moonfire_cat)
 #rip,if=!ticking
 if not target.DebuffPresent(rip_debuff) Spell(rip)
}

AddFunction FeralOpenerMainPostConditions
{
}

AddFunction FeralOpenerShortCdActions
{
 #tigers_fury
 Spell(tigers_fury)
}

AddFunction FeralOpenerShortCdPostConditions
{
 { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake) or not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not target.DebuffPresent(rip_debuff) and Spell(rip)
}

AddFunction FeralOpenerCdActions
{
}

AddFunction FeralOpenerCdPostConditions
{
 { not target.DebuffPresent(rake_debuff) or BuffPresent(prowl_buff) } and Spell(rake) or not target.DebuffPresent(moonfire_cat_debuff) and Spell(moonfire_cat) or not target.DebuffPresent(rip_debuff) and Spell(rip)
}

### actions.precombat

AddFunction FeralPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #variable,name=use_thrash,value=0
 #variable,name=use_thrash,value=2,if=azerite.wild_fleshrending.enabled
 #regrowth,if=talent.bloodtalons.enabled
 if Talent(bloodtalons_talent) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } Spell(regrowth)
 #cat_form
 Spell(cat_form)
}

AddFunction FeralPrecombatMainPostConditions
{
}

AddFunction FeralPrecombatShortCdActions
{
 unless Talent(bloodtalons_talent) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or Spell(cat_form)
 {
  #prowl
  Spell(prowl)
 }
}

AddFunction FeralPrecombatShortCdPostConditions
{
 Talent(bloodtalons_talent) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or Spell(cat_form)
}

AddFunction FeralPrecombatCdActions
{
 unless Talent(bloodtalons_talent) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth)
 {
  #use_item,name=azsharas_font_of_power
  #FeralUseItemActions()

  unless Spell(cat_form)
  {
   #potion,dynamic_prepot=1
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_focused_resolve usable=1)
   #berserk
   Spell(berserk)
  }
 }
}

AddFunction FeralPrecombatCdPostConditions
{
 Talent(bloodtalons_talent) and Talent(bloodtalons_talent) and { BuffRemaining(bloodtalons_buff) < CastTime(regrowth) + GCDRemaining() or InCombat() } and Spell(regrowth) or Spell(cat_form)
}
]]
		OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
	end
end