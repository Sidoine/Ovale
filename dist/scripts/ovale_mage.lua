local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "sc_mage_arcane_t19"
    local desc = "[7.0] Simulationcraft: Mage_Arcane_T19"
    local code = [[
# Based on SimulationCraft profile "Mage_Arcane_T19P".
#	class=mage
#	spec=arcane
#	talents=1021012

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)


AddFunction average_burn_length
{
 { 0 * total_burns() - 0 + GetStateDuration() } / total_burns()
}

AddFunction total_burns
{
 if not GetState(burn_phase) > 0 1
}

AddFunction time_until_burn_value
{
 if time_until_burn_value() < time_until_burn_max() time_until_burn_value()
 time_until_burn_max()
}

AddFunction time_until_burn_max
{
 if Talent(rune_of_power_talent) SpellCooldown(rune_of_power)
 if ArmorSetBonus(T20 2) SpellCooldown(presence_of_mind) > 0
 SpellCooldown(evocation) - average_burn_length()
}

AddFunction time_until_burn
{
 if time_until_burn_value() < time_until_burn_max() time_until_burn_value()
 time_until_burn_max()
}

AddFunction arcane_missiles_procs
{
 BuffPresent(arcane_missiles_buff)
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=arcane)
AddCheckBox(opt_arcane_mage_burn_phase L(arcane_mage_burn_phase) default specialization=arcane)
AddCheckBox(opt_time_warp SpellName(time_warp) specialization=arcane)

AddFunction ArcaneInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_mana)
  if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
 }
}

AddFunction ArcaneUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.variables

AddFunction ArcaneVariablesMainActions
{
}

AddFunction ArcaneVariablesMainPostConditions
{
}

AddFunction ArcaneVariablesShortCdActions
{
}

AddFunction ArcaneVariablesShortCdPostConditions
{
}

AddFunction ArcaneVariablesCdActions
{
}

AddFunction ArcaneVariablesCdPostConditions
{
}

### actions.precombat

AddFunction ArcanePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #summon_arcane_familiar
 Spell(summon_arcane_familiar)
 #arcane_blast,if=!(set_bonus.tier20_2pc|talent.charged_up.enabled)
 if not { ArmorSetBonus(T20 2) or Talent(charged_up_talent) } Spell(arcane_blast)
}

AddFunction ArcanePrecombatMainPostConditions
{
}

AddFunction ArcanePrecombatShortCdActions
{
 unless Spell(summon_arcane_familiar)
 {
  #mark_of_aluneth,if=set_bonus.tier20_2pc|talent.charged_up.enabled
  if ArmorSetBonus(T20 2) or Talent(charged_up_talent) Spell(mark_of_aluneth)
 }
}

AddFunction ArcanePrecombatShortCdPostConditions
{
 Spell(summon_arcane_familiar) or not { ArmorSetBonus(T20 2) or Talent(charged_up_talent) } and Spell(arcane_blast)
}

AddFunction ArcanePrecombatCdActions
{
 unless Spell(summon_arcane_familiar)
 {
  #snapshot_stats
  #mirror_image
  Spell(mirror_image)
  #potion
  Item(deadly_grace_potion)
 }
}

AddFunction ArcanePrecombatCdPostConditions
{
 Spell(summon_arcane_familiar) or { ArmorSetBonus(T20 2) or Talent(charged_up_talent) } and Spell(mark_of_aluneth) or not { ArmorSetBonus(T20 2) or Talent(charged_up_talent) } and Spell(arcane_blast)
}

### actions.miniburn_init

AddFunction ArcaneMiniburninitMainActions
{
 #arcane_barrage
 Spell(arcane_barrage)
 #swap_action_list,name=default
 ArcaneDefaultMainActions()
}

AddFunction ArcaneMiniburninitMainPostConditions
{
 ArcaneDefaultMainPostConditions()
}

AddFunction ArcaneMiniburninitShortCdActions
{
 #rune_of_power
 Spell(rune_of_power)

 unless Spell(arcane_barrage)
 {
  #presence_of_mind
  Spell(presence_of_mind)
  #swap_action_list,name=default
  ArcaneDefaultShortCdActions()
 }
}

AddFunction ArcaneMiniburninitShortCdPostConditions
{
 Spell(arcane_barrage) or ArcaneDefaultShortCdPostConditions()
}

AddFunction ArcaneMiniburninitCdActions
{
 unless Spell(rune_of_power) or Spell(arcane_barrage) or Spell(presence_of_mind)
 {
  #swap_action_list,name=default
  ArcaneDefaultCdActions()
 }
}

AddFunction ArcaneMiniburninitCdPostConditions
{
 Spell(rune_of_power) or Spell(arcane_barrage) or Spell(presence_of_mind) or ArcaneDefaultCdPostConditions()
}

### actions.conserve

AddFunction ArcaneConserveMainActions
{
 #swap_action_list,name=miniburn_init,if=set_bonus.tier20_4pc&cooldown.presence_of_mind.up&cooldown.arcane_power.remains>20&(action.rune_of_power.usable|!talent.rune_of_power.enabled)
 if ArmorSetBonus(T20 4) and not SpellCooldown(presence_of_mind) > 0 and SpellCooldown(arcane_power) > 20 and { CanCast(rune_of_power) or not Talent(rune_of_power_talent) } ArcaneMiniburninitMainActions()

 unless ArmorSetBonus(T20 4) and not SpellCooldown(presence_of_mind) > 0 and SpellCooldown(arcane_power) > 20 and { CanCast(rune_of_power) or not Talent(rune_of_power_talent) } and ArcaneMiniburninitMainPostConditions()
 {
  #arcane_missiles,if=variable.arcane_missiles_procs=buff.arcane_missiles.max_stack&active_enemies<3
  if arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 Spell(arcane_missiles)
  #supernova
  Spell(supernova)
  #nether_tempest,if=refreshable|!ticking
  if target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) Spell(nether_tempest)
  #arcane_explosion,if=active_enemies>1&(mana.pct>=70-(10*equipped.mystic_kilt_of_the_rune_master))
  if Enemies() > 1 and ManaPercent() >= 70 - 10 * HasEquippedItem(mystic_kilt_of_the_rune_master) Spell(arcane_explosion)
  #arcane_blast,if=mana.pct>=90|buff.rhonins_assaulting_armwraps.up|(buff.rune_of_power.remains>=cast_time&equipped.mystic_kilt_of_the_rune_master)
  if ManaPercent() >= 90 or BuffPresent(rhonins_assaulting_armwraps_buff) or TotemRemaining(rune_of_power) >= CastTime(arcane_blast) and HasEquippedItem(mystic_kilt_of_the_rune_master) Spell(arcane_blast)
  #arcane_missiles,if=variable.arcane_missiles_procs
  if arcane_missiles_procs() Spell(arcane_missiles)
  #arcane_barrage
  Spell(arcane_barrage)
  #arcane_explosion,if=active_enemies>1
  if Enemies() > 1 Spell(arcane_explosion)
  #arcane_blast
  Spell(arcane_blast)
 }
}

AddFunction ArcaneConserveMainPostConditions
{
 ArmorSetBonus(T20 4) and not SpellCooldown(presence_of_mind) > 0 and SpellCooldown(arcane_power) > 20 and { CanCast(rune_of_power) or not Talent(rune_of_power_talent) } and ArcaneMiniburninitMainPostConditions()
}

AddFunction ArcaneConserveShortCdActions
{
 #mark_of_aluneth
 Spell(mark_of_aluneth)
 #rune_of_power,if=full_recharge_time<=execute_time|(prev_gcd.1.mark_of_aluneth&!set_bonus.tier20_4pc)
 if SpellFullRecharge(rune_of_power) <= ExecuteTime(rune_of_power) or PreviousGCDSpell(mark_of_aluneth) and not ArmorSetBonus(T20 4) Spell(rune_of_power)
 #swap_action_list,name=miniburn_init,if=set_bonus.tier20_4pc&cooldown.presence_of_mind.up&cooldown.arcane_power.remains>20&(action.rune_of_power.usable|!talent.rune_of_power.enabled)
 if ArmorSetBonus(T20 4) and not SpellCooldown(presence_of_mind) > 0 and SpellCooldown(arcane_power) > 20 and { CanCast(rune_of_power) or not Talent(rune_of_power_talent) } ArcaneMiniburninitShortCdActions()
}

AddFunction ArcaneConserveShortCdPostConditions
{
 ArmorSetBonus(T20 4) and not SpellCooldown(presence_of_mind) > 0 and SpellCooldown(arcane_power) > 20 and { CanCast(rune_of_power) or not Talent(rune_of_power_talent) } and ArcaneMiniburninitShortCdPostConditions() or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 and Spell(arcane_missiles) or Spell(supernova) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and Spell(nether_tempest) or Enemies() > 1 and ManaPercent() >= 70 - 10 * HasEquippedItem(mystic_kilt_of_the_rune_master) and Spell(arcane_explosion) or { ManaPercent() >= 90 or BuffPresent(rhonins_assaulting_armwraps_buff) or TotemRemaining(rune_of_power) >= CastTime(arcane_blast) and HasEquippedItem(mystic_kilt_of_the_rune_master) } and Spell(arcane_blast) or arcane_missiles_procs() and Spell(arcane_missiles) or Spell(arcane_barrage) or Enemies() > 1 and Spell(arcane_explosion) or Spell(arcane_blast)
}

AddFunction ArcaneConserveCdActions
{
 #mirror_image,if=variable.time_until_burn>recharge_time|variable.time_until_burn>target.time_to_die
 if time_until_burn() > SpellChargeCooldown(mirror_image) or time_until_burn() > target.TimeToDie() Spell(mirror_image)

 unless Spell(mark_of_aluneth) or { SpellFullRecharge(rune_of_power) <= ExecuteTime(rune_of_power) or PreviousGCDSpell(mark_of_aluneth) and not ArmorSetBonus(T20 4) } and Spell(rune_of_power)
 {
  #swap_action_list,name=miniburn_init,if=set_bonus.tier20_4pc&cooldown.presence_of_mind.up&cooldown.arcane_power.remains>20&(action.rune_of_power.usable|!talent.rune_of_power.enabled)
  if ArmorSetBonus(T20 4) and not SpellCooldown(presence_of_mind) > 0 and SpellCooldown(arcane_power) > 20 and { CanCast(rune_of_power) or not Talent(rune_of_power_talent) } ArcaneMiniburninitCdActions()
 }
}

AddFunction ArcaneConserveCdPostConditions
{
 Spell(mark_of_aluneth) or { SpellFullRecharge(rune_of_power) <= ExecuteTime(rune_of_power) or PreviousGCDSpell(mark_of_aluneth) and not ArmorSetBonus(T20 4) } and Spell(rune_of_power) or ArmorSetBonus(T20 4) and not SpellCooldown(presence_of_mind) > 0 and SpellCooldown(arcane_power) > 20 and { CanCast(rune_of_power) or not Talent(rune_of_power_talent) } and ArcaneMiniburninitCdPostConditions() or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 and Spell(arcane_missiles) or Spell(supernova) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and Spell(nether_tempest) or Enemies() > 1 and ManaPercent() >= 70 - 10 * HasEquippedItem(mystic_kilt_of_the_rune_master) and Spell(arcane_explosion) or { ManaPercent() >= 90 or BuffPresent(rhonins_assaulting_armwraps_buff) or TotemRemaining(rune_of_power) >= CastTime(arcane_blast) and HasEquippedItem(mystic_kilt_of_the_rune_master) } and Spell(arcane_blast) or arcane_missiles_procs() and Spell(arcane_missiles) or Spell(arcane_barrage) or Enemies() > 1 and Spell(arcane_explosion) or Spell(arcane_blast)
}

### actions.burn

AddFunction ArcaneBurnMainActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not GetState(burn_phase) > 0 and not GetState(burn_phase) > 0 SetState(burn_phase 1)
 #stop_burn_phase,if=prev_gcd.1.evocation&cooldown.evocation.charges=0&burn_phase_duration>0
 if PreviousGCDSpell(evocation) and SpellCharges(evocation) == 0 and GetStateDuration() > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)
 #nether_tempest,if=refreshable|!ticking
 if target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) Spell(nether_tempest)
 #arcane_barrage,if=active_enemies>4&equipped.mantle_of_the_first_kirin_tor&buff.arcane_charge.stack=buff.arcane_charge.max_stack
 if Enemies() > 4 and HasEquippedItem(mantle_of_the_first_kirin_tor) and DebuffStacks(arcane_charge_debuff) == SpellData(arcane_charge_debuff max_stacks) Spell(arcane_barrage)
 #arcane_missiles,if=variable.arcane_missiles_procs=buff.arcane_missiles.max_stack&active_enemies<3
 if arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 Spell(arcane_missiles)
 #arcane_blast,if=buff.presence_of_mind.up
 if BuffPresent(presence_of_mind_buff) Spell(arcane_blast)
 #arcane_explosion,if=active_enemies>1
 if Enemies() > 1 Spell(arcane_explosion)
 #arcane_missiles,if=variable.arcane_missiles_procs
 if arcane_missiles_procs() Spell(arcane_missiles)
 #arcane_blast
 Spell(arcane_blast)
}

AddFunction ArcaneBurnMainPostConditions
{
}

AddFunction ArcaneBurnShortCdActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not GetState(burn_phase) > 0 and not GetState(burn_phase) > 0 SetState(burn_phase 1)
 #stop_burn_phase,if=prev_gcd.1.evocation&cooldown.evocation.charges=0&burn_phase_duration>0
 if PreviousGCDSpell(evocation) and SpellCharges(evocation) == 0 and GetStateDuration() > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)

 unless { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and Spell(nether_tempest)
 {
  #mark_of_aluneth
  Spell(mark_of_aluneth)
  #rune_of_power,if=mana.pct>30|(buff.arcane_power.up|cooldown.arcane_power.up)
  if ManaPercent() > 30 or BuffPresent(arcane_power_buff) or not SpellCooldown(arcane_power) > 0 Spell(rune_of_power)
  #presence_of_mind,if=((mana.pct>30|buff.arcane_power.up)&set_bonus.tier20_2pc)|buff.rune_of_power.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time|buff.arcane_power.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time
  if { ManaPercent() > 30 or BuffPresent(arcane_power_buff) } and ArmorSetBonus(T20 2) or TotemRemaining(rune_of_power) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) or BuffRemaining(arcane_power_buff) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) Spell(presence_of_mind)
  #arcane_orb
  Spell(arcane_orb)
 }
}

AddFunction ArcaneBurnShortCdPostConditions
{
 { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and Spell(nether_tempest) or Enemies() > 4 and HasEquippedItem(mantle_of_the_first_kirin_tor) and DebuffStacks(arcane_charge_debuff) == SpellData(arcane_charge_debuff max_stacks) and Spell(arcane_barrage) or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 and Spell(arcane_missiles) or BuffPresent(presence_of_mind_buff) and Spell(arcane_blast) or Enemies() > 1 and Spell(arcane_explosion) or arcane_missiles_procs() and Spell(arcane_missiles) or Spell(arcane_blast)
}

AddFunction ArcaneBurnCdActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not GetState(burn_phase) > 0 and not GetState(burn_phase) > 0 SetState(burn_phase 1)
 #stop_burn_phase,if=prev_gcd.1.evocation&cooldown.evocation.charges=0&burn_phase_duration>0
 if PreviousGCDSpell(evocation) and SpellCharges(evocation) == 0 and GetStateDuration() > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)

 unless { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and Spell(nether_tempest) or Spell(mark_of_aluneth)
 {
  #mirror_image
  Spell(mirror_image)

  unless { ManaPercent() > 30 or BuffPresent(arcane_power_buff) or not SpellCooldown(arcane_power) > 0 } and Spell(rune_of_power)
  {
   #arcane_power
   Spell(arcane_power)
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #arcane_torrent
   Spell(arcane_torrent_mana)
   #potion,if=buff.arcane_power.up&(buff.berserking.up|buff.blood_fury.up|!(race.troll|race.orc))
   if BuffPresent(arcane_power_buff) and { BuffPresent(berserking_buff) or BuffPresent(blood_fury_sp_buff) or not { Race(Troll) or Race(Orc) } } Item(deadly_grace_potion)
   #use_items,if=buff.arcane_power.up|target.time_to_die<cooldown.arcane_power.remains
   if BuffPresent(arcane_power_buff) or target.TimeToDie() < SpellCooldown(arcane_power) ArcaneUseItemActions()

   unless { { ManaPercent() > 30 or BuffPresent(arcane_power_buff) } and ArmorSetBonus(T20 2) or TotemRemaining(rune_of_power) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) or BuffRemaining(arcane_power_buff) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) } and Spell(presence_of_mind) or Spell(arcane_orb) or Enemies() > 4 and HasEquippedItem(mantle_of_the_first_kirin_tor) and DebuffStacks(arcane_charge_debuff) == SpellData(arcane_charge_debuff max_stacks) and Spell(arcane_barrage) or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 and Spell(arcane_missiles) or BuffPresent(presence_of_mind_buff) and Spell(arcane_blast) or Enemies() > 1 and Spell(arcane_explosion) or arcane_missiles_procs() and Spell(arcane_missiles) or Spell(arcane_blast)
   {
    #variable,name=average_burn_length,op=set,value=(variable.average_burn_length*variable.total_burns-variable.average_burn_length+burn_phase_duration)%variable.total_burns
    #evocation,interrupt_if=ticks=2|mana.pct>=85,interrupt_immediate=1
    Spell(evocation)
   }
  }
 }
}

AddFunction ArcaneBurnCdPostConditions
{
 { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and Spell(nether_tempest) or Spell(mark_of_aluneth) or { ManaPercent() > 30 or BuffPresent(arcane_power_buff) or not SpellCooldown(arcane_power) > 0 } and Spell(rune_of_power) or { { ManaPercent() > 30 or BuffPresent(arcane_power_buff) } and ArmorSetBonus(T20 2) or TotemRemaining(rune_of_power) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) or BuffRemaining(arcane_power_buff) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) } and Spell(presence_of_mind) or Spell(arcane_orb) or Enemies() > 4 and HasEquippedItem(mantle_of_the_first_kirin_tor) and DebuffStacks(arcane_charge_debuff) == SpellData(arcane_charge_debuff max_stacks) and Spell(arcane_barrage) or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 and Spell(arcane_missiles) or BuffPresent(presence_of_mind_buff) and Spell(arcane_blast) or Enemies() > 1 and Spell(arcane_explosion) or arcane_missiles_procs() and Spell(arcane_missiles) or Spell(arcane_blast)
}

### actions.build

AddFunction ArcaneBuildMainActions
{
 #charged_up,if=equipped.mystic_kilt_of_the_rune_master|(variable.arcane_missiles_procs=buff.arcane_missiles.max_stack&active_enemies<3)
 if HasEquippedItem(mystic_kilt_of_the_rune_master) or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 Spell(charged_up)
 #arcane_missiles,if=variable.arcane_missiles_procs=buff.arcane_missiles.max_stack&active_enemies<3
 if arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 Spell(arcane_missiles)
 #arcane_explosion,if=active_enemies>1
 if Enemies() > 1 Spell(arcane_explosion)
 #arcane_blast
 Spell(arcane_blast)
}

AddFunction ArcaneBuildMainPostConditions
{
}

AddFunction ArcaneBuildShortCdActions
{
 #arcane_orb
 Spell(arcane_orb)
}

AddFunction ArcaneBuildShortCdPostConditions
{
 { HasEquippedItem(mystic_kilt_of_the_rune_master) or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 } and Spell(charged_up) or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 and Spell(arcane_missiles) or Enemies() > 1 and Spell(arcane_explosion) or Spell(arcane_blast)
}

AddFunction ArcaneBuildCdActions
{
}

AddFunction ArcaneBuildCdPostConditions
{
 Spell(arcane_orb) or { HasEquippedItem(mystic_kilt_of_the_rune_master) or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 } and Spell(charged_up) or arcane_missiles_procs() == SpellData(arcane_missiles_buff max_stacks) and Enemies() < 3 and Spell(arcane_missiles) or Enemies() > 1 and Spell(arcane_explosion) or Spell(arcane_blast)
}

### actions.default

AddFunction ArcaneDefaultMainActions
{
 #call_action_list,name=variables
 ArcaneVariablesMainActions()

 unless ArcaneVariablesMainPostConditions()
 {
  #call_action_list,name=build,if=buff.arcane_charge.stack<buff.arcane_charge.max_stack&!burn_phase&time>0
  if DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 ArcaneBuildMainActions()

  unless DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 and ArcaneBuildMainPostConditions()
  {
   #call_action_list,name=burn,if=variable.time_until_burn=0|burn_phase
   if { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnMainActions()

   unless { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions()
   {
    #call_action_list,name=conserve
    ArcaneConserveMainActions()
   }
  }
 }
}

AddFunction ArcaneDefaultMainPostConditions
{
 ArcaneVariablesMainPostConditions() or DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 and ArcaneBuildMainPostConditions() or { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions() or ArcaneConserveMainPostConditions()
}

AddFunction ArcaneDefaultShortCdActions
{
 #call_action_list,name=variables
 ArcaneVariablesShortCdActions()

 unless ArcaneVariablesShortCdPostConditions()
 {
  #cancel_buff,name=presence_of_mind,if=active_enemies>1&set_bonus.tier20_2pc
  if Enemies() > 1 and ArmorSetBonus(T20 2) and BuffPresent(presence_of_mind_buff) Texture(presence_of_mind text=cancel)
  #call_action_list,name=build,if=buff.arcane_charge.stack<buff.arcane_charge.max_stack&!burn_phase&time>0
  if DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 ArcaneBuildShortCdActions()

  unless DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 and ArcaneBuildShortCdPostConditions()
  {
   #call_action_list,name=burn,if=variable.time_until_burn=0|burn_phase
   if { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnShortCdActions()

   unless { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions()
   {
    #call_action_list,name=conserve
    ArcaneConserveShortCdActions()
   }
  }
 }
}

AddFunction ArcaneDefaultShortCdPostConditions
{
 ArcaneVariablesShortCdPostConditions() or DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 and ArcaneBuildShortCdPostConditions() or { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions() or ArcaneConserveShortCdPostConditions()
}

AddFunction ArcaneDefaultCdActions
{
 #counterspell,if=target.debuff.casting.react
 if target.IsInterruptible() ArcaneInterruptActions()
 #time_warp,if=buff.bloodlust.down&(time=0|(buff.arcane_power.up&(buff.potion.up|!action.potion.usable))|target.time_to_die<=buff.bloodlust.duration)
 if BuffExpires(burst_haste_buff any=1) and { TimeInCombat() == 0 or BuffPresent(arcane_power_buff) and { BuffPresent(deadly_grace_potion_buff) or not CanCast(deadly_grace_potion) } or target.TimeToDie() <= BaseDuration(burst_haste_buff) } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
 #call_action_list,name=variables
 ArcaneVariablesCdActions()

 unless ArcaneVariablesCdPostConditions() or Enemies() > 1 and ArmorSetBonus(T20 2) and BuffPresent(presence_of_mind_buff) and Texture(presence_of_mind text=cancel)
 {
  #call_action_list,name=build,if=buff.arcane_charge.stack<buff.arcane_charge.max_stack&!burn_phase&time>0
  if DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 ArcaneBuildCdActions()

  unless DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 and ArcaneBuildCdPostConditions()
  {
   #call_action_list,name=burn,if=variable.time_until_burn=0|burn_phase
   if { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnCdActions()

   unless { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions()
   {
    #call_action_list,name=conserve
    ArcaneConserveCdActions()
   }
  }
 }
}

AddFunction ArcaneDefaultCdPostConditions
{
 ArcaneVariablesCdPostConditions() or Enemies() > 1 and ArmorSetBonus(T20 2) and BuffPresent(presence_of_mind_buff) and Texture(presence_of_mind text=cancel) or DebuffStacks(arcane_charge_debuff) < SpellData(arcane_charge_debuff max_stacks) and not GetState(burn_phase) > 0 and TimeInCombat() > 0 and ArcaneBuildCdPostConditions() or { time_until_burn() == 0 or GetState(burn_phase) > 0 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions() or ArcaneConserveCdPostConditions()
}

### Arcane icons.

AddCheckBox(opt_mage_arcane_aoe L(AOE) default specialization=arcane)

AddIcon checkbox=!opt_mage_arcane_aoe enemies=1 help=shortcd specialization=arcane
{
 if not InCombat() ArcanePrecombatShortCdActions()
 unless not InCombat() and ArcanePrecombatShortCdPostConditions()
 {
  ArcaneDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_mage_arcane_aoe help=shortcd specialization=arcane
{
 if not InCombat() ArcanePrecombatShortCdActions()
 unless not InCombat() and ArcanePrecombatShortCdPostConditions()
 {
  ArcaneDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=arcane
{
 if not InCombat() ArcanePrecombatMainActions()
 unless not InCombat() and ArcanePrecombatMainPostConditions()
 {
  ArcaneDefaultMainActions()
 }
}

AddIcon checkbox=opt_mage_arcane_aoe help=aoe specialization=arcane
{
 if not InCombat() ArcanePrecombatMainActions()
 unless not InCombat() and ArcanePrecombatMainPostConditions()
 {
  ArcaneDefaultMainActions()
 }
}

AddIcon checkbox=!opt_mage_arcane_aoe enemies=1 help=cd specialization=arcane
{
 if not InCombat() ArcanePrecombatCdActions()
 unless not InCombat() and ArcanePrecombatCdPostConditions()
 {
  ArcaneDefaultCdActions()
 }
}

AddIcon checkbox=opt_mage_arcane_aoe help=cd specialization=arcane
{
 if not InCombat() ArcanePrecombatCdActions()
 unless not InCombat() and ArcanePrecombatCdPostConditions()
 {
  ArcaneDefaultCdActions()
 }
}

### Required symbols
# arcane_missiles_buff
# arcane_power
# evocation
# presence_of_mind
# rune_of_power
# rune_of_power_talent
# summon_arcane_familiar
# mirror_image
# deadly_grace_potion
# mark_of_aluneth
# charged_up_talent
# arcane_blast
# arcane_barrage
# arcane_missiles
# supernova
# nether_tempest
# nether_tempest_debuff
# arcane_explosion
# mystic_kilt_of_the_rune_master
# rhonins_assaulting_armwraps_buff
# arcane_power_buff
# blood_fury_sp
# berserking
# arcane_torrent_mana
# berserking_buff
# blood_fury_sp_buff
# presence_of_mind_buff
# arcane_orb
# mantle_of_the_first_kirin_tor
# arcane_charge_debuff
# charged_up
# time_warp
# deadly_grace_potion_buff
# quaking_palm
# counterspell
]]
    OvaleScripts:RegisterScript("MAGE", "arcane", name, desc, code, "script")
end
do
    local name = "sc_mage_fire_t19"
    local desc = "[7.0] Simulationcraft: Mage_Fire_T19"
    local code = [[
# Based on SimulationCraft profile "Mage_Fire_T19P".
#	class=mage
#	spec=fire
#	talents=3022023

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=fire)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=fire)
AddCheckBox(opt_time_warp SpellName(time_warp) specialization=fire)

AddFunction FireInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
	{
		if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
		if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_mana)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
	}
}

AddFunction FireUseItemActions
{
	Item(Trinket0Slot text=13 usable=1)
	Item(Trinket1Slot text=14 usable=1)
}

### actions.default

AddFunction FireDefaultMainActions
{
	#call_action_list,name=combustion_phase,if=cooldown.combustion.remains<=action.rune_of_power.cast_time+(!talent.kindling.enabled*gcd)&(!talent.firestarter.enabled|!firestarter.active|active_enemies>=4|active_enemies>=2&talent.flame_patch.enabled)|buff.combustion.up
	if SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) FireCombustionPhaseMainActions()

	unless { SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) } and FireCombustionPhaseMainPostConditions()
	{
		#call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
		if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopPhaseMainActions()

		unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseMainPostConditions()
		{
			#call_action_list,name=standard_rotation
			FireStandardRotationMainActions()
		}
	}
}

AddFunction FireDefaultMainPostConditions
{
	{ SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) } and FireCombustionPhaseMainPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseMainPostConditions() or FireStandardRotationMainPostConditions()
}

AddFunction FireDefaultShortCdActions
{
	#rune_of_power,if=firestarter.active&action.rune_of_power.charges=2|cooldown.combustion.remains>40&buff.combustion.down&!talent.kindling.enabled|target.time_to_die<11|talent.kindling.enabled&(charges_fractional>1.8|time<40)&cooldown.combustion.remains>40
	if HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and Charges(rune_of_power) == 2 or SpellCooldown(combustion) > 40 and BuffExpires(combustion_buff) and not Talent(kindling_talent) or target.TimeToDie() < 11 or Talent(kindling_talent) and { Charges(rune_of_power count=0) > 1.8 or TimeInCombat() < 40 } and SpellCooldown(combustion) > 40 Spell(rune_of_power)
	#rune_of_power,if=(buff.kaelthas_ultimate_ability.react&(cooldown.combustion.remains>40|action.rune_of_power.charges>1))|(buff.erupting_infernal_core.up&(cooldown.combustion.remains>40|action.rune_of_power.charges>1))
	if BuffPresent(kaelthas_ultimate_ability_buff) and { SpellCooldown(combustion) > 40 or Charges(rune_of_power) > 1 } or BuffPresent(erupting_infernal_core_buff) and { SpellCooldown(combustion) > 40 or Charges(rune_of_power) > 1 } Spell(rune_of_power)
	#call_action_list,name=combustion_phase,if=cooldown.combustion.remains<=action.rune_of_power.cast_time+(!talent.kindling.enabled*gcd)&(!talent.firestarter.enabled|!firestarter.active|active_enemies>=4|active_enemies>=2&talent.flame_patch.enabled)|buff.combustion.up
	if SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) FireCombustionPhaseShortCdActions()

	unless { SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) } and FireCombustionPhaseShortCdPostConditions()
	{
		#call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
		if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopPhaseShortCdActions()

		unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseShortCdPostConditions()
		{
			#call_action_list,name=standard_rotation
			FireStandardRotationShortCdActions()
		}
	}
}

AddFunction FireDefaultShortCdPostConditions
{
	{ SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) } and FireCombustionPhaseShortCdPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseShortCdPostConditions() or FireStandardRotationShortCdPostConditions()
}

AddFunction FireDefaultCdActions
{
	#counterspell,if=target.debuff.casting.react
	if target.IsInterruptible() FireInterruptActions()
	#time_warp,if=(time=0&buff.bloodlust.down)|(buff.bloodlust.down&equipped.132410&(cooldown.combustion.remains<1|target.time_to_die<50))
	if { TimeInCombat() == 0 and BuffExpires(burst_haste_buff any=1) or BuffExpires(burst_haste_buff any=1) and HasEquippedItem(132410) and { SpellCooldown(combustion) < 1 or target.TimeToDie() < 50 } } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
	#mirror_image,if=buff.combustion.down
	if BuffExpires(combustion_buff) Spell(mirror_image)

	unless { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and Charges(rune_of_power) == 2 or SpellCooldown(combustion) > 40 and BuffExpires(combustion_buff) and not Talent(kindling_talent) or target.TimeToDie() < 11 or Talent(kindling_talent) and { Charges(rune_of_power count=0) > 1.8 or TimeInCombat() < 40 } and SpellCooldown(combustion) > 40 } and Spell(rune_of_power) or { BuffPresent(kaelthas_ultimate_ability_buff) and { SpellCooldown(combustion) > 40 or Charges(rune_of_power) > 1 } or BuffPresent(erupting_infernal_core_buff) and { SpellCooldown(combustion) > 40 or Charges(rune_of_power) > 1 } } and Spell(rune_of_power)
	{
		#call_action_list,name=combustion_phase,if=cooldown.combustion.remains<=action.rune_of_power.cast_time+(!talent.kindling.enabled*gcd)&(!talent.firestarter.enabled|!firestarter.active|active_enemies>=4|active_enemies>=2&talent.flame_patch.enabled)|buff.combustion.up
		if SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) FireCombustionPhaseCdActions()

		unless { SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) } and FireCombustionPhaseCdPostConditions()
		{
			#call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
			if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopPhaseCdActions()

			unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseCdPostConditions()
			{
				#call_action_list,name=standard_rotation
				FireStandardRotationCdActions()
			}
		}
	}
}

AddFunction FireDefaultCdPostConditions
{
	{ HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and Charges(rune_of_power) == 2 or SpellCooldown(combustion) > 40 and BuffExpires(combustion_buff) and not Talent(kindling_talent) or target.TimeToDie() < 11 or Talent(kindling_talent) and { Charges(rune_of_power count=0) > 1.8 or TimeInCombat() < 40 } and SpellCooldown(combustion) > 40 } and Spell(rune_of_power) or { BuffPresent(kaelthas_ultimate_ability_buff) and { SpellCooldown(combustion) > 40 or Charges(rune_of_power) > 1 } or BuffPresent(erupting_infernal_core_buff) and { SpellCooldown(combustion) > 40 or Charges(rune_of_power) > 1 } } and Spell(rune_of_power) or { SpellCooldown(combustion) <= CastTime(rune_of_power) + Talent(kindling_talent no) * GCD() and { not Talent(firestarter_talent) or not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() >= 4 or Enemies() >= 2 and Talent(flame_patch_talent) } or BuffPresent(combustion_buff) } and FireCombustionPhaseCdPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopPhaseCdPostConditions() or FireStandardRotationCdPostConditions()
}

### actions.active_talents

AddFunction FireActiveTalentsMainActions
{
	#blast_wave,if=(buff.combustion.down)|(buff.combustion.up&action.fire_blast.charges<1&action.phoenixs_flames.charges<1)
	if BuffExpires(combustion_buff) or BuffPresent(combustion_buff) and Charges(fire_blast) < 1 and Charges(phoenixs_flames) < 1 Spell(blast_wave)
	#cinderstorm,if=cooldown.combustion.remains<cast_time&(buff.rune_of_power.up|!talent.rune_on_power.enabled)|cooldown.combustion.remains>10*spell_haste&!buff.combustion.up
	if SpellCooldown(combustion) < CastTime(cinderstorm) and { BuffPresent(rune_of_power_buff) or not Talent(rune_on_power_talent) } or SpellCooldown(combustion) > 10 * { 100 / { 100 + SpellHaste() } } and not BuffPresent(combustion_buff) Spell(cinderstorm)
	#living_bomb,if=active_enemies>1&buff.combustion.down
	if Enemies() > 1 and BuffExpires(combustion_buff) Spell(living_bomb)
}

AddFunction FireActiveTalentsMainPostConditions
{
}

AddFunction FireActiveTalentsShortCdActions
{
	unless { BuffExpires(combustion_buff) or BuffPresent(combustion_buff) and Charges(fire_blast) < 1 and Charges(phoenixs_flames) < 1 } and Spell(blast_wave)
	{
		#meteor,if=cooldown.combustion.remains>40|(cooldown.combustion.remains>target.time_to_die)|buff.rune_of_power.up|firestarter.active
		if SpellCooldown(combustion) > 40 or SpellCooldown(combustion) > target.TimeToDie() or BuffPresent(rune_of_power_buff) or HasTalent(firestarter_talent) and target.HealthPercent() >= 90 Spell(meteor)

		unless { SpellCooldown(combustion) < CastTime(cinderstorm) and { BuffPresent(rune_of_power_buff) or not Talent(rune_on_power_talent) } or SpellCooldown(combustion) > 10 * { 100 / { 100 + SpellHaste() } } and not BuffPresent(combustion_buff) } and Spell(cinderstorm)
		{
			#dragons_breath,if=equipped.132863|(talent.alexstraszas_fury.enabled&buff.hot_streak.down)
			if HasEquippedItem(132863) or Talent(alexstraszas_fury_talent) and BuffExpires(hot_streak_buff) Spell(dragons_breath)
		}
	}
}

AddFunction FireActiveTalentsShortCdPostConditions
{
	{ BuffExpires(combustion_buff) or BuffPresent(combustion_buff) and Charges(fire_blast) < 1 and Charges(phoenixs_flames) < 1 } and Spell(blast_wave) or { SpellCooldown(combustion) < CastTime(cinderstorm) and { BuffPresent(rune_of_power_buff) or not Talent(rune_on_power_talent) } or SpellCooldown(combustion) > 10 * { 100 / { 100 + SpellHaste() } } and not BuffPresent(combustion_buff) } and Spell(cinderstorm) or Enemies() > 1 and BuffExpires(combustion_buff) and Spell(living_bomb)
}

AddFunction FireActiveTalentsCdActions
{
}

AddFunction FireActiveTalentsCdPostConditions
{
	{ BuffExpires(combustion_buff) or BuffPresent(combustion_buff) and Charges(fire_blast) < 1 and Charges(phoenixs_flames) < 1 } and Spell(blast_wave) or { SpellCooldown(combustion) > 40 or SpellCooldown(combustion) > target.TimeToDie() or BuffPresent(rune_of_power_buff) or HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } and Spell(meteor) or { SpellCooldown(combustion) < CastTime(cinderstorm) and { BuffPresent(rune_of_power_buff) or not Talent(rune_on_power_talent) } or SpellCooldown(combustion) > 10 * { 100 / { 100 + SpellHaste() } } and not BuffPresent(combustion_buff) } and Spell(cinderstorm) or { HasEquippedItem(132863) or Talent(alexstraszas_fury_talent) and BuffExpires(hot_streak_buff) } and Spell(dragons_breath) or Enemies() > 1 and BuffExpires(combustion_buff) and Spell(living_bomb)
}

### actions.combustion_phase

AddFunction FireCombustionPhaseMainActions
{
	#call_action_list,name=active_talents
	FireActiveTalentsMainActions()

	unless FireActiveTalentsMainPostConditions()
	{
		#flamestrike,if=(talent.flame_patch.enabled&active_enemies>2|active_enemies>4)&buff.hot_streak.up
		if { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 4 } and BuffPresent(hot_streak_buff) Spell(flamestrike)
		#pyroblast,if=buff.kaelthas_ultimate_ability.react&buff.combustion.remains>execute_time
		if BuffPresent(kaelthas_ultimate_ability_buff) and BuffRemaining(combustion_buff) > ExecuteTime(pyroblast) Spell(pyroblast)
		#pyroblast,if=buff.hot_streak.up
		if BuffPresent(hot_streak_buff) Spell(pyroblast)
		#phoenixs_flames
		Spell(phoenixs_flames)
		#scorch,if=buff.combustion.remains>cast_time
		if BuffRemaining(combustion_buff) > CastTime(scorch) Spell(scorch)
		#scorch,if=target.health.pct<=30&equipped.132454
		if target.HealthPercent() <= 30 and HasEquippedItem(132454) Spell(scorch)
	}
}

AddFunction FireCombustionPhaseMainPostConditions
{
	FireActiveTalentsMainPostConditions()
}

AddFunction FireCombustionPhaseShortCdActions
{
	#rune_of_power,if=buff.combustion.down
	if BuffExpires(combustion_buff) Spell(rune_of_power)
	#call_action_list,name=active_talents
	FireActiveTalentsShortCdActions()

	unless FireActiveTalentsShortCdPostConditions() or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(kaelthas_ultimate_ability_buff) and BuffRemaining(combustion_buff) > ExecuteTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast)
	{
		#fire_blast,if=buff.heating_up.up
		if BuffPresent(heating_up_buff) Spell(fire_blast)

		unless Spell(phoenixs_flames) or BuffRemaining(combustion_buff) > CastTime(scorch) and Spell(scorch)
		{
			#dragons_breath,if=buff.hot_streak.down&action.fire_blast.charges<1&action.phoenixs_flames.charges<1
			if BuffExpires(hot_streak_buff) and Charges(fire_blast) < 1 and Charges(phoenixs_flames) < 1 Spell(dragons_breath)
		}
	}
}

AddFunction FireCombustionPhaseShortCdPostConditions
{
	FireActiveTalentsShortCdPostConditions() or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(kaelthas_ultimate_ability_buff) and BuffRemaining(combustion_buff) > ExecuteTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or Spell(phoenixs_flames) or BuffRemaining(combustion_buff) > CastTime(scorch) and Spell(scorch) or target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(scorch)
}

AddFunction FireCombustionPhaseCdActions
{
	unless BuffExpires(combustion_buff) and Spell(rune_of_power)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsCdActions()

		unless FireActiveTalentsCdPostConditions()
		{
			#combustion
			Spell(combustion)
			#potion
			if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
			#blood_fury
			Spell(blood_fury_sp)
			#berserking
			Spell(berserking)
			#arcane_torrent
			Spell(arcane_torrent_mana)
			#use_items
			FireUseItemActions()
		}
	}
}

AddFunction FireCombustionPhaseCdPostConditions
{
	BuffExpires(combustion_buff) and Spell(rune_of_power) or FireActiveTalentsCdPostConditions() or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(kaelthas_ultimate_ability_buff) and BuffRemaining(combustion_buff) > ExecuteTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or Spell(phoenixs_flames) or BuffRemaining(combustion_buff) > CastTime(scorch) and Spell(scorch) or BuffExpires(hot_streak_buff) and Charges(fire_blast) < 1 and Charges(phoenixs_flames) < 1 and Spell(dragons_breath) or target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(scorch)
}

### actions.precombat

AddFunction FirePrecombatMainActions
{
	#pyroblast
	Spell(pyroblast)
}

AddFunction FirePrecombatMainPostConditions
{
}

AddFunction FirePrecombatShortCdActions
{
}

AddFunction FirePrecombatShortCdPostConditions
{
	Spell(pyroblast)
}

AddFunction FirePrecombatCdActions
{
	#flask
	#food
	#augmentation
	#snapshot_stats
	#mirror_image
	Spell(mirror_image)
	#potion
	if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(prolonged_power_potion usable=1)
}

AddFunction FirePrecombatCdPostConditions
{
	Spell(pyroblast)
}

### actions.rop_phase

AddFunction FireRopPhaseMainActions
{
	#flamestrike,if=((talent.flame_patch.enabled&active_enemies>1)|active_enemies>3)&buff.hot_streak.up
	if { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) Spell(flamestrike)
	#pyroblast,if=buff.hot_streak.up
	if BuffPresent(hot_streak_buff) Spell(pyroblast)
	#call_action_list,name=active_talents
	FireActiveTalentsMainActions()

	unless FireActiveTalentsMainPostConditions()
	{
		#pyroblast,if=buff.kaelthas_ultimate_ability.react&execute_time<buff.kaelthas_ultimate_ability.remains
		if BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) Spell(pyroblast)
		#phoenixs_flames,if=!prev_gcd.1.phoenixs_flames&charges_fractional>2.7&firestarter.active
		if not PreviousGCDSpell(phoenixs_flames) and Charges(phoenixs_flames count=0) > 2.7 and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 Spell(phoenixs_flames)
		#phoenixs_flames,if=!prev_gcd.1.phoenixs_flames
		if not PreviousGCDSpell(phoenixs_flames) Spell(phoenixs_flames)
		#scorch,if=target.health.pct<=30&equipped.132454
		if target.HealthPercent() <= 30 and HasEquippedItem(132454) Spell(scorch)
		#flamestrike,if=(talent.flame_patch.enabled&active_enemies>2)|active_enemies>5
		if Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 5 Spell(flamestrike)
		#fireball
		Spell(fireball)
	}
}

AddFunction FireRopPhaseMainPostConditions
{
	FireActiveTalentsMainPostConditions()
}

AddFunction FireRopPhaseShortCdActions
{
	#rune_of_power
	Spell(rune_of_power)

	unless { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsShortCdActions()

		unless FireActiveTalentsShortCdPostConditions() or BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) and Spell(pyroblast)
		{
			#fire_blast,if=!prev_off_gcd.fire_blast&buff.heating_up.up&firestarter.active&charges_fractional>1.7
			if not PreviousOffGCDSpell(fire_blast) and BuffPresent(heating_up_buff) and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and Charges(fire_blast count=0) > 1.7 Spell(fire_blast)

			unless not PreviousGCDSpell(phoenixs_flames) and Charges(phoenixs_flames count=0) > 2.7 and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and Spell(phoenixs_flames)
			{
				#fire_blast,if=!prev_off_gcd.fire_blast&!firestarter.active
				if not PreviousOffGCDSpell(fire_blast) and not { HasTalent(firestarter_talent) and target.HealthPercent() >= 90 } Spell(fire_blast)

				unless not PreviousGCDSpell(phoenixs_flames) and Spell(phoenixs_flames) or target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(scorch)
				{
					#dragons_breath,if=active_enemies>2
					if Enemies() > 2 Spell(dragons_breath)
				}
			}
		}
	}
}

AddFunction FireRopPhaseShortCdPostConditions
{
	{ Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or FireActiveTalentsShortCdPostConditions() or BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) and Spell(pyroblast) or not PreviousGCDSpell(phoenixs_flames) and Charges(phoenixs_flames count=0) > 2.7 and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and Spell(phoenixs_flames) or not PreviousGCDSpell(phoenixs_flames) and Spell(phoenixs_flames) or target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(scorch) or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 5 } and Spell(flamestrike) or Spell(fireball)
}

AddFunction FireRopPhaseCdActions
{
	unless Spell(rune_of_power) or { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsCdActions()
	}
}

AddFunction FireRopPhaseCdPostConditions
{
	Spell(rune_of_power) or { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or FireActiveTalentsCdPostConditions() or BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) and Spell(pyroblast) or not PreviousGCDSpell(phoenixs_flames) and Charges(phoenixs_flames count=0) > 2.7 and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and Spell(phoenixs_flames) or not PreviousGCDSpell(phoenixs_flames) and Spell(phoenixs_flames) or target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(scorch) or Enemies() > 2 and Spell(dragons_breath) or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 5 } and Spell(flamestrike) or Spell(fireball)
}

### actions.standard_rotation

AddFunction FireStandardRotationMainActions
{
	#flamestrike,if=((talent.flame_patch.enabled&active_enemies>1)|active_enemies>3)&buff.hot_streak.up
	if { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) Spell(flamestrike)
	#pyroblast,if=buff.hot_streak.up&buff.hot_streak.remains<action.fireball.execute_time
	if BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) Spell(pyroblast)
	#pyroblast,if=buff.hot_streak.up&firestarter.active&!talent.rune_of_power.enabled
	if BuffPresent(hot_streak_buff) and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and not Talent(rune_of_power_talent) Spell(pyroblast)
	#phoenixs_flames,if=charges_fractional>2.7&active_enemies>2
	if Charges(phoenixs_flames count=0) > 2.7 and Enemies() > 2 Spell(phoenixs_flames)
	#pyroblast,if=buff.hot_streak.up&!prev_gcd.1.pyroblast
	if BuffPresent(hot_streak_buff) and not PreviousGCDSpell(pyroblast) Spell(pyroblast)
	#pyroblast,if=buff.hot_streak.react&target.health.pct<=30&equipped.132454
	if BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and HasEquippedItem(132454) Spell(pyroblast)
	#pyroblast,if=buff.kaelthas_ultimate_ability.react&execute_time<buff.kaelthas_ultimate_ability.remains
	if BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) Spell(pyroblast)
	#call_action_list,name=active_talents
	FireActiveTalentsMainActions()

	unless FireActiveTalentsMainPostConditions()
	{
		#phoenixs_flames,if=(buff.combustion.up|buff.rune_of_power.up|buff.incanters_flow.stack>3|talent.mirror_image.enabled)&artifact.phoenix_reborn.enabled&(4-charges_fractional)*13<cooldown.combustion.remains+5|target.time_to_die<10
		if { BuffPresent(combustion_buff) or BuffPresent(rune_of_power_buff) or BuffStacks(incanters_flow_buff) > 3 or Talent(mirror_image_talent) } and HasArtifactTrait(phoenix_reborn) and { 4 - Charges(phoenixs_flames count=0) } * 13 < SpellCooldown(combustion) + 5 or target.TimeToDie() < 10 Spell(phoenixs_flames)
		#phoenixs_flames,if=(buff.combustion.up|buff.rune_of_power.up)&(4-charges_fractional)*30<cooldown.combustion.remains+5
		if { BuffPresent(combustion_buff) or BuffPresent(rune_of_power_buff) } and { 4 - Charges(phoenixs_flames count=0) } * 30 < SpellCooldown(combustion) + 5 Spell(phoenixs_flames)
		#phoenixs_flames,if=charges_fractional>2.5&cooldown.combustion.remains>23
		if Charges(phoenixs_flames count=0) > 2.5 and SpellCooldown(combustion) > 23 Spell(phoenixs_flames)
		#flamestrike,if=(talent.flame_patch.enabled&active_enemies>3)|active_enemies>5
		if Talent(flame_patch_talent) and Enemies() > 3 or Enemies() > 5 Spell(flamestrike)
		#scorch,if=target.health.pct<=30&equipped.132454
		if target.HealthPercent() <= 30 and HasEquippedItem(132454) Spell(scorch)
		#fireball
		Spell(fireball)
	}
}

AddFunction FireStandardRotationMainPostConditions
{
	FireActiveTalentsMainPostConditions()
}

AddFunction FireStandardRotationShortCdActions
{
	unless { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and not Talent(rune_of_power_talent) and Spell(pyroblast) or Charges(phoenixs_flames count=0) > 2.7 and Enemies() > 2 and Spell(phoenixs_flames) or BuffPresent(hot_streak_buff) and not PreviousGCDSpell(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(pyroblast) or BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) and Spell(pyroblast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsShortCdActions()

		unless FireActiveTalentsShortCdPostConditions()
		{
			#fire_blast,if=!talent.kindling.enabled&buff.heating_up.up&(!talent.rune_of_power.enabled|charges_fractional>1.4|cooldown.combustion.remains<40)&(3-charges_fractional)*(12*spell_haste)<cooldown.combustion.remains+3|target.time_to_die<4
			if not Talent(kindling_talent) and BuffPresent(heating_up_buff) and { not Talent(rune_of_power_talent) or Charges(fire_blast count=0) > 1.4 or SpellCooldown(combustion) < 40 } and { 3 - Charges(fire_blast count=0) } * 12 * { 100 / { 100 + SpellHaste() } } < SpellCooldown(combustion) + 3 or target.TimeToDie() < 4 Spell(fire_blast)
			#fire_blast,if=talent.kindling.enabled&buff.heating_up.up&(!talent.rune_of_power.enabled|charges_fractional>1.5|cooldown.combustion.remains<40)&(3-charges_fractional)*(18*spell_haste)<cooldown.combustion.remains+3|target.time_to_die<4
			if Talent(kindling_talent) and BuffPresent(heating_up_buff) and { not Talent(rune_of_power_talent) or Charges(fire_blast count=0) > 1.5 or SpellCooldown(combustion) < 40 } and { 3 - Charges(fire_blast count=0) } * 18 * { 100 / { 100 + SpellHaste() } } < SpellCooldown(combustion) + 3 or target.TimeToDie() < 4 Spell(fire_blast)
		}
	}
}

AddFunction FireStandardRotationShortCdPostConditions
{
	{ Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and not Talent(rune_of_power_talent) and Spell(pyroblast) or Charges(phoenixs_flames count=0) > 2.7 and Enemies() > 2 and Spell(phoenixs_flames) or BuffPresent(hot_streak_buff) and not PreviousGCDSpell(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(pyroblast) or BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) and Spell(pyroblast) or FireActiveTalentsShortCdPostConditions() or { { BuffPresent(combustion_buff) or BuffPresent(rune_of_power_buff) or BuffStacks(incanters_flow_buff) > 3 or Talent(mirror_image_talent) } and HasArtifactTrait(phoenix_reborn) and { 4 - Charges(phoenixs_flames count=0) } * 13 < SpellCooldown(combustion) + 5 or target.TimeToDie() < 10 } and Spell(phoenixs_flames) or { BuffPresent(combustion_buff) or BuffPresent(rune_of_power_buff) } and { 4 - Charges(phoenixs_flames count=0) } * 30 < SpellCooldown(combustion) + 5 and Spell(phoenixs_flames) or Charges(phoenixs_flames count=0) > 2.5 and SpellCooldown(combustion) > 23 and Spell(phoenixs_flames) or { Talent(flame_patch_talent) and Enemies() > 3 or Enemies() > 5 } and Spell(flamestrike) or target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(scorch) or Spell(fireball)
}

AddFunction FireStandardRotationCdActions
{
	unless { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and not Talent(rune_of_power_talent) and Spell(pyroblast) or Charges(phoenixs_flames count=0) > 2.7 and Enemies() > 2 and Spell(phoenixs_flames) or BuffPresent(hot_streak_buff) and not PreviousGCDSpell(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(pyroblast) or BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) and Spell(pyroblast)
	{
		#call_action_list,name=active_talents
		FireActiveTalentsCdActions()
	}
}

AddFunction FireStandardRotationCdPostConditions
{
	{ Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 3 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and HasTalent(firestarter_talent) and target.HealthPercent() >= 90 and not Talent(rune_of_power_talent) and Spell(pyroblast) or Charges(phoenixs_flames count=0) > 2.7 and Enemies() > 2 and Spell(phoenixs_flames) or BuffPresent(hot_streak_buff) and not PreviousGCDSpell(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(pyroblast) or BuffPresent(kaelthas_ultimate_ability_buff) and ExecuteTime(pyroblast) < BuffRemaining(kaelthas_ultimate_ability_buff) and Spell(pyroblast) or FireActiveTalentsCdPostConditions() or { { BuffPresent(combustion_buff) or BuffPresent(rune_of_power_buff) or BuffStacks(incanters_flow_buff) > 3 or Talent(mirror_image_talent) } and HasArtifactTrait(phoenix_reborn) and { 4 - Charges(phoenixs_flames count=0) } * 13 < SpellCooldown(combustion) + 5 or target.TimeToDie() < 10 } and Spell(phoenixs_flames) or { BuffPresent(combustion_buff) or BuffPresent(rune_of_power_buff) } and { 4 - Charges(phoenixs_flames count=0) } * 30 < SpellCooldown(combustion) + 5 and Spell(phoenixs_flames) or Charges(phoenixs_flames count=0) > 2.5 and SpellCooldown(combustion) > 23 and Spell(phoenixs_flames) or { Talent(flame_patch_talent) and Enemies() > 3 or Enemies() > 5 } and Spell(flamestrike) or target.HealthPercent() <= 30 and HasEquippedItem(132454) and Spell(scorch) or Spell(fireball)
}

### Fire icons.

AddCheckBox(opt_mage_fire_aoe L(AOE) default specialization=fire)

AddIcon checkbox=!opt_mage_fire_aoe enemies=1 help=shortcd specialization=fire
{
	if not InCombat() FirePrecombatShortCdActions()
	unless not InCombat() and FirePrecombatShortCdPostConditions()
	{
		FireDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_mage_fire_aoe help=shortcd specialization=fire
{
	if not InCombat() FirePrecombatShortCdActions()
	unless not InCombat() and FirePrecombatShortCdPostConditions()
	{
		FireDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=fire
{
	if not InCombat() FirePrecombatMainActions()
	unless not InCombat() and FirePrecombatMainPostConditions()
	{
		FireDefaultMainActions()
	}
}

AddIcon checkbox=opt_mage_fire_aoe help=aoe specialization=fire
{
	if not InCombat() FirePrecombatMainActions()
	unless not InCombat() and FirePrecombatMainPostConditions()
	{
		FireDefaultMainActions()
	}
}

AddIcon checkbox=!opt_mage_fire_aoe enemies=1 help=cd specialization=fire
{
	if not InCombat() FirePrecombatCdActions()
	unless not InCombat() and FirePrecombatCdPostConditions()
	{
		FireDefaultCdActions()
	}
}

AddIcon checkbox=opt_mage_fire_aoe help=cd specialization=fire
{
	if not InCombat() FirePrecombatCdActions()
	unless not InCombat() and FirePrecombatCdPostConditions()
	{
		FireDefaultCdActions()
	}
}

### Required symbols
# 132410
# 132454
# 132863
# alexstraszas_fury_talent
# arcane_torrent_mana
# berserking
# blast_wave
# blood_fury_sp
# cinderstorm
# combustion
# combustion_buff
# counterspell
# dragons_breath
# erupting_infernal_core_buff
# fire_blast
# fireball
# firestarter_talent
# flame_patch_talent
# flamestrike
# heating_up_buff
# hot_streak_buff
# incanters_flow_buff
# kaelthas_ultimate_ability_buff
# kindling_talent
# living_bomb
# meteor
# mirror_image
# mirror_image_talent
# phoenix_reborn
# phoenixs_flames
# prolonged_power_potion
# pyroblast
# quaking_palm
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# rune_on_power_talent
# scorch
# time_warp
]]
    OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
end
do
    local name = "sc_mage_frost_t19"
    local desc = "[7.0] Simulationcraft: Mage_Frost_T19"
    local code = [[
# Based on SimulationCraft profile "Mage_Frost_T19P".
#	class=mage
#	spec=frost
#	talents=3122111

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)


AddFunction fof_react
{
 if HasEquippedItem(lady_vashjs_grasp) and BuffPresent(icy_veins_buff) and time_until_fof() > 9 or PreviousOffGCDSpell(freeze) or DebuffRemaining(frozen_orb_debuff) > 8 BuffPresent(fingers_of_frost_buff)
 BuffPresent(fingers_of_frost_buff)
}

AddFunction time_until_fof
{
 10 - { TimeInCombat() - iv_start() - { TimeInCombat() - iv_start() } / 10 * 10 }
}

AddFunction iv_start
{
 if PreviousOffGCDSpell(icy_veins) TimeInCombat()
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=frost)
AddCheckBox(opt_time_warp SpellName(time_warp) specialization=frost)

AddFunction FrostInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.Distance(less 8) and target.IsInterruptible() Spell(arcane_torrent_mana)
  if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
 }
}

AddFunction FrostUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.variables

AddFunction FrostVariablesMainActions
{
}

AddFunction FrostVariablesMainPostConditions
{
}

AddFunction FrostVariablesShortCdActions
{
}

AddFunction FrostVariablesShortCdPostConditions
{
}

AddFunction FrostVariablesCdActions
{
}

AddFunction FrostVariablesCdPostConditions
{
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=debuff.winters_chill.up
 if target.DebuffPresent(winters_chill_debuff) Spell(ice_nova)
 #frostbolt,if=prev_off_gcd.water_jet
 if PreviousOffGCDSpell(water_elemental_water_jet) Spell(frostbolt)
 #water_jet,if=prev_gcd.1.frostbolt&buff.fingers_of_frost.stack<3&buff.brain_freeze.react=0
 if PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and BuffStacks(brain_freeze_buff) == 0 Spell(water_elemental_water_jet)
 #ray_of_frost,if=buff.icy_veins.up|cooldown.icy_veins.remains>action.ray_of_frost.cooldown&buff.rune_of_power.down
 if BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) Spell(ray_of_frost)
 #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.glacial_spike|prev_gcd.1.frostbolt&(!talent.glacial_spike.enabled|buff.icicles.stack<=3|cooldown.frozen_orb.remains<=10&set_bonus.tier20_2pc))
 if PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 3 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } Spell(flurry)
 #blizzard,if=cast_time=0&active_enemies>1&variable.fof_react<3
 if CastTime(blizzard) == 0 and Enemies() > 1 and fof_react() < 3 Spell(blizzard)
 #ice_lance,if=variable.fof_react
 if fof_react() Spell(ice_lance)
 #ebonbolt
 Spell(ebonbolt)
 #ice_nova
 Spell(ice_nova)
 #blizzard,if=active_enemies>1|buff.zannesu_journey.stack=5&buff.zannesu_journey.remains>cast_time
 if Enemies() > 1 or BuffStacks(zannesu_journey_buff) == 5 and BuffRemaining(zannesu_journey_buff) > CastTime(blizzard) Spell(blizzard)
 #frostbolt,if=buff.frozen_mass.remains>execute_time+action.glacial_spike.execute_time+action.glacial_spike.travel_time&buff.brain_freeze.react=0&talent.glacial_spike.enabled
 if BuffRemaining(frozen_mass_buff) > ExecuteTime(frostbolt) + ExecuteTime(glacial_spike) + TravelTime(glacial_spike) and BuffStacks(brain_freeze_buff) == 0 and Talent(glacial_spike_talent) Spell(frostbolt)
 #glacial_spike,if=cooldown.frozen_orb.remains>10|!set_bonus.tier20_2pc
 if SpellCooldown(frozen_orb) > 10 or not ArmorSetBonus(T20 2) Spell(glacial_spike)
 #frostbolt
 Spell(frostbolt)
 #blizzard
 Spell(blizzard)
 #ice_lance
 Spell(ice_lance)
}

AddFunction FrostSingleMainPostConditions
{
}

AddFunction FrostSingleShortCdActions
{
 unless target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and BuffStacks(brain_freeze_buff) == 0 and Spell(water_elemental_water_jet) or { BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) } and Spell(ray_of_frost) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 3 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } } and Spell(flurry)
 {
  #frozen_orb,if=set_bonus.tier20_2pc&variable.fof_react<3
  if ArmorSetBonus(T20 2) and fof_react() < 3 Spell(frozen_orb)

  unless CastTime(blizzard) == 0 and Enemies() > 1 and fof_react() < 3 and Spell(blizzard)
  {
   #frost_bomb,if=debuff.frost_bomb.remains<action.ice_lance.travel_time&variable.fof_react
   if target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and fof_react() Spell(frost_bomb)

   unless fof_react() and Spell(ice_lance) or Spell(ebonbolt)
   {
    #frozen_orb
    Spell(frozen_orb)

    unless Spell(ice_nova)
    {
     #comet_storm
     Spell(comet_storm)
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and BuffStacks(brain_freeze_buff) == 0 and Spell(water_elemental_water_jet) or { BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) } and Spell(ray_of_frost) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 3 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } } and Spell(flurry) or CastTime(blizzard) == 0 and Enemies() > 1 and fof_react() < 3 and Spell(blizzard) or fof_react() and Spell(ice_lance) or Spell(ebonbolt) or Spell(ice_nova) or { Enemies() > 1 or BuffStacks(zannesu_journey_buff) == 5 and BuffRemaining(zannesu_journey_buff) > CastTime(blizzard) } and Spell(blizzard) or BuffRemaining(frozen_mass_buff) > ExecuteTime(frostbolt) + ExecuteTime(glacial_spike) + TravelTime(glacial_spike) and BuffStacks(brain_freeze_buff) == 0 and Talent(glacial_spike_talent) and Spell(frostbolt) or { SpellCooldown(frozen_orb) > 10 or not ArmorSetBonus(T20 2) } and Spell(glacial_spike) or Spell(frostbolt) or Spell(blizzard) or Spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
}

AddFunction FrostSingleCdPostConditions
{
 target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and BuffStacks(brain_freeze_buff) == 0 and Spell(water_elemental_water_jet) or { BuffPresent(icy_veins_buff) or SpellCooldown(icy_veins) > SpellCooldown(ray_of_frost) and BuffExpires(rune_of_power_buff) } and Spell(ray_of_frost) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) <= 3 or SpellCooldown(frozen_orb) <= 10 and ArmorSetBonus(T20 2) } } } and Spell(flurry) or ArmorSetBonus(T20 2) and fof_react() < 3 and Spell(frozen_orb) or CastTime(blizzard) == 0 and Enemies() > 1 and fof_react() < 3 and Spell(blizzard) or target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and fof_react() and Spell(frost_bomb) or fof_react() and Spell(ice_lance) or Spell(ebonbolt) or Spell(frozen_orb) or Spell(ice_nova) or Spell(comet_storm) or { Enemies() > 1 or BuffStacks(zannesu_journey_buff) == 5 and BuffRemaining(zannesu_journey_buff) > CastTime(blizzard) } and Spell(blizzard) or BuffRemaining(frozen_mass_buff) > ExecuteTime(frostbolt) + ExecuteTime(glacial_spike) + TravelTime(glacial_spike) and BuffStacks(brain_freeze_buff) == 0 and Talent(glacial_spike_talent) and Spell(frostbolt) or { SpellCooldown(frozen_orb) > 10 or not ArmorSetBonus(T20 2) } and Spell(glacial_spike) or Spell(frostbolt) or Spell(blizzard) or Spell(ice_lance)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #frostbolt
 Spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 #flask
 #food
 #augmentation
 #water_elemental
 if not pet.Present() Spell(water_elemental)
}

AddFunction FrostPrecombatShortCdPostConditions
{
 Spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless not pet.Present() and Spell(water_elemental)
 {
  #snapshot_stats
  #mirror_image
  Spell(mirror_image)
  #potion
  Item(prolonged_power_potion)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 not pet.Present() and Spell(water_elemental) or Spell(frostbolt)
}

### actions.movement

AddFunction FrostMovementMainActions
{
}

AddFunction FrostMovementMainPostConditions
{
}

AddFunction FrostMovementShortCdActions
{
 #blink,if=movement.distance>10
 if target.Distance() > 10 Spell(blink)
 #ice_floes,if=buff.ice_floes.down&variable.fof_react=0
 if BuffExpires(ice_floes_buff) and fof_react() == 0 Spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 target.Distance() > 10 and Spell(blink) or BuffExpires(ice_floes_buff) and fof_react() == 0 and Spell(ice_floes)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
}

AddFunction FrostCooldownsMainPostConditions
{
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=cooldown.icy_veins.remains<cast_time|charges_fractional>1.9&cooldown.icy_veins.remains>10|buff.icy_veins.up|target.time_to_die+5<charges_fractional*10
 if SpellCooldown(icy_veins) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1 and SpellCooldown(icy_veins) > 10 or BuffPresent(icy_veins_buff) or target.TimeToDie() + 5 < Charges(rune_of_power count=0) * 10 Spell(rune_of_power)
}

AddFunction FrostCooldownsShortCdPostConditions
{
}

AddFunction FrostCooldownsCdActions
{
 unless { SpellCooldown(icy_veins) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1 and SpellCooldown(icy_veins) > 10 or BuffPresent(icy_veins_buff) or target.TimeToDie() + 5 < Charges(rune_of_power count=0) * 10 } and Spell(rune_of_power)
 {
  #potion,if=cooldown.icy_veins.remains<1|target.time_to_die<70
  if SpellCooldown(icy_veins) < 1 or target.TimeToDie() < 70 Item(prolonged_power_potion)
  #icy_veins
  Spell(icy_veins)
  #mirror_image
  Spell(mirror_image)
  #use_items
  FrostUseItemActions()
  #blood_fury
  Spell(blood_fury_sp)
  #berserking
  Spell(berserking)
  #arcane_torrent
  Spell(arcane_torrent_mana)
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { SpellCooldown(icy_veins) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1 and SpellCooldown(icy_veins) > 10 or BuffPresent(icy_veins_buff) or target.TimeToDie() + 5 < Charges(rune_of_power count=0) * 10 } and Spell(rune_of_power)
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #frostbolt,if=prev_off_gcd.water_jet
 if PreviousOffGCDSpell(water_elemental_water_jet) Spell(frostbolt)
 #blizzard
 Spell(blizzard)
 #ice_nova
 Spell(ice_nova)
 #water_jet,if=prev_gcd.1.frostbolt&buff.fingers_of_frost.stack<3&buff.brain_freeze.react=0
 if PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and BuffStacks(brain_freeze_buff) == 0 Spell(water_elemental_water_jet)
 #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.glacial_spike|prev_gcd.1.frostbolt)
 if PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } Spell(flurry)
 #ice_lance,if=variable.fof_react
 if fof_react() Spell(ice_lance)
 #ebonbolt
 Spell(ebonbolt)
 #glacial_spike
 Spell(glacial_spike)
 #frostbolt
 Spell(frostbolt)
 #ice_lance
 Spell(ice_lance)
}

AddFunction FrostAoeMainPostConditions
{
}

AddFunction FrostAoeShortCdActions
{
 unless PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt)
 {
  #frozen_orb
  Spell(frozen_orb)

  unless Spell(blizzard)
  {
   #comet_storm
   Spell(comet_storm)

   unless Spell(ice_nova) or PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and BuffStacks(brain_freeze_buff) == 0 and Spell(water_elemental_water_jet) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } } and Spell(flurry)
   {
    #frost_bomb,if=debuff.frost_bomb.remains<action.ice_lance.travel_time&variable.fof_react
    if target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and fof_react() Spell(frost_bomb)

    unless fof_react() and Spell(ice_lance) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt)
    {
     #cone_of_cold
     Spell(cone_of_cold)
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or Spell(blizzard) or Spell(ice_nova) or PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and BuffStacks(brain_freeze_buff) == 0 and Spell(water_elemental_water_jet) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } } and Spell(flurry) or fof_react() and Spell(ice_lance) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt) or Spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
}

AddFunction FrostAoeCdPostConditions
{
 PreviousOffGCDSpell(water_elemental_water_jet) and Spell(frostbolt) or Spell(frozen_orb) or Spell(blizzard) or Spell(comet_storm) or Spell(ice_nova) or PreviousGCDSpell(frostbolt) and BuffStacks(fingers_of_frost_buff) < 3 and BuffStacks(brain_freeze_buff) == 0 and Spell(water_elemental_water_jet) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(glacial_spike) or PreviousGCDSpell(frostbolt) } } and Spell(flurry) or target.DebuffRemaining(frost_bomb_debuff) < TravelTime(ice_lance) and fof_react() and Spell(frost_bomb) or fof_react() and Spell(ice_lance) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt) or Spell(cone_of_cold) or Spell(ice_lance)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #call_action_list,name=variables
 FrostVariablesMainActions()

 unless FrostVariablesMainPostConditions()
 {
  #ice_lance,if=variable.fof_react=0&prev_gcd.1.flurry
  if fof_react() == 0 and PreviousGCDSpell(flurry) Spell(ice_lance)
  #call_action_list,name=movement,moving=1
  if Speed() > 0 FrostMovementMainActions()

  unless Speed() > 0 and FrostMovementMainPostConditions()
  {
   #call_action_list,name=cooldowns
   FrostCooldownsMainActions()

   unless FrostCooldownsMainPostConditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if Enemies() >= 3 FrostAoeMainActions()

    unless Enemies() >= 3 and FrostAoeMainPostConditions()
    {
     #call_action_list,name=single
     FrostSingleMainActions()
    }
   }
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostVariablesMainPostConditions() or Speed() > 0 and FrostMovementMainPostConditions() or FrostCooldownsMainPostConditions() or Enemies() >= 3 and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 #call_action_list,name=variables
 FrostVariablesShortCdActions()

 unless FrostVariablesShortCdPostConditions() or fof_react() == 0 and PreviousGCDSpell(flurry) and Spell(ice_lance)
 {
  #call_action_list,name=movement,moving=1
  if Speed() > 0 FrostMovementShortCdActions()

  unless Speed() > 0 and FrostMovementShortCdPostConditions()
  {
   #call_action_list,name=cooldowns
   FrostCooldownsShortCdActions()

   unless FrostCooldownsShortCdPostConditions()
   {
    #call_action_list,name=aoe,if=active_enemies>=3
    if Enemies() >= 3 FrostAoeShortCdActions()

    unless Enemies() >= 3 and FrostAoeShortCdPostConditions()
    {
     #call_action_list,name=single
     FrostSingleShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 FrostVariablesShortCdPostConditions() or fof_react() == 0 and PreviousGCDSpell(flurry) and Spell(ice_lance) or Speed() > 0 and FrostMovementShortCdPostConditions() or FrostCooldownsShortCdPostConditions() or Enemies() >= 3 and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #call_action_list,name=variables
 FrostVariablesCdActions()

 unless FrostVariablesCdPostConditions()
 {
  #counterspell
  FrostInterruptActions()

  unless fof_react() == 0 and PreviousGCDSpell(flurry) and Spell(ice_lance)
  {
   #time_warp,if=buff.bloodlust.down&(buff.exhaustion.down|equipped.shard_of_the_exodar)&(cooldown.icy_veins.remains<1|target.time_to_die<50)
   if BuffExpires(burst_haste_buff any=1) and { DebuffExpires(burst_haste_debuff any=1) or HasEquippedItem(shard_of_the_exodar) } and { SpellCooldown(icy_veins) < 1 or target.TimeToDie() < 50 } and CheckBoxOn(opt_time_warp) and DebuffExpires(burst_haste_debuff any=1) Spell(time_warp)
   #call_action_list,name=movement,moving=1
   if Speed() > 0 FrostMovementCdActions()

   unless Speed() > 0 and FrostMovementCdPostConditions()
   {
    #call_action_list,name=cooldowns
    FrostCooldownsCdActions()

    unless FrostCooldownsCdPostConditions()
    {
     #call_action_list,name=aoe,if=active_enemies>=3
     if Enemies() >= 3 FrostAoeCdActions()

     unless Enemies() >= 3 and FrostAoeCdPostConditions()
     {
      #call_action_list,name=single
      FrostSingleCdActions()
     }
    }
   }
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 FrostVariablesCdPostConditions() or fof_react() == 0 and PreviousGCDSpell(flurry) and Spell(ice_lance) or Speed() > 0 and FrostMovementCdPostConditions() or FrostCooldownsCdPostConditions() or Enemies() >= 3 and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
}

### Frost icons.

AddCheckBox(opt_mage_frost_aoe L(AOE) default specialization=frost)

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=shortcd specialization=frost
{
 if not InCombat() FrostPrecombatShortCdActions()
 unless not InCombat() and FrostPrecombatShortCdPostConditions()
 {
  FrostDefaultShortCdActions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=shortcd specialization=frost
{
 if not InCombat() FrostPrecombatShortCdActions()
 unless not InCombat() and FrostPrecombatShortCdPostConditions()
 {
  FrostDefaultShortCdActions()
 }
}

AddIcon enemies=1 help=main specialization=frost
{
 if not InCombat() FrostPrecombatMainActions()
 unless not InCombat() and FrostPrecombatMainPostConditions()
 {
  FrostDefaultMainActions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=aoe specialization=frost
{
 if not InCombat() FrostPrecombatMainActions()
 unless not InCombat() and FrostPrecombatMainPostConditions()
 {
  FrostDefaultMainActions()
 }
}

AddIcon checkbox=!opt_mage_frost_aoe enemies=1 help=cd specialization=frost
{
 if not InCombat() FrostPrecombatCdActions()
 unless not InCombat() and FrostPrecombatCdPostConditions()
 {
  FrostDefaultCdActions()
 }
}

AddIcon checkbox=opt_mage_frost_aoe help=cd specialization=frost
{
 if not InCombat() FrostPrecombatCdActions()
 unless not InCombat() and FrostPrecombatCdPostConditions()
 {
  FrostDefaultCdActions()
 }
}

### Required symbols
# icy_veins
# fingers_of_frost_buff
# lady_vashjs_grasp
# icy_veins_buff
# freeze
# frozen_orb_debuff
# ice_nova
# winters_chill_debuff
# frostbolt
# water_elemental_water_jet
# brain_freeze_buff
# ray_of_frost
# rune_of_power_buff
# flurry
# ebonbolt
# glacial_spike
# glacial_spike_talent
# icicles_buff
# frozen_orb
# blizzard
# frost_bomb
# frost_bomb_debuff
# ice_lance
# comet_storm
# zannesu_journey_buff
# frozen_mass_buff
# water_elemental
# mirror_image
# prolonged_power_potion
# blink
# ice_floes
# ice_floes_buff
# rune_of_power
# blood_fury_sp
# berserking
# arcane_torrent_mana
# cone_of_cold
# time_warp
# shard_of_the_exodar
# quaking_palm
# counterspell
]]
    OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
end
