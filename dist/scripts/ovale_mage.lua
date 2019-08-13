local __exports = LibStub:NewLibrary("ovale/scripts/ovale_mage", 80201)
if not __exports then return end
__exports.registerMage = function(OvaleScripts)
    do
        local name = "sc_t23_mage_arcane"
        local desc = "[8.2] Simulationcraft: T23_Mage_Arcane"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Arcane".
#	class=mage
#	spec=arcane
#	talents=2032021

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

AddFunction conserve_mana
{
 60 + 20 * HasAzeriteTrait(equipoise_trait)
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=arcane)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=arcane)
AddCheckBox(opt_arcane_mage_burn_phase L(arcane_mage_burn_phase) default specialization=arcane)
AddCheckBox(opt_blink SpellName(blink) specialization=arcane)

AddFunction ArcaneInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
 }
}

AddFunction ArcaneUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.precombat

AddFunction ArcanePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 Spell(arcane_intellect)
 #arcane_familiar
 Spell(arcane_familiar)
 #arcane_blast
 if Mana() > ManaCost(arcane_blast) Spell(arcane_blast)
}

AddFunction ArcanePrecombatMainPostConditions
{
}

AddFunction ArcanePrecombatShortCdActions
{
}

AddFunction ArcanePrecombatShortCdPostConditions
{
 Spell(arcane_intellect) or Spell(arcane_familiar) or Mana() > ManaCost(arcane_blast) and Spell(arcane_blast)
}

AddFunction ArcanePrecombatCdActions
{
 unless Spell(arcane_intellect) or Spell(arcane_familiar)
 {
  #variable,name=conserve_mana,op=set,value=60+20*azerite.equipoise.enabled
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  ArcaneUseItemActions()
  #mirror_image
  Spell(mirror_image)
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_focused_resolve usable=1)
 }
}

AddFunction ArcanePrecombatCdPostConditions
{
 Spell(arcane_intellect) or Spell(arcane_familiar) or Mana() > ManaCost(arcane_blast) and Spell(arcane_blast)
}

### actions.movement

AddFunction ArcaneMovementMainActions
{
 #arcane_missiles
 Spell(arcane_missiles)
 #supernova
 Spell(supernova)
}

AddFunction ArcaneMovementMainPostConditions
{
}

AddFunction ArcaneMovementShortCdActions
{
 #blink_any,if=movement.distance>=10
 if target.Distance() >= 10 and CheckBoxOn(opt_blink) Spell(blink)
 #presence_of_mind
 Spell(presence_of_mind)

 unless Spell(arcane_missiles)
 {
  #arcane_orb
  Spell(arcane_orb)
 }
}

AddFunction ArcaneMovementShortCdPostConditions
{
 Spell(arcane_missiles) or Spell(supernova)
}

AddFunction ArcaneMovementCdActions
{
}

AddFunction ArcaneMovementCdPostConditions
{
 target.Distance() >= 10 and CheckBoxOn(opt_blink) and Spell(blink) or Spell(presence_of_mind) or Spell(arcane_missiles) or Spell(arcane_orb) or Spell(supernova)
}

### actions.essences

AddFunction ArcaneEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down&buff.arcane_power.down&(!burn_phase|time_to_die<cooldown.arcane_power.remains)&mana.time_to_max>=execute_time
 if TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and { not GetState(burn_phase) > 0 or target.TimeToDie() < SpellCooldown(arcane_power) } and TimeToMaxMana() >= ExecuteTime(concentrated_flame_essence) Spell(concentrated_flame_essence)
}

AddFunction ArcaneEssencesMainPostConditions
{
}

AddFunction ArcaneEssencesShortCdActions
{
 unless TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and { not GetState(burn_phase) > 0 or target.TimeToDie() < SpellCooldown(arcane_power) } and TimeToMaxMana() >= ExecuteTime(concentrated_flame_essence) and Spell(concentrated_flame_essence)
 {
  #focused_azerite_beam,if=buff.rune_of_power.down&buff.arcane_power.down
  if BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(focused_azerite_beam)
  #purifying_blast,if=buff.rune_of_power.down&buff.arcane_power.down
  if BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(purifying_blast)
  #ripple_in_space,if=buff.rune_of_power.down&buff.arcane_power.down
  if BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(ripple_in_space_essence)
  #the_unbound_force,if=buff.rune_of_power.down&buff.arcane_power.down
  if BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(the_unbound_force)
  #worldvein_resonance,if=burn_phase&buff.arcane_power.down&buff.rune_of_power.down&buff.arcane_charge.stack=buff.arcane_charge.max_stack|time_to_die<cooldown.arcane_power.remains
  if GetState(burn_phase) > 0 and BuffExpires(arcane_power_buff) and BuffExpires(rune_of_power_buff) and ArcaneCharges() == MaxArcaneCharges() or target.TimeToDie() < SpellCooldown(arcane_power) Spell(worldvein_resonance_essence)
 }
}

AddFunction ArcaneEssencesShortCdPostConditions
{
 TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and { not GetState(burn_phase) > 0 or target.TimeToDie() < SpellCooldown(arcane_power) } and TimeToMaxMana() >= ExecuteTime(concentrated_flame_essence) and Spell(concentrated_flame_essence)
}

AddFunction ArcaneEssencesCdActions
{
 #blood_of_the_enemy,if=burn_phase&buff.arcane_power.down&buff.rune_of_power.down&buff.arcane_charge.stack=buff.arcane_charge.max_stack|time_to_die<cooldown.arcane_power.remains
 if GetState(burn_phase) > 0 and BuffExpires(arcane_power_buff) and BuffExpires(rune_of_power_buff) and ArcaneCharges() == MaxArcaneCharges() or target.TimeToDie() < SpellCooldown(arcane_power) Spell(blood_of_the_enemy)

 unless TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and { not GetState(burn_phase) > 0 or target.TimeToDie() < SpellCooldown(arcane_power) } and TimeToMaxMana() >= ExecuteTime(concentrated_flame_essence) and Spell(concentrated_flame_essence) or BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(focused_azerite_beam)
 {
  #guardian_of_azeroth,if=buff.rune_of_power.down&buff.arcane_power.down
  if BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(guardian_of_azeroth)

  unless BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(purifying_blast) or BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(ripple_in_space_essence) or BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(the_unbound_force)
  {
   #memory_of_lucid_dreams,if=!burn_phase&buff.arcane_power.down&cooldown.arcane_power.remains&buff.arcane_charge.stack=buff.arcane_charge.max_stack&(!talent.rune_of_power.enabled|action.rune_of_power.charges)|time_to_die<cooldown.arcane_power.remains
   if not GetState(burn_phase) > 0 and BuffExpires(arcane_power_buff) and SpellCooldown(arcane_power) > 0 and ArcaneCharges() == MaxArcaneCharges() and { not Talent(rune_of_power_talent) or Charges(rune_of_power) } or target.TimeToDie() < SpellCooldown(arcane_power) Spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction ArcaneEssencesCdPostConditions
{
 TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and { not GetState(burn_phase) > 0 or target.TimeToDie() < SpellCooldown(arcane_power) } and TimeToMaxMana() >= ExecuteTime(concentrated_flame_essence) and Spell(concentrated_flame_essence) or BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(focused_azerite_beam) or BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(purifying_blast) or BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(ripple_in_space_essence) or BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(the_unbound_force) or { GetState(burn_phase) > 0 and BuffExpires(arcane_power_buff) and BuffExpires(rune_of_power_buff) and ArcaneCharges() == MaxArcaneCharges() or target.TimeToDie() < SpellCooldown(arcane_power) } and Spell(worldvein_resonance_essence)
}

### actions.conserve

AddFunction ArcaneConserveMainActions
{
 #charged_up,if=buff.arcane_charge.stack=0
 if ArcaneCharges() == 0 Spell(charged_up)
 #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.rune_of_power.down&buff.arcane_power.down
 if { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(nether_tempest)
 #arcane_blast,if=buff.rule_of_threes.up&buff.arcane_charge.stack>3
 if BuffPresent(rule_of_threes) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) Spell(arcane_blast)
 #arcane_missiles,if=mana.pct<=95&buff.clearcasting.react&active_enemies<3,chain=1
 if ManaPercent() <= 95 and BuffPresent(clearcasting_buff) and Enemies() < 3 Spell(arcane_missiles)
 #arcane_barrage,if=((buff.arcane_charge.stack=buff.arcane_charge.max_stack)&((mana.pct<=variable.conserve_mana)|(talent.rune_of_power.enabled&cooldown.arcane_power.remains>cooldown.rune_of_power.full_recharge_time&mana.pct<=variable.conserve_mana+25))|(talent.arcane_orb.enabled&cooldown.arcane_orb.remains<=gcd&cooldown.arcane_power.remains>10))|mana.pct<=(variable.conserve_mana-10)
 if ArcaneCharges() == MaxArcaneCharges() and { ManaPercent() <= conserve_mana() or Talent(rune_of_power_talent) and SpellCooldown(arcane_power) > SpellCooldown(rune_of_power) and ManaPercent() <= conserve_mana() + 25 } or Talent(arcane_orb_talent) and SpellCooldown(arcane_orb) <= GCD() and SpellCooldown(arcane_power) > 10 or ManaPercent() <= conserve_mana() - 10 Spell(arcane_barrage)
 #supernova,if=mana.pct<=95
 if ManaPercent() <= 95 Spell(supernova)
 #arcane_explosion,if=active_enemies>=3&(mana.pct>=variable.conserve_mana|buff.arcane_charge.stack=3)
 if Enemies() >= 3 and { ManaPercent() >= conserve_mana() or ArcaneCharges() == 3 } Spell(arcane_explosion)
 #arcane_blast
 if Mana() > ManaCost(arcane_blast) Spell(arcane_blast)
 #arcane_barrage
 Spell(arcane_barrage)
}

AddFunction ArcaneConserveMainPostConditions
{
}

AddFunction ArcaneConserveShortCdActions
{
 unless ArcaneCharges() == 0 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest)
 {
  #arcane_orb,if=buff.arcane_charge.stack<=2&(cooldown.arcane_power.remains>10|active_enemies<=2)
  if ArcaneCharges() <= 2 and { SpellCooldown(arcane_power) > 10 or Enemies() <= 2 } Spell(arcane_orb)

  unless BuffPresent(rule_of_threes) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast)
  {
   #rune_of_power,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&(full_recharge_time<=execute_time|full_recharge_time<=cooldown.arcane_power.remains|target.time_to_die<=cooldown.arcane_power.remains)
   if ArcaneCharges() == MaxArcaneCharges() and { SpellFullRecharge(rune_of_power) <= ExecuteTime(rune_of_power) or SpellFullRecharge(rune_of_power) <= SpellCooldown(arcane_power) or target.TimeToDie() <= SpellCooldown(arcane_power) } Spell(rune_of_power)
  }
 }
}

AddFunction ArcaneConserveShortCdPostConditions
{
 ArcaneCharges() == 0 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast) or ManaPercent() <= 95 and BuffPresent(clearcasting_buff) and Enemies() < 3 and Spell(arcane_missiles) or { ArcaneCharges() == MaxArcaneCharges() and { ManaPercent() <= conserve_mana() or Talent(rune_of_power_talent) and SpellCooldown(arcane_power) > SpellCooldown(rune_of_power) and ManaPercent() <= conserve_mana() + 25 } or Talent(arcane_orb_talent) and SpellCooldown(arcane_orb) <= GCD() and SpellCooldown(arcane_power) > 10 or ManaPercent() <= conserve_mana() - 10 } and Spell(arcane_barrage) or ManaPercent() <= 95 and Spell(supernova) or Enemies() >= 3 and { ManaPercent() >= conserve_mana() or ArcaneCharges() == 3 } and Spell(arcane_explosion) or Mana() > ManaCost(arcane_blast) and Spell(arcane_blast) or Spell(arcane_barrage)
}

AddFunction ArcaneConserveCdActions
{
 #mirror_image
 Spell(mirror_image)

 unless ArcaneCharges() == 0 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or ArcaneCharges() <= 2 and { SpellCooldown(arcane_power) > 10 or Enemies() <= 2 } and Spell(arcane_orb) or BuffPresent(rule_of_threes) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast)
 {
  #use_item,name=tidestorm_codex,if=buff.rune_of_power.down&!buff.arcane_power.react&cooldown.arcane_power.remains>20
  if BuffExpires(rune_of_power_buff) and not BuffPresent(arcane_power_buff) and SpellCooldown(arcane_power) > 20 ArcaneUseItemActions()
  #use_item,effect_name=cyclotronic_blast,if=buff.rune_of_power.down&!buff.arcane_power.react&cooldown.arcane_power.remains>20
  if BuffExpires(rune_of_power_buff) and not BuffPresent(arcane_power_buff) and SpellCooldown(arcane_power) > 20 ArcaneUseItemActions()
 }
}

AddFunction ArcaneConserveCdPostConditions
{
 ArcaneCharges() == 0 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or ArcaneCharges() <= 2 and { SpellCooldown(arcane_power) > 10 or Enemies() <= 2 } and Spell(arcane_orb) or BuffPresent(rule_of_threes) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast) or ArcaneCharges() == MaxArcaneCharges() and { SpellFullRecharge(rune_of_power) <= ExecuteTime(rune_of_power) or SpellFullRecharge(rune_of_power) <= SpellCooldown(arcane_power) or target.TimeToDie() <= SpellCooldown(arcane_power) } and Spell(rune_of_power) or ManaPercent() <= 95 and BuffPresent(clearcasting_buff) and Enemies() < 3 and Spell(arcane_missiles) or { ArcaneCharges() == MaxArcaneCharges() and { ManaPercent() <= conserve_mana() or Talent(rune_of_power_talent) and SpellCooldown(arcane_power) > SpellCooldown(rune_of_power) and ManaPercent() <= conserve_mana() + 25 } or Talent(arcane_orb_talent) and SpellCooldown(arcane_orb) <= GCD() and SpellCooldown(arcane_power) > 10 or ManaPercent() <= conserve_mana() - 10 } and Spell(arcane_barrage) or ManaPercent() <= 95 and Spell(supernova) or Enemies() >= 3 and { ManaPercent() >= conserve_mana() or ArcaneCharges() == 3 } and Spell(arcane_explosion) or Mana() > ManaCost(arcane_blast) and Spell(arcane_blast) or Spell(arcane_barrage)
}

### actions.burn

AddFunction ArcaneBurnMainActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not GetState(burn_phase) > 0 and not GetState(burn_phase) > 0 SetState(burn_phase 1)
 #stop_burn_phase,if=burn_phase&prev_gcd.1.evocation&target.time_to_die>variable.average_burn_length&burn_phase_duration>0
 if GetState(burn_phase) > 0 and PreviousGCDSpell(evocation) and target.TimeToDie() > average_burn_length() and GetStateDuration() > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)
 #charged_up,if=buff.arcane_charge.stack<=1
 if ArcaneCharges() <= 1 Spell(charged_up)
 #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.rune_of_power.down&buff.arcane_power.down
 if { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(nether_tempest)
 #arcane_blast,if=buff.rule_of_threes.up&talent.overpowered.enabled&active_enemies<3
 if BuffPresent(rule_of_threes) and Talent(overpowered_talent) and Enemies() < 3 and Mana() > ManaCost(arcane_blast) Spell(arcane_blast)
 #arcane_barrage,if=active_enemies>=3&(buff.arcane_charge.stack=buff.arcane_charge.max_stack)
 if Enemies() >= 3 and ArcaneCharges() == MaxArcaneCharges() Spell(arcane_barrage)
 #arcane_explosion,if=active_enemies>=3
 if Enemies() >= 3 Spell(arcane_explosion)
 #arcane_missiles,if=buff.clearcasting.react&active_enemies<3&(talent.amplification.enabled|(!talent.overpowered.enabled&azerite.arcane_pummeling.rank>=2)|buff.arcane_power.down),chain=1
 if BuffPresent(clearcasting_buff) and Enemies() < 3 and { Talent(amplification_talent) or not Talent(overpowered_talent) and AzeriteTraitRank(arcane_pummeling_trait) >= 2 or BuffExpires(arcane_power_buff) } Spell(arcane_missiles)
 #arcane_blast,if=active_enemies<3
 if Enemies() < 3 and Mana() > ManaCost(arcane_blast) Spell(arcane_blast)
 #arcane_barrage
 Spell(arcane_barrage)
}

AddFunction ArcaneBurnMainPostConditions
{
}

AddFunction ArcaneBurnShortCdActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not GetState(burn_phase) > 0 and not GetState(burn_phase) > 0 SetState(burn_phase 1)
 #stop_burn_phase,if=burn_phase&prev_gcd.1.evocation&target.time_to_die>variable.average_burn_length&burn_phase_duration>0
 if GetState(burn_phase) > 0 and PreviousGCDSpell(evocation) and target.TimeToDie() > average_burn_length() and GetStateDuration() > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)

 unless ArcaneCharges() <= 1 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes) and Talent(overpowered_talent) and Enemies() < 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast)
 {
  #rune_of_power,if=!buff.arcane_power.up&(mana.pct>=50|cooldown.arcane_power.remains=0)&(buff.arcane_charge.stack=buff.arcane_charge.max_stack)
  if not BuffPresent(arcane_power_buff) and { ManaPercent() >= 50 or not SpellCooldown(arcane_power) > 0 } and ArcaneCharges() == MaxArcaneCharges() Spell(rune_of_power)
  #presence_of_mind,if=(talent.rune_of_power.enabled&buff.rune_of_power.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time)|buff.arcane_power.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time
  if Talent(rune_of_power_talent) and TotemRemaining(rune_of_power) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) or BuffRemaining(arcane_power_buff) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) Spell(presence_of_mind)
  #arcane_orb,if=buff.arcane_charge.stack=0|(active_enemies<3|(active_enemies<2&talent.resonance.enabled))
  if ArcaneCharges() == 0 or Enemies() < 3 or Enemies() < 2 and Talent(resonance_talent) Spell(arcane_orb)
 }
}

AddFunction ArcaneBurnShortCdPostConditions
{
 ArcaneCharges() <= 1 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes) and Talent(overpowered_talent) and Enemies() < 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast) or Enemies() >= 3 and ArcaneCharges() == MaxArcaneCharges() and Spell(arcane_barrage) or Enemies() >= 3 and Spell(arcane_explosion) or BuffPresent(clearcasting_buff) and Enemies() < 3 and { Talent(amplification_talent) or not Talent(overpowered_talent) and AzeriteTraitRank(arcane_pummeling_trait) >= 2 or BuffExpires(arcane_power_buff) } and Spell(arcane_missiles) or Enemies() < 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast) or Spell(arcane_barrage)
}

AddFunction ArcaneBurnCdActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not GetState(burn_phase) > 0 and not GetState(burn_phase) > 0 SetState(burn_phase 1)
 #stop_burn_phase,if=burn_phase&prev_gcd.1.evocation&target.time_to_die>variable.average_burn_length&burn_phase_duration>0
 if GetState(burn_phase) > 0 and PreviousGCDSpell(evocation) and target.TimeToDie() > average_burn_length() and GetStateDuration() > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)

 unless ArcaneCharges() <= 1 and Spell(charged_up)
 {
  #mirror_image
  Spell(mirror_image)

  unless { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes) and Talent(overpowered_talent) and Enemies() < 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast)
  {
   #lights_judgment,if=buff.arcane_power.down
   if BuffExpires(arcane_power_buff) Spell(lights_judgment)
   #use_item,name=azsharas_font_of_power,if=cooldown.arcane_power.remains<5|time_to_die<cooldown.arcane_power.remains
   if SpellCooldown(arcane_power) < 5 or target.TimeToDie() < SpellCooldown(arcane_power) ArcaneUseItemActions()

   unless not BuffPresent(arcane_power_buff) and { ManaPercent() >= 50 or not SpellCooldown(arcane_power) > 0 } and ArcaneCharges() == MaxArcaneCharges() and Spell(rune_of_power)
   {
    #berserking
    Spell(berserking)
    #arcane_power
    Spell(arcane_power)
    #use_items,if=buff.arcane_power.up|target.time_to_die<cooldown.arcane_power.remains
    if BuffPresent(arcane_power_buff) or target.TimeToDie() < SpellCooldown(arcane_power) ArcaneUseItemActions()
    #blood_fury
    Spell(blood_fury_sp)
    #fireblood
    Spell(fireblood)
    #ancestral_call
    Spell(ancestral_call)

    unless { Talent(rune_of_power_talent) and TotemRemaining(rune_of_power) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) or BuffRemaining(arcane_power_buff) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) } and Spell(presence_of_mind)
    {
     #potion,if=buff.arcane_power.up&(buff.berserking.up|buff.blood_fury.up|!(race.troll|race.orc))
     if BuffPresent(arcane_power_buff) and { BuffPresent(berserking_buff) or BuffPresent(blood_fury_sp_buff) or not { Race(Troll) or Race(Orc) } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_focused_resolve usable=1)

     unless { ArcaneCharges() == 0 or Enemies() < 3 or Enemies() < 2 and Talent(resonance_talent) } and Spell(arcane_orb) or Enemies() >= 3 and ArcaneCharges() == MaxArcaneCharges() and Spell(arcane_barrage) or Enemies() >= 3 and Spell(arcane_explosion) or BuffPresent(clearcasting_buff) and Enemies() < 3 and { Talent(amplification_talent) or not Talent(overpowered_talent) and AzeriteTraitRank(arcane_pummeling_trait) >= 2 or BuffExpires(arcane_power_buff) } and Spell(arcane_missiles) or Enemies() < 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast)
     {
      #variable,name=average_burn_length,op=set,value=(variable.average_burn_length*variable.total_burns-variable.average_burn_length+(burn_phase_duration))%variable.total_burns
      #evocation,interrupt_if=mana.pct>=85,interrupt_immediate=1
      Spell(evocation)
     }
    }
   }
  }
 }
}

AddFunction ArcaneBurnCdPostConditions
{
 ArcaneCharges() <= 1 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes) and Talent(overpowered_talent) and Enemies() < 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast) or not BuffPresent(arcane_power_buff) and { ManaPercent() >= 50 or not SpellCooldown(arcane_power) > 0 } and ArcaneCharges() == MaxArcaneCharges() and Spell(rune_of_power) or { Talent(rune_of_power_talent) and TotemRemaining(rune_of_power) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) or BuffRemaining(arcane_power_buff) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) } and Spell(presence_of_mind) or { ArcaneCharges() == 0 or Enemies() < 3 or Enemies() < 2 and Talent(resonance_talent) } and Spell(arcane_orb) or Enemies() >= 3 and ArcaneCharges() == MaxArcaneCharges() and Spell(arcane_barrage) or Enemies() >= 3 and Spell(arcane_explosion) or BuffPresent(clearcasting_buff) and Enemies() < 3 and { Talent(amplification_talent) or not Talent(overpowered_talent) and AzeriteTraitRank(arcane_pummeling_trait) >= 2 or BuffExpires(arcane_power_buff) } and Spell(arcane_missiles) or Enemies() < 3 and Mana() > ManaCost(arcane_blast) and Spell(arcane_blast) or Spell(arcane_barrage)
}

### actions.default

AddFunction ArcaneDefaultMainActions
{
 #call_action_list,name=essences
 ArcaneEssencesMainActions()

 unless ArcaneEssencesMainPostConditions()
 {
  #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
  if { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnMainActions()

  unless { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions()
  {
   #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
   if not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnMainActions()

   unless not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions()
   {
    #call_action_list,name=conserve,if=!burn_phase
    if not GetState(burn_phase) > 0 ArcaneConserveMainActions()

    unless not GetState(burn_phase) > 0 and ArcaneConserveMainPostConditions()
    {
     #call_action_list,name=movement
     ArcaneMovementMainActions()
    }
   }
  }
 }
}

AddFunction ArcaneDefaultMainPostConditions
{
 ArcaneEssencesMainPostConditions() or { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions() or not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnMainPostConditions() or not GetState(burn_phase) > 0 and ArcaneConserveMainPostConditions() or ArcaneMovementMainPostConditions()
}

AddFunction ArcaneDefaultShortCdActions
{
 #call_action_list,name=essences
 ArcaneEssencesShortCdActions()

 unless ArcaneEssencesShortCdPostConditions()
 {
  #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
  if { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnShortCdActions()

  unless { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions()
  {
   #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
   if not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnShortCdActions()

   unless not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions()
   {
    #call_action_list,name=conserve,if=!burn_phase
    if not GetState(burn_phase) > 0 ArcaneConserveShortCdActions()

    unless not GetState(burn_phase) > 0 and ArcaneConserveShortCdPostConditions()
    {
     #call_action_list,name=movement
     ArcaneMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction ArcaneDefaultShortCdPostConditions
{
 ArcaneEssencesShortCdPostConditions() or { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions() or not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnShortCdPostConditions() or not GetState(burn_phase) > 0 and ArcaneConserveShortCdPostConditions() or ArcaneMovementShortCdPostConditions()
}

AddFunction ArcaneDefaultCdActions
{
 #counterspell
 ArcaneInterruptActions()
 #call_action_list,name=essences
 ArcaneEssencesCdActions()

 unless ArcaneEssencesCdPostConditions()
 {
  #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
  if { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnCdActions()

  unless { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions()
  {
   #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
   if not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) ArcaneBurnCdActions()

   unless not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions()
   {
    #call_action_list,name=conserve,if=!burn_phase
    if not GetState(burn_phase) > 0 ArcaneConserveCdActions()

    unless not GetState(burn_phase) > 0 and ArcaneConserveCdPostConditions()
    {
     #call_action_list,name=movement
     ArcaneMovementCdActions()
    }
   }
  }
 }
}

AddFunction ArcaneDefaultCdPostConditions
{
 ArcaneEssencesCdPostConditions() or { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions() or not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and CheckBoxOn(opt_arcane_mage_burn_phase) and ArcaneBurnCdPostConditions() or not GetState(burn_phase) > 0 and ArcaneConserveCdPostConditions() or ArcaneMovementCdPostConditions()
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
# amplification_talent
# ancestral_call
# arcane_barrage
# arcane_blast
# arcane_explosion
# arcane_familiar
# arcane_intellect
# arcane_missiles
# arcane_orb
# arcane_orb_talent
# arcane_power
# arcane_power_buff
# arcane_pummeling_trait
# berserking
# berserking_buff
# blink
# blood_fury_sp
# blood_fury_sp_buff
# blood_of_the_enemy
# charged_up
# charged_up_talent
# clearcasting_buff
# concentrated_flame_essence
# counterspell
# equipoise_trait
# evocation
# fireblood
# focused_azerite_beam
# guardian_of_azeroth
# item_focused_resolve
# lights_judgment
# memory_of_lucid_dreams_essence
# mirror_image
# nether_tempest
# nether_tempest_debuff
# overpowered_talent
# presence_of_mind
# presence_of_mind_buff
# purifying_blast
# quaking_palm
# resonance_talent
# ripple_in_space_essence
# rule_of_threes
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# supernova
# the_unbound_force
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "arcane", name, desc, code, "script")
    end
    do
        local name = "sc_t23_mage_fire"
        local desc = "[8.2] Simulationcraft: T23_Mage_Fire"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Fire".
#	class=mage
#	spec=fire
#	talents=3031022

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)


AddFunction phoenix_pooling
{
 Talent(rune_of_power_talent) and SpellCooldown(rune_of_power) < SpellCooldown(phoenix_flames) and SpellCooldown(combustion) > combustion_rop_cutoff() and { SpellCooldown(rune_of_power) < target.TimeToDie() or Charges(rune_of_power) > 0 } or SpellCooldown(combustion) < SpellFullRecharge(phoenix_flames) and SpellCooldown(combustion) < target.TimeToDie()
}

AddFunction fire_blast_pooling
{
 Talent(rune_of_power_talent) and SpellCooldown(rune_of_power) < SpellCooldown(fire_blast) and { SpellCooldown(combustion) > combustion_rop_cutoff() or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and { SpellCooldown(rune_of_power) < target.TimeToDie() or Charges(rune_of_power) > 0 } or SpellCooldown(combustion) < SpellFullRecharge(fire_blast) + SpellCooldownDuration(fire_blast) * HasAzeriteTrait(blaster_master_trait) and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } and SpellCooldown(combustion) < target.TimeToDie() or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 and target.TimeToHealthPercent(90) < SpellCooldown(fire_blast) + SpellCooldownDuration(fire_blast) * HasAzeriteTrait(blaster_master_trait)
}

AddFunction on_use_cutoff
{
 20 * combustion_on_use() and not font_double_on_use() + 40 * font_double_on_use() + 25 * HasEquippedItem(azsharas_font_of_power_item) and not font_double_on_use()
}

AddFunction font_double_on_use
{
 HasEquippedItem(azsharas_font_of_power_item) and combustion_on_use()
}

AddFunction combustion_on_use
{
 HasEquippedItem(notorious_aspirants_badge_item) or HasEquippedItem(notorious_gladiators_badge_item) or HasEquippedItem(sinister_gladiators_badge_item) or HasEquippedItem(sinister_aspirants_badge_item) or HasEquippedItem(dread_gladiators_badge_item) or HasEquippedItem(dread_aspirants_badge_item) or HasEquippedItem(dread_combatants_insignia_item) or HasEquippedItem(notorious_aspirants_medallion_item) or HasEquippedItem(notorious_gladiators_medallion_item) or HasEquippedItem(sinister_gladiators_medallion_item) or HasEquippedItem(sinister_aspirants_medallion_item) or HasEquippedItem(dread_gladiators_medallion_item) or HasEquippedItem(dread_aspirants_medallion_item) or HasEquippedItem(dread_combatants_medallion_item) or HasEquippedItem(ignition_mages_fuse_item) or HasEquippedItem(tzanes_barkspines_item) or HasEquippedItem(azurethos_singed_plumage_item) or HasEquippedItem(ancient_knot_of_wisdom_item) or HasEquippedItem(shockbiters_fang_item) or HasEquippedItem(neural_synapse_enhancer_item) or HasEquippedItem(balefire_branch_item)
}

AddFunction combustion_rop_cutoff
{
 60
}

AddCheckBox(opt_interrupt L(interrupt) default specialization=fire)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=fire)

AddFunction FireInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
 }
}

AddFunction FireUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.standard_rotation

AddFunction FireStandardrotationMainActions
{
 #flamestrike,if=((talent.flame_patch.enabled&active_enemies>1&!firestarter.active)|active_enemies>4)&buff.hot_streak.react
 if { Talent(flame_patch_talent) and Enemies() > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() > 4 } and BuffPresent(hot_streak_buff) Spell(flamestrike)
 #pyroblast,if=buff.hot_streak.react&buff.hot_streak.remains<action.fireball.execute_time
 if BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) Spell(pyroblast)
 #pyroblast,if=buff.hot_streak.react&(prev_gcd.1.fireball|firestarter.active|action.pyroblast.in_flight)
 if BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } Spell(pyroblast)
 #phoenix_flames,if=charges>=3&active_enemies>2&!variable.phoenix_pooling
 if Charges(phoenix_flames) >= 3 and Enemies() > 2 and not phoenix_pooling() Spell(phoenix_flames)
 #pyroblast,if=buff.hot_streak.react&target.health.pct<=30&talent.searing_touch.enabled
 if BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(pyroblast)
 #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains
 if BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) Spell(pyroblast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=(cooldown.combustion.remains>0&buff.rune_of_power.down|firestarter.active)&!talent.kindling.enabled&!variable.fire_blast_pooling&(((action.fireball.executing|action.pyroblast.executing)&(buff.heating_up.react|firestarter.active&!buff.hot_streak.react&!buff.heating_up.react))|(talent.searing_touch.enabled&target.health.pct<=30&(buff.heating_up.react&!action.scorch.executing|!buff.hot_streak.react&!buff.heating_up.react&action.scorch.executing&!action.pyroblast.in_flight&!action.fireball.in_flight))|(firestarter.active&(action.pyroblast.in_flight|action.fireball.in_flight)&!buff.heating_up.react&!buff.hot_streak.react))
 if { SpellCooldown(combustion) > 0 and BuffExpires(rune_of_power_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and not Talent(kindling_talent) and not fire_blast_pooling() and { { ExecuteTime(fireball) > 0 or ExecuteTime(pyroblast) > 0 } and { BuffPresent(heating_up_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 and not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) } or Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) and ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } or Talent(firestarter_talent) and target.HealthPercent() >= 90 and { InFlightToTarget(pyroblast) or InFlightToTarget(fireball) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } Spell(fire_blast)
 #fire_blast,if=talent.kindling.enabled&buff.heating_up.react&(cooldown.combustion.remains>full_recharge_time+2+talent.kindling.enabled|firestarter.remains>full_recharge_time|(!talent.rune_of_power.enabled|cooldown.rune_of_power.remains>target.time_to_die&action.rune_of_power.charges<1)&cooldown.combustion.remains>target.time_to_die)
 if Talent(kindling_talent) and BuffPresent(heating_up_buff) and { SpellCooldown(combustion) > SpellFullRecharge(fire_blast) + 2 + TalentPoints(kindling_talent) or target.TimeToHealthPercent(90) > SpellFullRecharge(fire_blast) or { not Talent(rune_of_power_talent) or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 } and SpellCooldown(combustion) > target.TimeToDie() } Spell(fire_blast)
 #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up&talent.searing_touch.enabled&target.health.pct<=30&((talent.flame_patch.enabled&active_enemies=1&!firestarter.active)|(active_enemies<4&!talent.flame_patch.enabled))
 if PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies() == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() < 4 and not Talent(flame_patch_talent) } Spell(pyroblast)
 #phoenix_flames,if=(buff.heating_up.react|(!buff.hot_streak.react&(action.fire_blast.charges>0|talent.searing_touch.enabled&target.health.pct<=30)))&!variable.phoenix_pooling
 if { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() Spell(phoenix_flames)
 #call_action_list,name=active_talents
 FireActivetalentsMainActions()

 unless FireActivetalentsMainPostConditions()
 {
  #call_action_list,name=items_low_priority
  FireItemslowpriorityMainActions()

  unless FireItemslowpriorityMainPostConditions()
  {
   #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
   if target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(scorch)
   #fireball
   Spell(fireball)
   #scorch
   Spell(scorch)
  }
 }
}

AddFunction FireStandardrotationMainPostConditions
{
 FireActivetalentsMainPostConditions() or FireItemslowpriorityMainPostConditions()
}

AddFunction FireStandardrotationShortCdActions
{
 unless { Talent(flame_patch_talent) and Enemies() > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or Charges(phoenix_flames) >= 3 and Enemies() > 2 and not phoenix_pooling() and Spell(phoenix_flames) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 and BuffExpires(rune_of_power_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and not Talent(kindling_talent) and not fire_blast_pooling() and { { ExecuteTime(fireball) > 0 or ExecuteTime(pyroblast) > 0 } and { BuffPresent(heating_up_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 and not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) } or Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) and ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } or Talent(firestarter_talent) and target.HealthPercent() >= 90 and { InFlightToTarget(pyroblast) or InFlightToTarget(fireball) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } and Spell(fire_blast) or Talent(kindling_talent) and BuffPresent(heating_up_buff) and { SpellCooldown(combustion) > SpellFullRecharge(fire_blast) + 2 + TalentPoints(kindling_talent) or target.TimeToHealthPercent(90) > SpellFullRecharge(fire_blast) or { not Talent(rune_of_power_talent) or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 } and SpellCooldown(combustion) > target.TimeToDie() } and Spell(fire_blast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies() == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames)
 {
  #call_action_list,name=active_talents
  FireActivetalentsShortCdActions()

  unless FireActivetalentsShortCdPostConditions()
  {
   #dragons_breath,if=active_enemies>1
   if Enemies() > 1 and target.Distance(less 12) Spell(dragons_breath)
   #call_action_list,name=items_low_priority
   FireItemslowpriorityShortCdActions()
  }
 }
}

AddFunction FireStandardrotationShortCdPostConditions
{
 { Talent(flame_patch_talent) and Enemies() > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or Charges(phoenix_flames) >= 3 and Enemies() > 2 and not phoenix_pooling() and Spell(phoenix_flames) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 and BuffExpires(rune_of_power_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and not Talent(kindling_talent) and not fire_blast_pooling() and { { ExecuteTime(fireball) > 0 or ExecuteTime(pyroblast) > 0 } and { BuffPresent(heating_up_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 and not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) } or Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) and ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } or Talent(firestarter_talent) and target.HealthPercent() >= 90 and { InFlightToTarget(pyroblast) or InFlightToTarget(fireball) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } and Spell(fire_blast) or Talent(kindling_talent) and BuffPresent(heating_up_buff) and { SpellCooldown(combustion) > SpellFullRecharge(fire_blast) + 2 + TalentPoints(kindling_talent) or target.TimeToHealthPercent(90) > SpellFullRecharge(fire_blast) or { not Talent(rune_of_power_talent) or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 } and SpellCooldown(combustion) > target.TimeToDie() } and Spell(fire_blast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies() == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames) or FireActivetalentsShortCdPostConditions() or FireItemslowpriorityShortCdPostConditions() or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Spell(fireball) or Spell(scorch)
}

AddFunction FireStandardrotationCdActions
{
 unless { Talent(flame_patch_talent) and Enemies() > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or Charges(phoenix_flames) >= 3 and Enemies() > 2 and not phoenix_pooling() and Spell(phoenix_flames) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 and BuffExpires(rune_of_power_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and not Talent(kindling_talent) and not fire_blast_pooling() and { { ExecuteTime(fireball) > 0 or ExecuteTime(pyroblast) > 0 } and { BuffPresent(heating_up_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 and not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) } or Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) and ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } or Talent(firestarter_talent) and target.HealthPercent() >= 90 and { InFlightToTarget(pyroblast) or InFlightToTarget(fireball) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } and Spell(fire_blast) or Talent(kindling_talent) and BuffPresent(heating_up_buff) and { SpellCooldown(combustion) > SpellFullRecharge(fire_blast) + 2 + TalentPoints(kindling_talent) or target.TimeToHealthPercent(90) > SpellFullRecharge(fire_blast) or { not Talent(rune_of_power_talent) or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 } and SpellCooldown(combustion) > target.TimeToDie() } and Spell(fire_blast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies() == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames)
 {
  #call_action_list,name=active_talents
  FireActivetalentsCdActions()

  unless FireActivetalentsCdPostConditions() or Enemies() > 1 and target.Distance(less 12) and Spell(dragons_breath)
  {
   #call_action_list,name=items_low_priority
   FireItemslowpriorityCdActions()
  }
 }
}

AddFunction FireStandardrotationCdPostConditions
{
 { Talent(flame_patch_talent) and Enemies() > 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and BuffRemaining(hot_streak_buff) < ExecuteTime(fireball) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and { PreviousGCDSpell(fireball) or Talent(firestarter_talent) and target.HealthPercent() >= 90 or InFlightToTarget(pyroblast) } and Spell(pyroblast) or Charges(phoenix_flames) >= 3 and Enemies() > 2 and not phoenix_pooling() and Spell(phoenix_flames) or BuffPresent(hot_streak_buff) and target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(pyroblast) or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 and BuffExpires(rune_of_power_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 } and not Talent(kindling_talent) and not fire_blast_pooling() and { { ExecuteTime(fireball) > 0 or ExecuteTime(pyroblast) > 0 } and { BuffPresent(heating_up_buff) or Talent(firestarter_talent) and target.HealthPercent() >= 90 and not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) } or Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(hot_streak_buff) and not BuffPresent(heating_up_buff) and ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } or Talent(firestarter_talent) and target.HealthPercent() >= 90 and { InFlightToTarget(pyroblast) or InFlightToTarget(fireball) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } and Spell(fire_blast) or Talent(kindling_talent) and BuffPresent(heating_up_buff) and { SpellCooldown(combustion) > SpellFullRecharge(fire_blast) + 2 + TalentPoints(kindling_talent) or target.TimeToHealthPercent(90) > SpellFullRecharge(fire_blast) or { not Talent(rune_of_power_talent) or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 } and SpellCooldown(combustion) > target.TimeToDie() } and Spell(fire_blast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { Talent(flame_patch_talent) and Enemies() == 1 and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or Enemies() < 4 and not Talent(flame_patch_talent) } and Spell(pyroblast) or { BuffPresent(heating_up_buff) or not BuffPresent(hot_streak_buff) and { Charges(fire_blast) > 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 } } and not phoenix_pooling() and Spell(phoenix_flames) or FireActivetalentsCdPostConditions() or Enemies() > 1 and target.Distance(less 12) and Spell(dragons_breath) or FireItemslowpriorityCdPostConditions() or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Spell(fireball) or Spell(scorch)
}

### actions.rop_phase

AddFunction FireRopphaseMainActions
{
 #flamestrike,if=((talent.flame_patch.enabled&active_enemies>1)|active_enemies>4)&buff.hot_streak.react
 if { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 4 } and BuffPresent(hot_streak_buff) Spell(flamestrike)
 #pyroblast,if=buff.hot_streak.react
 if BuffPresent(hot_streak_buff) Spell(pyroblast)
 #fire_blast,use_off_gcd=1,use_while_casting=1,if=(cooldown.combustion.remains>0|firestarter.active&buff.rune_of_power.up)&(!buff.heating_up.react&!buff.hot_streak.react&!prev_off_gcd.fire_blast&(action.fire_blast.charges>=2|(action.phoenix_flames.charges>=1&talent.phoenix_flames.enabled)|(talent.alexstraszas_fury.enabled&cooldown.dragons_breath.ready)|(talent.searing_touch.enabled&target.health.pct<=30)|(talent.firestarter.enabled&firestarter.active)))
 if { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and not PreviousOffGCDSpell(fire_blast) and { Charges(fire_blast) >= 2 or Charges(phoenix_flames) >= 1 and Talent(phoenix_flames_talent) or Talent(alexstraszas_fury_talent) and SpellCooldown(dragons_breath) == 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 } Spell(fire_blast)
 #call_action_list,name=active_talents
 FireActivetalentsMainActions()

 unless FireActivetalentsMainPostConditions()
 {
  #pyroblast,if=buff.pyroclasm.react&cast_time<buff.pyroclasm.remains&buff.rune_of_power.remains>cast_time
  if BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) Spell(pyroblast)
  #fire_blast,use_off_gcd=1,use_while_casting=1,if=(cooldown.combustion.remains>0|firestarter.active&buff.rune_of_power.up)&(buff.heating_up.react&(target.health.pct>=30|!talent.searing_touch.enabled))
  if { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and BuffPresent(heating_up_buff) and { target.HealthPercent() >= 30 or not Talent(searing_touch_talent) } Spell(fire_blast)
  #fire_blast,use_off_gcd=1,use_while_casting=1,if=(cooldown.combustion.remains>0|firestarter.active&buff.rune_of_power.up)&talent.searing_touch.enabled&target.health.pct<=30&(buff.heating_up.react&!action.scorch.executing|!buff.heating_up.react&!buff.hot_streak.react)
  if { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } Spell(fire_blast)
  #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up&talent.searing_touch.enabled&target.health.pct<=30&(!talent.flame_patch.enabled|active_enemies=1)
  if PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies() == 1 } Spell(pyroblast)
  #phoenix_flames,if=!prev_gcd.1.phoenix_flames&buff.heating_up.react
  if not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) Spell(phoenix_flames)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(scorch)
  #flamestrike,if=(talent.flame_patch.enabled&active_enemies>2)|active_enemies>5
  if Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 5 Spell(flamestrike)
  #fireball
  Spell(fireball)
 }
}

AddFunction FireRopphaseMainPostConditions
{
 FireActivetalentsMainPostConditions()
}

AddFunction FireRopphaseShortCdActions
{
 #rune_of_power
 Spell(rune_of_power)

 unless { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and not PreviousOffGCDSpell(fire_blast) and { Charges(fire_blast) >= 2 or Charges(phoenix_flames) >= 1 and Talent(phoenix_flames_talent) or Talent(alexstraszas_fury_talent) and SpellCooldown(dragons_breath) == 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 } and Spell(fire_blast)
 {
  #call_action_list,name=active_talents
  FireActivetalentsShortCdActions()

  unless FireActivetalentsShortCdPostConditions() or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and BuffPresent(heating_up_buff) and { target.HealthPercent() >= 30 or not Talent(searing_touch_talent) } and Spell(fire_blast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } and Spell(fire_blast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies() == 1 } and Spell(pyroblast) or not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) and Spell(phoenix_flames) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch)
  {
   #dragons_breath,if=active_enemies>2
   if Enemies() > 2 and target.Distance(less 12) Spell(dragons_breath)
  }
 }
}

AddFunction FireRopphaseShortCdPostConditions
{
 { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and not PreviousOffGCDSpell(fire_blast) and { Charges(fire_blast) >= 2 or Charges(phoenix_flames) >= 1 and Talent(phoenix_flames_talent) or Talent(alexstraszas_fury_talent) and SpellCooldown(dragons_breath) == 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 } and Spell(fire_blast) or FireActivetalentsShortCdPostConditions() or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and BuffPresent(heating_up_buff) and { target.HealthPercent() >= 30 or not Talent(searing_touch_talent) } and Spell(fire_blast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } and Spell(fire_blast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies() == 1 } and Spell(pyroblast) or not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) and Spell(phoenix_flames) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 5 } and Spell(flamestrike) or Spell(fireball)
}

AddFunction FireRopphaseCdActions
{
 unless Spell(rune_of_power) or { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and not PreviousOffGCDSpell(fire_blast) and { Charges(fire_blast) >= 2 or Charges(phoenix_flames) >= 1 and Talent(phoenix_flames_talent) or Talent(alexstraszas_fury_talent) and SpellCooldown(dragons_breath) == 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 } and Spell(fire_blast)
 {
  #call_action_list,name=active_talents
  FireActivetalentsCdActions()
 }
}

AddFunction FireRopphaseCdPostConditions
{
 Spell(rune_of_power) or { Talent(flame_patch_talent) and Enemies() > 1 or Enemies() > 4 } and BuffPresent(hot_streak_buff) and Spell(flamestrike) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and not PreviousOffGCDSpell(fire_blast) and { Charges(fire_blast) >= 2 or Charges(phoenix_flames) >= 1 and Talent(phoenix_flames_talent) or Talent(alexstraszas_fury_talent) and SpellCooldown(dragons_breath) == 0 or Talent(searing_touch_talent) and target.HealthPercent() <= 30 or Talent(firestarter_talent) and Talent(firestarter_talent) and target.HealthPercent() >= 90 } and Spell(fire_blast) or FireActivetalentsCdPostConditions() or BuffPresent(pyroclasm) and CastTime(pyroblast) < BuffRemaining(pyroclasm) and TotemRemaining(rune_of_power) > CastTime(pyroblast) and Spell(pyroblast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and BuffPresent(heating_up_buff) and { target.HealthPercent() >= 30 or not Talent(searing_touch_talent) } and Spell(fire_blast) or { SpellCooldown(combustion) > 0 or Talent(firestarter_talent) and target.HealthPercent() >= 90 and BuffPresent(rune_of_power_buff) } and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { BuffPresent(heating_up_buff) and not ExecuteTime(scorch) > 0 or not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) } and Spell(fire_blast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Talent(searing_touch_talent) and target.HealthPercent() <= 30 and { not Talent(flame_patch_talent) or Enemies() == 1 } and Spell(pyroblast) or not PreviousGCDSpell(phoenix_flames) and BuffPresent(heating_up_buff) and Spell(phoenix_flames) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch) or Enemies() > 2 and target.Distance(less 12) and Spell(dragons_breath) or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 5 } and Spell(flamestrike) or Spell(fireball)
}

### actions.precombat

AddFunction FirePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 Spell(arcane_intellect)
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
 Spell(arcane_intellect) or Spell(pyroblast)
}

AddFunction FirePrecombatCdActions
{
 unless Spell(arcane_intellect)
 {
  #variable,name=combustion_rop_cutoff,op=set,value=60
  #variable,name=combustion_on_use,op=set,value=equipped.notorious_aspirants_badge|equipped.notorious_gladiators_badge|equipped.sinister_gladiators_badge|equipped.sinister_aspirants_badge|equipped.dread_gladiators_badge|equipped.dread_aspirants_badge|equipped.dread_combatants_insignia|equipped.notorious_aspirants_medallion|equipped.notorious_gladiators_medallion|equipped.sinister_gladiators_medallion|equipped.sinister_aspirants_medallion|equipped.dread_gladiators_medallion|equipped.dread_aspirants_medallion|equipped.dread_combatants_medallion|equipped.ignition_mages_fuse|equipped.tzanes_barkspines|equipped.azurethos_singed_plumage|equipped.ancient_knot_of_wisdom|equipped.shockbiters_fang|equipped.neural_synapse_enhancer|equipped.balefire_branch
  #variable,name=font_double_on_use,op=set,value=equipped.azsharas_font_of_power&variable.combustion_on_use
  #variable,name=on_use_cutoff,op=set,value=20*variable.combustion_on_use&!variable.font_double_on_use+40*variable.font_double_on_use+25*equipped.azsharas_font_of_power&!variable.font_double_on_use
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  FireUseItemActions()
  #mirror_image
  Spell(mirror_image)
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 }
}

AddFunction FirePrecombatCdPostConditions
{
 Spell(arcane_intellect) or Spell(pyroblast)
}

### actions.items_low_priority

AddFunction FireItemslowpriorityMainActions
{
}

AddFunction FireItemslowpriorityMainPostConditions
{
}

AddFunction FireItemslowpriorityShortCdActions
{
}

AddFunction FireItemslowpriorityShortCdPostConditions
{
}

AddFunction FireItemslowpriorityCdActions
{
 #use_item,name=tidestorm_codex,if=cooldown.combustion.remains>variable.on_use_cutoff|talent.firestarter.enabled&firestarter.remains>variable.on_use_cutoff
 if SpellCooldown(combustion) > on_use_cutoff() or Talent(firestarter_talent) and target.TimeToHealthPercent(90) > on_use_cutoff() FireUseItemActions()
 #use_item,effect_name=cyclotronic_blast,if=cooldown.combustion.remains>variable.on_use_cutoff|talent.firestarter.enabled&firestarter.remains>variable.on_use_cutoff
 if SpellCooldown(combustion) > on_use_cutoff() or Talent(firestarter_talent) and target.TimeToHealthPercent(90) > on_use_cutoff() FireUseItemActions()
}

AddFunction FireItemslowpriorityCdPostConditions
{
}

### actions.items_high_priority

AddFunction FireItemshighpriorityMainActions
{
 #call_action_list,name=items_combustion,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireItemscombustionMainActions()
}

AddFunction FireItemshighpriorityMainPostConditions
{
 { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireItemscombustionMainPostConditions()
}

AddFunction FireItemshighpriorityShortCdActions
{
 #call_action_list,name=items_combustion,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireItemscombustionShortCdActions()
}

AddFunction FireItemshighpriorityShortCdPostConditions
{
 { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireItemscombustionShortCdPostConditions()
}

AddFunction FireItemshighpriorityCdActions
{
 #call_action_list,name=items_combustion,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
 if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireItemscombustionCdActions()

 unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireItemscombustionCdPostConditions()
 {
  #use_items
  FireUseItemActions()
  #use_item,name=azsharas_font_of_power,if=cooldown.combustion.remains<=5+15*variable.font_double_on_use
  if SpellCooldown(combustion) <= 5 + 15 * font_double_on_use() FireUseItemActions()
  #use_item,name=rotcrusted_voodoo_doll,if=cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,name=aquipotent_nautilus,if=cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,name=shiver_venom_relic,if=cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,effect_name=harmonic_dematerializer
  FireUseItemActions()
  #use_item,name=malformed_heralds_legwraps,if=cooldown.combustion.remains>=55&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) >= 55 and BuffExpires(combustion_buff) and SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,name=ancient_knot_of_wisdom,if=cooldown.combustion.remains>=55&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) >= 55 and BuffExpires(combustion_buff) and SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
  #use_item,name=neural_synapse_enhancer,if=cooldown.combustion.remains>=45&buff.combustion.down&cooldown.combustion.remains>variable.on_use_cutoff
  if SpellCooldown(combustion) >= 45 and BuffExpires(combustion_buff) and SpellCooldown(combustion) > on_use_cutoff() FireUseItemActions()
 }
}

AddFunction FireItemshighpriorityCdPostConditions
{
 { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireItemscombustionCdPostConditions()
}

### actions.items_combustion

AddFunction FireItemscombustionMainActions
{
}

AddFunction FireItemscombustionMainPostConditions
{
}

AddFunction FireItemscombustionShortCdActions
{
}

AddFunction FireItemscombustionShortCdPostConditions
{
}

AddFunction FireItemscombustionCdActions
{
 #use_item,name=ignition_mages_fuse
 FireUseItemActions()
 #use_item,name=hyperthread_wristwraps,if=buff.combustion.up&action.fire_blast.charges=0&action.fire_blast.recharge_time>gcd.remains
 if BuffPresent(combustion_buff) and Charges(fire_blast) == 0 and SpellChargeCooldown(fire_blast) > GCDRemaining() FireUseItemActions()
 #use_item,use_off_gcd=1,name=azurethos_singed_plumage,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,effect_name=gladiators_badge,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,effect_name=gladiators_medallion,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=balefire_branch,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=shockbiters_fang,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=tzanes_barkspines,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=ancient_knot_of_wisdom,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=neural_synapse_enhancer,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
 #use_item,use_off_gcd=1,name=malformed_heralds_legwraps,if=buff.combustion.up|action.meteor.in_flight&action.meteor.in_flight_remains<=0.5
 if BuffPresent(combustion_buff) or InFlightToTarget(meteor) and 0 <= 0.5 FireUseItemActions()
}

AddFunction FireItemscombustionCdPostConditions
{
}

### actions.combustion_phase

AddFunction FireCombustionphaseMainActions
{
 #fire_blast,use_while_casting=1,use_off_gcd=1,if=charges>=1&((action.fire_blast.charges_fractional+(buff.combustion.remains-buff.blaster_master.duration)%cooldown.fire_blast.duration-(buff.combustion.remains)%(buff.blaster_master.duration-0.5))>=0|!azerite.blaster_master.enabled|!talent.flame_on.enabled|buff.combustion.remains<=buff.blaster_master.duration|buff.blaster_master.remains<0.5|equipped.hyperthread_wristwraps&cooldown.hyperthread_wristwraps_300142.remains<5)&buff.combustion.up&(!action.scorch.executing&!action.pyroblast.in_flight&buff.heating_up.up|action.scorch.executing&buff.hot_streak.down&(buff.heating_up.down|azerite.blaster_master.enabled)|azerite.blaster_master.enabled&talent.flame_on.enabled&action.pyroblast.in_flight&buff.heating_up.down&buff.hot_streak.down)
 if Charges(fire_blast) >= 1 and { Charges(fire_blast count=0) + { BuffRemaining(combustion_buff) - BaseDuration(blaster_master_buff) } / SpellCooldownDuration(fire_blast) - BuffRemaining(combustion_buff) / { BaseDuration(blaster_master_buff) - 0.5 } >= 0 or not HasAzeriteTrait(blaster_master_trait) or not Talent(flame_on_talent) or BuffRemaining(combustion_buff) <= BaseDuration(blaster_master_buff) or BuffRemaining(blaster_master_buff) < 0.5 or HasEquippedItem(hyperthread_wristwraps_item) and SpellCooldown(hyperthread_wristwraps_300142) < 5 } and BuffPresent(combustion_buff) and { not ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and BuffPresent(heating_up_buff) or ExecuteTime(scorch) > 0 and BuffExpires(hot_streak_buff) and { BuffExpires(heating_up_buff) or HasAzeriteTrait(blaster_master_trait) } or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and InFlightToTarget(pyroblast) and BuffExpires(heating_up_buff) and BuffExpires(hot_streak_buff) } Spell(fire_blast)
 #fire_blast,use_while_casting=1,if=azerite.blaster_master.enabled&talent.flame_on.enabled&buff.blaster_master.down&(talent.rune_of_power.enabled&action.rune_of_power.executing&action.rune_of_power.execute_remains<0.6|(cooldown.combustion.ready|buff.combustion.up)&!talent.rune_of_power.enabled&!action.pyroblast.in_flight&!action.fireball.in_flight)
 if HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and BuffExpires(blaster_master_buff) and { Talent(rune_of_power_talent) and ExecuteTime(rune_of_power) > 0 and ExecuteTime(rune_of_power) < 0.6 or { SpellCooldown(combustion) == 0 or BuffPresent(combustion_buff) } and not Talent(rune_of_power_talent) and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } Spell(fire_blast)
 #call_action_list,name=active_talents
 FireActivetalentsMainActions()

 unless FireActivetalentsMainPostConditions()
 {
  #flamestrike,if=((talent.flame_patch.enabled&active_enemies>2)|active_enemies>6)&buff.hot_streak.react&!azerite.blaster_master.enabled
  if { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 6 } and BuffPresent(hot_streak_buff) and not HasAzeriteTrait(blaster_master_trait) Spell(flamestrike)
  #pyroblast,if=buff.pyroclasm.react&buff.combustion.remains>cast_time
  if BuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) Spell(pyroblast)
  #pyroblast,if=buff.hot_streak.react
  if BuffPresent(hot_streak_buff) Spell(pyroblast)
  #pyroblast,if=prev_gcd.1.scorch&buff.heating_up.up
  if PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) Spell(pyroblast)
  #phoenix_flames
  Spell(phoenix_flames)
  #scorch,if=buff.combustion.remains>cast_time&buff.combustion.up|buff.combustion.down
  if BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) Spell(scorch)
  #living_bomb,if=buff.combustion.remains<gcd.max&active_enemies>1
  if BuffRemaining(combustion_buff) < GCD() and Enemies() > 1 Spell(living_bomb)
  #scorch,if=target.health.pct<=30&talent.searing_touch.enabled
  if target.HealthPercent() <= 30 and Talent(searing_touch_talent) Spell(scorch)
 }
}

AddFunction FireCombustionphaseMainPostConditions
{
 FireActivetalentsMainPostConditions()
}

AddFunction FireCombustionphaseShortCdActions
{
 unless Charges(fire_blast) >= 1 and { Charges(fire_blast count=0) + { BuffRemaining(combustion_buff) - BaseDuration(blaster_master_buff) } / SpellCooldownDuration(fire_blast) - BuffRemaining(combustion_buff) / { BaseDuration(blaster_master_buff) - 0.5 } >= 0 or not HasAzeriteTrait(blaster_master_trait) or not Talent(flame_on_talent) or BuffRemaining(combustion_buff) <= BaseDuration(blaster_master_buff) or BuffRemaining(blaster_master_buff) < 0.5 or HasEquippedItem(hyperthread_wristwraps_item) and SpellCooldown(hyperthread_wristwraps_300142) < 5 } and BuffPresent(combustion_buff) and { not ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and BuffPresent(heating_up_buff) or ExecuteTime(scorch) > 0 and BuffExpires(hot_streak_buff) and { BuffExpires(heating_up_buff) or HasAzeriteTrait(blaster_master_trait) } or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and InFlightToTarget(pyroblast) and BuffExpires(heating_up_buff) and BuffExpires(hot_streak_buff) } and Spell(fire_blast)
 {
  #rune_of_power,if=buff.combustion.down
  if BuffExpires(combustion_buff) Spell(rune_of_power)

  unless HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and BuffExpires(blaster_master_buff) and { Talent(rune_of_power_talent) and ExecuteTime(rune_of_power) > 0 and ExecuteTime(rune_of_power) < 0.6 or { SpellCooldown(combustion) == 0 or BuffPresent(combustion_buff) } and not Talent(rune_of_power_talent) and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } and Spell(fire_blast)
  {
   #call_action_list,name=active_talents
   FireActivetalentsShortCdActions()

   unless FireActivetalentsShortCdPostConditions() or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 6 } and BuffPresent(hot_streak_buff) and not HasAzeriteTrait(blaster_master_trait) and Spell(flamestrike) or BuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies() > 1 and Spell(living_bomb)
   {
    #dragons_breath,if=buff.combustion.remains<gcd.max&buff.combustion.up
    if BuffRemaining(combustion_buff) < GCD() and BuffPresent(combustion_buff) and target.Distance(less 12) Spell(dragons_breath)
   }
  }
 }
}

AddFunction FireCombustionphaseShortCdPostConditions
{
 Charges(fire_blast) >= 1 and { Charges(fire_blast count=0) + { BuffRemaining(combustion_buff) - BaseDuration(blaster_master_buff) } / SpellCooldownDuration(fire_blast) - BuffRemaining(combustion_buff) / { BaseDuration(blaster_master_buff) - 0.5 } >= 0 or not HasAzeriteTrait(blaster_master_trait) or not Talent(flame_on_talent) or BuffRemaining(combustion_buff) <= BaseDuration(blaster_master_buff) or BuffRemaining(blaster_master_buff) < 0.5 or HasEquippedItem(hyperthread_wristwraps_item) and SpellCooldown(hyperthread_wristwraps_300142) < 5 } and BuffPresent(combustion_buff) and { not ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and BuffPresent(heating_up_buff) or ExecuteTime(scorch) > 0 and BuffExpires(hot_streak_buff) and { BuffExpires(heating_up_buff) or HasAzeriteTrait(blaster_master_trait) } or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and InFlightToTarget(pyroblast) and BuffExpires(heating_up_buff) and BuffExpires(hot_streak_buff) } and Spell(fire_blast) or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and BuffExpires(blaster_master_buff) and { Talent(rune_of_power_talent) and ExecuteTime(rune_of_power) > 0 and ExecuteTime(rune_of_power) < 0.6 or { SpellCooldown(combustion) == 0 or BuffPresent(combustion_buff) } and not Talent(rune_of_power_talent) and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } and Spell(fire_blast) or FireActivetalentsShortCdPostConditions() or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 6 } and BuffPresent(hot_streak_buff) and not HasAzeriteTrait(blaster_master_trait) and Spell(flamestrike) or BuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies() > 1 and Spell(living_bomb) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch)
}

AddFunction FireCombustionphaseCdActions
{
 #lights_judgment,if=buff.combustion.down
 if BuffExpires(combustion_buff) Spell(lights_judgment)
 #blood_of_the_enemy
 Spell(blood_of_the_enemy)
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams_essence)

 unless Charges(fire_blast) >= 1 and { Charges(fire_blast count=0) + { BuffRemaining(combustion_buff) - BaseDuration(blaster_master_buff) } / SpellCooldownDuration(fire_blast) - BuffRemaining(combustion_buff) / { BaseDuration(blaster_master_buff) - 0.5 } >= 0 or not HasAzeriteTrait(blaster_master_trait) or not Talent(flame_on_talent) or BuffRemaining(combustion_buff) <= BaseDuration(blaster_master_buff) or BuffRemaining(blaster_master_buff) < 0.5 or HasEquippedItem(hyperthread_wristwraps_item) and SpellCooldown(hyperthread_wristwraps_300142) < 5 } and BuffPresent(combustion_buff) and { not ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and BuffPresent(heating_up_buff) or ExecuteTime(scorch) > 0 and BuffExpires(hot_streak_buff) and { BuffExpires(heating_up_buff) or HasAzeriteTrait(blaster_master_trait) } or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and InFlightToTarget(pyroblast) and BuffExpires(heating_up_buff) and BuffExpires(hot_streak_buff) } and Spell(fire_blast) or BuffExpires(combustion_buff) and Spell(rune_of_power) or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and BuffExpires(blaster_master_buff) and { Talent(rune_of_power_talent) and ExecuteTime(rune_of_power) > 0 and ExecuteTime(rune_of_power) < 0.6 or { SpellCooldown(combustion) == 0 or BuffPresent(combustion_buff) } and not Talent(rune_of_power_talent) and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } and Spell(fire_blast)
 {
  #call_action_list,name=active_talents
  FireActivetalentsCdActions()

  unless FireActivetalentsCdPostConditions()
  {
   #combustion,use_off_gcd=1,use_while_casting=1,if=((action.meteor.in_flight&action.meteor.in_flight_remains<=0.5)|!talent.meteor.enabled)&(buff.rune_of_power.up|!talent.rune_of_power.enabled)
   if { InFlightToTarget(meteor) and 0 <= 0.5 or not Talent(meteor_talent) } and { BuffPresent(rune_of_power_buff) or not Talent(rune_of_power_talent) } Spell(combustion)
   #potion
   if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #fireblood
   Spell(fireblood)
   #ancestral_call
   Spell(ancestral_call)
  }
 }
}

AddFunction FireCombustionphaseCdPostConditions
{
 Charges(fire_blast) >= 1 and { Charges(fire_blast count=0) + { BuffRemaining(combustion_buff) - BaseDuration(blaster_master_buff) } / SpellCooldownDuration(fire_blast) - BuffRemaining(combustion_buff) / { BaseDuration(blaster_master_buff) - 0.5 } >= 0 or not HasAzeriteTrait(blaster_master_trait) or not Talent(flame_on_talent) or BuffRemaining(combustion_buff) <= BaseDuration(blaster_master_buff) or BuffRemaining(blaster_master_buff) < 0.5 or HasEquippedItem(hyperthread_wristwraps_item) and SpellCooldown(hyperthread_wristwraps_300142) < 5 } and BuffPresent(combustion_buff) and { not ExecuteTime(scorch) > 0 and not InFlightToTarget(pyroblast) and BuffPresent(heating_up_buff) or ExecuteTime(scorch) > 0 and BuffExpires(hot_streak_buff) and { BuffExpires(heating_up_buff) or HasAzeriteTrait(blaster_master_trait) } or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and InFlightToTarget(pyroblast) and BuffExpires(heating_up_buff) and BuffExpires(hot_streak_buff) } and Spell(fire_blast) or BuffExpires(combustion_buff) and Spell(rune_of_power) or HasAzeriteTrait(blaster_master_trait) and Talent(flame_on_talent) and BuffExpires(blaster_master_buff) and { Talent(rune_of_power_talent) and ExecuteTime(rune_of_power) > 0 and ExecuteTime(rune_of_power) < 0.6 or { SpellCooldown(combustion) == 0 or BuffPresent(combustion_buff) } and not Talent(rune_of_power_talent) and not InFlightToTarget(pyroblast) and not InFlightToTarget(fireball) } and Spell(fire_blast) or FireActivetalentsCdPostConditions() or { Talent(flame_patch_talent) and Enemies() > 2 or Enemies() > 6 } and BuffPresent(hot_streak_buff) and not HasAzeriteTrait(blaster_master_trait) and Spell(flamestrike) or BuffPresent(pyroclasm) and BuffRemaining(combustion_buff) > CastTime(pyroblast) and Spell(pyroblast) or BuffPresent(hot_streak_buff) and Spell(pyroblast) or PreviousGCDSpell(scorch) and BuffPresent(heating_up_buff) and Spell(pyroblast) or Spell(phoenix_flames) or { BuffRemaining(combustion_buff) > CastTime(scorch) and BuffPresent(combustion_buff) or BuffExpires(combustion_buff) } and Spell(scorch) or BuffRemaining(combustion_buff) < GCD() and Enemies() > 1 and Spell(living_bomb) or BuffRemaining(combustion_buff) < GCD() and BuffPresent(combustion_buff) and target.Distance(less 12) and Spell(dragons_breath) or target.HealthPercent() <= 30 and Talent(searing_touch_talent) and Spell(scorch)
}

### actions.active_talents

AddFunction FireActivetalentsMainActions
{
 #living_bomb,if=active_enemies>1&buff.combustion.down&(cooldown.combustion.remains>cooldown.living_bomb.duration|cooldown.combustion.ready)
 if Enemies() > 1 and BuffExpires(combustion_buff) and { SpellCooldown(combustion) > SpellCooldownDuration(living_bomb) or SpellCooldown(combustion) == 0 } Spell(living_bomb)
}

AddFunction FireActivetalentsMainPostConditions
{
}

AddFunction FireActivetalentsShortCdActions
{
 unless Enemies() > 1 and BuffExpires(combustion_buff) and { SpellCooldown(combustion) > SpellCooldownDuration(living_bomb) or SpellCooldown(combustion) == 0 } and Spell(living_bomb)
 {
  #meteor,if=buff.rune_of_power.up&(firestarter.remains>cooldown.meteor.duration|!firestarter.active)|cooldown.rune_of_power.remains>target.time_to_die&action.rune_of_power.charges<1|(cooldown.meteor.duration<cooldown.combustion.remains|cooldown.combustion.ready)&!talent.rune_of_power.enabled&(cooldown.meteor.duration<firestarter.remains|!talent.firestarter.enabled|!firestarter.active)
  if BuffPresent(rune_of_power_buff) and { target.TimeToHealthPercent(90) > SpellCooldownDuration(meteor) or not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } } or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 or { SpellCooldownDuration(meteor) < SpellCooldown(combustion) or SpellCooldown(combustion) == 0 } and not Talent(rune_of_power_talent) and { SpellCooldownDuration(meteor) < target.TimeToHealthPercent(90) or not Talent(firestarter_talent) or not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } } Spell(meteor)
 }
}

AddFunction FireActivetalentsShortCdPostConditions
{
 Enemies() > 1 and BuffExpires(combustion_buff) and { SpellCooldown(combustion) > SpellCooldownDuration(living_bomb) or SpellCooldown(combustion) == 0 } and Spell(living_bomb)
}

AddFunction FireActivetalentsCdActions
{
}

AddFunction FireActivetalentsCdPostConditions
{
 Enemies() > 1 and BuffExpires(combustion_buff) and { SpellCooldown(combustion) > SpellCooldownDuration(living_bomb) or SpellCooldown(combustion) == 0 } and Spell(living_bomb) or { BuffPresent(rune_of_power_buff) and { target.TimeToHealthPercent(90) > SpellCooldownDuration(meteor) or not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } } or SpellCooldown(rune_of_power) > target.TimeToDie() and Charges(rune_of_power) < 1 or { SpellCooldownDuration(meteor) < SpellCooldown(combustion) or SpellCooldown(combustion) == 0 } and not Talent(rune_of_power_talent) and { SpellCooldownDuration(meteor) < target.TimeToHealthPercent(90) or not Talent(firestarter_talent) or not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } } } and Spell(meteor)
}

### actions.default

AddFunction FireDefaultMainActions
{
 #call_action_list,name=items_high_priority
 FireItemshighpriorityMainActions()

 unless FireItemshighpriorityMainPostConditions()
 {
  #concentrated_flame
  Spell(concentrated_flame_essence)
  #call_action_list,name=combustion_phase,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
  if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireCombustionphaseMainActions()

  unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionphaseMainPostConditions()
  {
   #fire_blast,use_while_casting=1,use_off_gcd=1,if=(essence.memory_of_lucid_dreams.major|essence.memory_of_lucid_dreams.minor&azerite.blaster_master.enabled)&charges=max_charges&!buff.hot_streak.react&!(buff.heating_up.react&(buff.combustion.up&(action.fireball.in_flight|action.pyroblast.in_flight|action.scorch.executing)|target.health.pct<=30&action.scorch.executing))&!(!buff.heating_up.react&!buff.hot_streak.react&buff.combustion.down&(action.fireball.in_flight|action.pyroblast.in_flight))
   if { AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or AzeriteEssenceIsMinor(memory_of_lucid_dreams_essence_id) and HasAzeriteTrait(blaster_master_trait) } and Charges(fire_blast) == SpellMaxCharges(fire_blast) and not BuffPresent(hot_streak_buff) and not { BuffPresent(heating_up_buff) and { BuffPresent(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) or ExecuteTime(scorch) > 0 } or target.HealthPercent() <= 30 and ExecuteTime(scorch) > 0 } } and not { not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and BuffExpires(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) } } Spell(fire_blast)
   #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
   if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopphaseMainActions()

   unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopphaseMainPostConditions()
   {
    #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
    #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&cooldown.combustion.remains>variable.combustion_rop_cutoff&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
    #call_action_list,name=standard_rotation
    FireStandardrotationMainActions()
   }
  }
 }
}

AddFunction FireDefaultMainPostConditions
{
 FireItemshighpriorityMainPostConditions() or { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionphaseMainPostConditions() or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopphaseMainPostConditions() or FireStandardrotationMainPostConditions()
}

AddFunction FireDefaultShortCdActions
{
 #call_action_list,name=items_high_priority
 FireItemshighpriorityShortCdActions()

 unless FireItemshighpriorityShortCdPostConditions() or Spell(concentrated_flame_essence)
 {
  #focused_azerite_beam
  Spell(focused_azerite_beam)
  #purifying_blast
  Spell(purifying_blast)
  #ripple_in_space
  Spell(ripple_in_space_essence)
  #the_unbound_force
  Spell(the_unbound_force)
  #worldvein_resonance
  Spell(worldvein_resonance_essence)
  #rune_of_power,if=talent.firestarter.enabled&firestarter.remains>full_recharge_time|cooldown.combustion.remains>variable.combustion_rop_cutoff&buff.combustion.down|target.time_to_die<cooldown.combustion.remains&buff.combustion.down
  if Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) Spell(rune_of_power)
  #call_action_list,name=combustion_phase,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
  if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireCombustionphaseShortCdActions()

  unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionphaseShortCdPostConditions() or { AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or AzeriteEssenceIsMinor(memory_of_lucid_dreams_essence_id) and HasAzeriteTrait(blaster_master_trait) } and Charges(fire_blast) == SpellMaxCharges(fire_blast) and not BuffPresent(hot_streak_buff) and not { BuffPresent(heating_up_buff) and { BuffPresent(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) or ExecuteTime(scorch) > 0 } or target.HealthPercent() <= 30 and ExecuteTime(scorch) > 0 } } and not { not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and BuffExpires(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) } } and Spell(fire_blast)
  {
   #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
   if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopphaseShortCdActions()

   unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopphaseShortCdPostConditions()
   {
    #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
    #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&cooldown.combustion.remains>variable.combustion_rop_cutoff&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
    #call_action_list,name=standard_rotation
    FireStandardrotationShortCdActions()
   }
  }
 }
}

AddFunction FireDefaultShortCdPostConditions
{
 FireItemshighpriorityShortCdPostConditions() or Spell(concentrated_flame_essence) or { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionphaseShortCdPostConditions() or { AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or AzeriteEssenceIsMinor(memory_of_lucid_dreams_essence_id) and HasAzeriteTrait(blaster_master_trait) } and Charges(fire_blast) == SpellMaxCharges(fire_blast) and not BuffPresent(hot_streak_buff) and not { BuffPresent(heating_up_buff) and { BuffPresent(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) or ExecuteTime(scorch) > 0 } or target.HealthPercent() <= 30 and ExecuteTime(scorch) > 0 } } and not { not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and BuffExpires(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) } } and Spell(fire_blast) or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopphaseShortCdPostConditions() or FireStandardrotationShortCdPostConditions()
}

AddFunction FireDefaultCdActions
{
 #counterspell
 FireInterruptActions()
 #call_action_list,name=items_high_priority
 FireItemshighpriorityCdActions()

 unless FireItemshighpriorityCdPostConditions()
 {
  #mirror_image,if=buff.combustion.down
  if BuffExpires(combustion_buff) Spell(mirror_image)
  #guardian_of_azeroth,if=cooldown.combustion.remains<10|target.time_to_die<cooldown.combustion.remains
  if SpellCooldown(combustion) < 10 or target.TimeToDie() < SpellCooldown(combustion) Spell(guardian_of_azeroth)

  unless Spell(concentrated_flame_essence) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(ripple_in_space_essence) or Spell(the_unbound_force) or Spell(worldvein_resonance_essence) or { Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) } and Spell(rune_of_power)
  {
   #call_action_list,name=combustion_phase,if=(talent.rune_of_power.enabled&cooldown.combustion.remains<=action.rune_of_power.cast_time|cooldown.combustion.ready)&!firestarter.active|buff.combustion.up
   if { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) FireCombustionphaseCdActions()

   unless { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionphaseCdPostConditions() or { AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or AzeriteEssenceIsMinor(memory_of_lucid_dreams_essence_id) and HasAzeriteTrait(blaster_master_trait) } and Charges(fire_blast) == SpellMaxCharges(fire_blast) and not BuffPresent(hot_streak_buff) and not { BuffPresent(heating_up_buff) and { BuffPresent(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) or ExecuteTime(scorch) > 0 } or target.HealthPercent() <= 30 and ExecuteTime(scorch) > 0 } } and not { not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and BuffExpires(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) } } and Spell(fire_blast)
   {
    #call_action_list,name=rop_phase,if=buff.rune_of_power.up&buff.combustion.down
    if BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) FireRopphaseCdActions()

    unless BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopphaseCdPostConditions()
    {
     #variable,name=fire_blast_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.fire_blast.full_recharge_time&(cooldown.combustion.remains>variable.combustion_rop_cutoff|firestarter.active)&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled&!firestarter.active&cooldown.combustion.remains<target.time_to_die|talent.firestarter.enabled&firestarter.active&firestarter.remains<cooldown.fire_blast.full_recharge_time+cooldown.fire_blast.duration*azerite.blaster_master.enabled
     #variable,name=phoenix_pooling,value=talent.rune_of_power.enabled&cooldown.rune_of_power.remains<cooldown.phoenix_flames.full_recharge_time&cooldown.combustion.remains>variable.combustion_rop_cutoff&(cooldown.rune_of_power.remains<target.time_to_die|action.rune_of_power.charges>0)|cooldown.combustion.remains<action.phoenix_flames.full_recharge_time&cooldown.combustion.remains<target.time_to_die
     #call_action_list,name=standard_rotation
     FireStandardrotationCdActions()
    }
   }
  }
 }
}

AddFunction FireDefaultCdPostConditions
{
 FireItemshighpriorityCdPostConditions() or Spell(concentrated_flame_essence) or Spell(focused_azerite_beam) or Spell(purifying_blast) or Spell(ripple_in_space_essence) or Spell(the_unbound_force) or Spell(worldvein_resonance_essence) or { Talent(firestarter_talent) and target.TimeToHealthPercent(90) > SpellFullRecharge(rune_of_power) or SpellCooldown(combustion) > combustion_rop_cutoff() and BuffExpires(combustion_buff) or target.TimeToDie() < SpellCooldown(combustion) and BuffExpires(combustion_buff) } and Spell(rune_of_power) or { { Talent(rune_of_power_talent) and SpellCooldown(combustion) <= CastTime(rune_of_power) or SpellCooldown(combustion) == 0 } and not { Talent(firestarter_talent) and target.HealthPercent() >= 90 } or BuffPresent(combustion_buff) } and FireCombustionphaseCdPostConditions() or { AzeriteEssenceIsMajor(memory_of_lucid_dreams_essence_id) or AzeriteEssenceIsMinor(memory_of_lucid_dreams_essence_id) and HasAzeriteTrait(blaster_master_trait) } and Charges(fire_blast) == SpellMaxCharges(fire_blast) and not BuffPresent(hot_streak_buff) and not { BuffPresent(heating_up_buff) and { BuffPresent(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) or ExecuteTime(scorch) > 0 } or target.HealthPercent() <= 30 and ExecuteTime(scorch) > 0 } } and not { not BuffPresent(heating_up_buff) and not BuffPresent(hot_streak_buff) and BuffExpires(combustion_buff) and { InFlightToTarget(fireball) or InFlightToTarget(pyroblast) } } and Spell(fire_blast) or BuffPresent(rune_of_power_buff) and BuffExpires(combustion_buff) and FireRopphaseCdPostConditions() or FireStandardrotationCdPostConditions()
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
# alexstraszas_fury_talent
# ancestral_call
# ancient_knot_of_wisdom_item
# arcane_intellect
# azsharas_font_of_power_item
# azurethos_singed_plumage_item
# balefire_branch_item
# berserking
# blaster_master_buff
# blaster_master_trait
# blood_fury_sp
# blood_of_the_enemy
# combustion
# combustion_buff
# concentrated_flame_essence
# counterspell
# dragons_breath
# dread_aspirants_badge_item
# dread_aspirants_medallion_item
# dread_combatants_insignia_item
# dread_combatants_medallion_item
# dread_gladiators_badge_item
# dread_gladiators_medallion_item
# fire_blast
# fireball
# fireblood
# firestarter_talent
# flame_on_talent
# flame_patch_talent
# flamestrike
# focused_azerite_beam
# guardian_of_azeroth
# heating_up_buff
# hot_streak_buff
# hyperthread_wristwraps_300142
# hyperthread_wristwraps_item
# ignition_mages_fuse_item
# item_unbridled_fury
# kindling_talent
# lights_judgment
# living_bomb
# memory_of_lucid_dreams_essence
# memory_of_lucid_dreams_essence_id
# meteor
# meteor_talent
# mirror_image
# neural_synapse_enhancer_item
# notorious_aspirants_badge_item
# notorious_aspirants_medallion_item
# notorious_gladiators_badge_item
# notorious_gladiators_medallion_item
# phoenix_flames
# phoenix_flames_talent
# purifying_blast
# pyroblast
# pyroclasm
# quaking_palm
# ripple_in_space_essence
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# scorch
# searing_touch_talent
# shockbiters_fang_item
# sinister_aspirants_badge_item
# sinister_aspirants_medallion_item
# sinister_gladiators_badge_item
# sinister_gladiators_medallion_item
# the_unbound_force
# tzanes_barkspines_item
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
    end
    do
        local name = "sc_t23_mage_frost"
        local desc = "[8.2] Simulationcraft: T23_Mage_Frost"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Frost".
#	class=mage
#	spec=frost
#	talents=1013033

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=frost)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=frost)
AddCheckBox(opt_blink SpellName(blink) specialization=frost)

AddFunction FrostInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
 }
}

AddFunction FrostUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.talent_rop

AddFunction FrostTalentropMainActions
{
}

AddFunction FrostTalentropMainPostConditions
{
}

AddFunction FrostTalentropShortCdActions
{
 #rune_of_power,if=talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time)
 if Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) } Spell(rune_of_power)
 #rune_of_power,if=!talent.glacial_spike.enabled&(talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time|talent.comet_storm.enabled&cooldown.comet_storm.remains<cast_time|talent.ray_of_frost.enabled&cooldown.ray_of_frost.remains<cast_time|charges_fractional>1.9)
 if not Talent(glacial_spike_talent) and { Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) or Talent(comet_storm_talent) and SpellCooldown(comet_storm) < CastTime(rune_of_power) or Talent(ray_of_frost_talent) and SpellCooldown(ray_of_frost) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 } Spell(rune_of_power)
}

AddFunction FrostTalentropShortCdPostConditions
{
}

AddFunction FrostTalentropCdActions
{
}

AddFunction FrostTalentropCdPostConditions
{
 Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) } and Spell(rune_of_power) or not Talent(glacial_spike_talent) and { Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) or Talent(comet_storm_talent) and SpellCooldown(comet_storm) < CastTime(rune_of_power) or Talent(ray_of_frost_talent) and SpellCooldown(ray_of_frost) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 } and Spell(rune_of_power)
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=cooldown.ice_nova.ready&debuff.winters_chill.up
 if SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) Spell(ice_nova)
 #flurry,if=talent.ebonbolt.enabled&prev_gcd.1.ebonbolt&(!talent.glacial_spike.enabled|buff.icicles.stack<4|buff.brain_freeze.react)
 if Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 or BuffPresent(brain_freeze_buff) } Spell(flurry)
 #flurry,if=talent.glacial_spike.enabled&prev_gcd.1.glacial_spike&buff.brain_freeze.react
 if Talent(glacial_spike_talent) and PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) Spell(flurry)
 #flurry,if=prev_gcd.1.frostbolt&buff.brain_freeze.react&(!talent.glacial_spike.enabled|buff.icicles.stack<4)
 if PreviousGCDSpell(frostbolt) and BuffPresent(brain_freeze_buff) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 } Spell(flurry)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #blizzard,if=active_enemies>2|active_enemies>1&cast_time=0&buff.fingers_of_frost.react<2
  if Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 and BuffStacks(fingers_of_frost_buff) < 2 Spell(blizzard)
  #ice_lance,if=buff.fingers_of_frost.react
  if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
  #ebonbolt
  Spell(ebonbolt)
  #ray_of_frost,if=!action.frozen_orb.in_flight&ground_aoe.frozen_orb.remains=0
  if not TimeSincePreviousSpell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 Spell(ray_of_frost)
  #blizzard,if=cast_time=0|active_enemies>1
  if CastTime(blizzard) == 0 or Enemies() > 1 Spell(blizzard)
  #glacial_spike,if=buff.brain_freeze.react|prev_gcd.1.ebonbolt|active_enemies>1&talent.splitting_ice.enabled
  if BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Enemies() > 1 and Talent(splitting_ice_talent) Spell(glacial_spike)
  #ice_nova
  Spell(ice_nova)
  #frostbolt
  Spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   Spell(ice_lance)
  }
 }
}

AddFunction FrostSingleMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostSingleShortCdActions
{
 unless SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 or BuffPresent(brain_freeze_buff) } and Spell(flurry) or Talent(glacial_spike_talent) and PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(frostbolt) and BuffPresent(brain_freeze_buff) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 } and Spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #frozen_orb
   Spell(frozen_orb)

   unless { Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 and BuffStacks(fingers_of_frost_buff) < 2 } and Spell(blizzard) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance)
   {
    #comet_storm
    Spell(comet_storm)

    unless Spell(ebonbolt) or not TimeSincePreviousSpell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 and Spell(ray_of_frost) or { CastTime(blizzard) == 0 or Enemies() > 1 } and Spell(blizzard) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Enemies() > 1 and Talent(splitting_ice_talent) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 or BuffPresent(brain_freeze_buff) } and Spell(flurry) or Talent(glacial_spike_talent) and PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(frostbolt) and BuffPresent(brain_freeze_buff) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 } and Spell(flurry) or FrostEssencesShortCdPostConditions() or { Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 and BuffStacks(fingers_of_frost_buff) < 2 } and Spell(blizzard) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ebonbolt) or not TimeSincePreviousSpell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 and Spell(ray_of_frost) or { CastTime(blizzard) == 0 or Enemies() > 1 } and Spell(blizzard) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Enemies() > 1 and Talent(splitting_ice_talent) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
 unless SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 or BuffPresent(brain_freeze_buff) } and Spell(flurry) or Talent(glacial_spike_talent) and PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(frostbolt) and BuffPresent(brain_freeze_buff) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 } and Spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or Spell(frozen_orb) or { Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 and BuffStacks(fingers_of_frost_buff) < 2 } and Spell(blizzard) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(comet_storm) or Spell(ebonbolt) or not TimeSincePreviousSpell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 and Spell(ray_of_frost) or { CastTime(blizzard) == 0 or Enemies() > 1 } and Spell(blizzard) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Enemies() > 1 and Talent(splitting_ice_talent) } and Spell(glacial_spike) or Spell(ice_nova)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()

   unless Spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostSingleCdPostConditions
{
 SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 or BuffPresent(brain_freeze_buff) } and Spell(flurry) or Talent(glacial_spike_talent) and PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(frostbolt) and BuffPresent(brain_freeze_buff) and { not Talent(glacial_spike_talent) or BuffStacks(icicles_buff) < 4 } and Spell(flurry) or FrostEssencesCdPostConditions() or Spell(frozen_orb) or { Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 and BuffStacks(fingers_of_frost_buff) < 2 } and Spell(blizzard) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(comet_storm) or Spell(ebonbolt) or not TimeSincePreviousSpell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 and Spell(ray_of_frost) or { CastTime(blizzard) == 0 or Enemies() > 1 } and Spell(blizzard) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Enemies() > 1 and Talent(splitting_ice_talent) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(ice_lance)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 Spell(arcane_intellect)
 #frostbolt
 Spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 unless Spell(arcane_intellect)
 {
  #summon_water_elemental
  if not pet.Present() Spell(summon_water_elemental)
 }
}

AddFunction FrostPrecombatShortCdPostConditions
{
 Spell(arcane_intellect) or Spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless Spell(arcane_intellect) or not pet.Present() and Spell(summon_water_elemental)
 {
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  FrostUseItemActions()
  #mirror_image
  Spell(mirror_image)
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 Spell(arcane_intellect) or not pet.Present() and Spell(summon_water_elemental) or Spell(frostbolt)
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
 #blink_any,if=movement.distance>10
 if target.Distance() > 10 and CheckBoxOn(opt_blink) Spell(blink)
 #ice_floes,if=buff.ice_floes.down
 if BuffExpires(ice_floes_buff) and Speed() > 0 Spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 target.Distance() > 10 and CheckBoxOn(opt_blink) and Spell(blink) or BuffExpires(ice_floes_buff) and Speed() > 0 and Spell(ice_floes)
}

### actions.essences

AddFunction FrostEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down
 if TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesMainPostConditions
{
}

AddFunction FrostEssencesShortCdActions
{
 #focused_azerite_beam,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies() > 3 Spell(focused_azerite_beam)
 #purifying_blast,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies() > 3 Spell(purifying_blast)
 #ripple_in_space,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies() > 3 Spell(ripple_in_space_essence)

 unless TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and Spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
  #worldvein_resonance,if=buff.rune_of_power.down|active_enemies>3
  if BuffExpires(rune_of_power_buff) or Enemies() > 3 Spell(worldvein_resonance_essence)
 }
}

AddFunction FrostEssencesShortCdPostConditions
{
 TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesCdActions
{
 unless { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(focused_azerite_beam)
 {
  #memory_of_lucid_dreams,if=active_enemies<5&(buff.icicles.stack<=1|!talent.glacial_spike.enabled)&cooldown.frozen_orb.remains>10&!action.frozen_orb.in_flight&ground_aoe.frozen_orb.remains=0
  if Enemies() < 5 and { BuffStacks(icicles_buff) <= 1 or not Talent(glacial_spike_talent) } and SpellCooldown(frozen_orb) > 10 and not TimeSincePreviousSpell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 Spell(memory_of_lucid_dreams_essence)
  #blood_of_the_enemy,if=(talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|prev_gcd.1.ebonbolt))|((active_enemies>3|!talent.glacial_spike.enabled)&(prev_gcd.1.frozen_orb|ground_aoe.frozen_orb.remains>5))
  if Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) } or { Enemies() > 3 or not Talent(glacial_spike_talent) } and { PreviousGCDSpell(frozen_orb) or target.DebuffRemaining(frozen_orb_debuff) > 5 } Spell(blood_of_the_enemy)
 }
}

AddFunction FrostEssencesCdPostConditions
{
 { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(focused_azerite_beam) or { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(purifying_blast) or { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(ripple_in_space_essence) or TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(worldvein_resonance_essence)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=prev_gcd.1.frozen_orb|target.time_to_die>10+cast_time&target.time_to_die<20
 if PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 Spell(rune_of_power)
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
 #icy_veins
 Spell(icy_veins)
 #mirror_image
 Spell(mirror_image)

 unless { PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 } and Spell(rune_of_power)
 {
  #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
  if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropCdActions()

  unless Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropCdPostConditions()
  {
   #potion,if=prev_gcd.1.icy_veins|target.time_to_die<30
   if { PreviousGCDSpell(icy_veins) or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
   #use_items
   FrostUseItemActions()
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #lights_judgment
   Spell(lights_judgment)
   #fireblood
   Spell(fireblood)
   #ancestral_call
   Spell(ancestral_call)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 } and Spell(rune_of_power) or Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #blizzard
 Spell(blizzard)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #ice_nova
  Spell(ice_nova)
  #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.frostbolt&(buff.icicles.stack<4|!talent.glacial_spike.enabled)|prev_gcd.1.glacial_spike)
  if PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } Spell(flurry)
  #ice_lance,if=buff.fingers_of_frost.react
  if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
  #ray_of_frost
  Spell(ray_of_frost)
  #ebonbolt
  Spell(ebonbolt)
  #glacial_spike
  Spell(glacial_spike)
  #frostbolt
  Spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   Spell(ice_lance)
  }
 }
}

AddFunction FrostAoeMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostAoeShortCdActions
{
 #frozen_orb
 Spell(frozen_orb)

 unless Spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #comet_storm
   Spell(comet_storm)

   unless Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike)
   {
    #cone_of_cold
    if target.Distance() < 12 Spell(cone_of_cold)

    unless Spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 Spell(blizzard) or FrostEssencesShortCdPostConditions() or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
 unless Spell(frozen_orb) or Spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or target.Distance() < 12 and Spell(cone_of_cold)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()

   unless Spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostAoeCdPostConditions
{
 Spell(frozen_orb) or Spell(blizzard) or FrostEssencesCdPostConditions() or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or target.Distance() < 12 and Spell(cone_of_cold) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(ice_lance)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #ice_lance,if=prev_gcd.1.flurry&!buff.fingers_of_frost.react
 if PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeMainActions()

  unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeMainPostConditions()
  {
   #call_action_list,name=single
   FrostSingleMainActions()
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 unless PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) and Spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsShortCdActions()

  unless FrostCooldownsShortCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
   if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeShortCdActions()

   unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeShortCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleShortCdActions()
   }
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or FrostCooldownsShortCdPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #counterspell
 FrostInterruptActions()

 unless PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) and Spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsCdActions()

  unless FrostCooldownsCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
   if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeCdActions()

   unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleCdActions()
   }
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or FrostCooldownsCdPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
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
# ancestral_call
# arcane_intellect
# berserking
# blink
# blizzard
# blood_fury_sp
# blood_of_the_enemy
# brain_freeze_buff
# comet_storm
# comet_storm_talent
# concentrated_flame_essence
# cone_of_cold
# counterspell
# ebonbolt
# ebonbolt_talent
# fingers_of_frost_buff
# fireblood
# flurry
# focused_azerite_beam
# freezing_rain_talent
# frostbolt
# frozen_orb
# frozen_orb_debuff
# glacial_spike
# glacial_spike_talent
# guardian_of_azeroth
# ice_floes
# ice_floes_buff
# ice_lance
# ice_nova
# icicles_buff
# icy_veins
# icy_veins_buff
# item_unbridled_fury
# lights_judgment
# memory_of_lucid_dreams_essence
# mirror_image
# purifying_blast
# quaking_palm
# ray_of_frost
# ray_of_frost_talent
# reckless_force_buff
# ripple_in_space_essence
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# splitting_ice_talent
# summon_water_elemental
# the_unbound_force
# winters_chill_debuff
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
    do
        local name = "sc_t23_mage_frost_frozenorb"
        local desc = "[8.2] Simulationcraft: T23_Mage_Frost_FrozenOrb"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Frost_FrozenOrb".
#	class=mage
#	spec=frost
#	talents=2032011

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=frost)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=frost)
AddCheckBox(opt_blink SpellName(blink) specialization=frost)

AddFunction FrostInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
 }
}

AddFunction FrostUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.talent_rop

AddFunction FrostTalentropMainActions
{
}

AddFunction FrostTalentropMainPostConditions
{
}

AddFunction FrostTalentropShortCdActions
{
 #rune_of_power,if=talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time)
 if Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) } Spell(rune_of_power)
 #rune_of_power,if=!talent.glacial_spike.enabled&(talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time|talent.comet_storm.enabled&cooldown.comet_storm.remains<cast_time|talent.ray_of_frost.enabled&cooldown.ray_of_frost.remains<cast_time|charges_fractional>1.9)
 if not Talent(glacial_spike_talent) and { Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) or Talent(comet_storm_talent) and SpellCooldown(comet_storm) < CastTime(rune_of_power) or Talent(ray_of_frost_talent) and SpellCooldown(ray_of_frost) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 } Spell(rune_of_power)
}

AddFunction FrostTalentropShortCdPostConditions
{
}

AddFunction FrostTalentropCdActions
{
}

AddFunction FrostTalentropCdPostConditions
{
 Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) } and Spell(rune_of_power) or not Talent(glacial_spike_talent) and { Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) or Talent(comet_storm_talent) and SpellCooldown(comet_storm) < CastTime(rune_of_power) or Talent(ray_of_frost_talent) and SpellCooldown(ray_of_frost) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 } and Spell(rune_of_power)
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=cooldown.ice_nova.ready&debuff.winters_chill.up
 if SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) Spell(ice_nova)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #flurry,if=prev_gcd.1.ebonbolt&buff.brain_freeze.react
  if PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) Spell(flurry)
  #blizzard,if=active_enemies>2|active_enemies>1&cast_time=0
  if Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 Spell(blizzard)
  #ice_lance,if=buff.fingers_of_frost.react&cooldown.frozen_orb.remains>5|buff.fingers_of_frost.react=2
  if BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > 5 or BuffStacks(fingers_of_frost_buff) == 2 Spell(ice_lance)
  #blizzard,if=cast_time=0
  if CastTime(blizzard) == 0 Spell(blizzard)
  #flurry,if=prev_gcd.1.ebonbolt
  if PreviousGCDSpell(ebonbolt) Spell(flurry)
  #flurry,if=buff.brain_freeze.react&(prev_gcd.1.frostbolt|debuff.packed_ice.remains>execute_time+action.ice_lance.travel_time)
  if BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) or target.DebuffRemaining(packed_ice) > ExecuteTime(flurry) + TravelTime(ice_lance) } Spell(flurry)
  #ebonbolt
  Spell(ebonbolt)
  #ray_of_frost,if=debuff.packed_ice.up,interrupt_if=buff.fingers_of_frost.react=2,interrupt_immediate=1
  if target.DebuffPresent(packed_ice) Spell(ray_of_frost)
  #blizzard
  Spell(blizzard)
  #ice_nova
  Spell(ice_nova)
  #frostbolt
  Spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   Spell(ice_lance)
  }
 }
}

AddFunction FrostSingleMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostSingleShortCdActions
{
 unless SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #frozen_orb
   Spell(frozen_orb)

   unless PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or { Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 } and Spell(blizzard) or { BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > 5 or BuffStacks(fingers_of_frost_buff) == 2 } and Spell(ice_lance) or CastTime(blizzard) == 0 and Spell(blizzard) or PreviousGCDSpell(ebonbolt) and Spell(flurry) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) or target.DebuffRemaining(packed_ice) > ExecuteTime(flurry) + TravelTime(ice_lance) } and Spell(flurry)
   {
    #comet_storm
    Spell(comet_storm)

    unless Spell(ebonbolt) or target.DebuffPresent(packed_ice) and Spell(ray_of_frost) or Spell(blizzard) or Spell(ice_nova) or Spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or FrostEssencesShortCdPostConditions() or PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or { Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 } and Spell(blizzard) or { BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > 5 or BuffStacks(fingers_of_frost_buff) == 2 } and Spell(ice_lance) or CastTime(blizzard) == 0 and Spell(blizzard) or PreviousGCDSpell(ebonbolt) and Spell(flurry) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) or target.DebuffRemaining(packed_ice) > ExecuteTime(flurry) + TravelTime(ice_lance) } and Spell(flurry) or Spell(ebonbolt) or target.DebuffPresent(packed_ice) and Spell(ray_of_frost) or Spell(blizzard) or Spell(ice_nova) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
 unless SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or Spell(frozen_orb) or PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or { Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 } and Spell(blizzard) or { BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > 5 or BuffStacks(fingers_of_frost_buff) == 2 } and Spell(ice_lance) or CastTime(blizzard) == 0 and Spell(blizzard) or PreviousGCDSpell(ebonbolt) and Spell(flurry) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) or target.DebuffRemaining(packed_ice) > ExecuteTime(flurry) + TravelTime(ice_lance) } and Spell(flurry) or Spell(comet_storm) or Spell(ebonbolt) or target.DebuffPresent(packed_ice) and Spell(ray_of_frost) or Spell(blizzard) or Spell(ice_nova)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()

   unless Spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostSingleCdPostConditions
{
 SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or FrostEssencesCdPostConditions() or Spell(frozen_orb) or PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or { Enemies() > 2 or Enemies() > 1 and CastTime(blizzard) == 0 } and Spell(blizzard) or { BuffPresent(fingers_of_frost_buff) and SpellCooldown(frozen_orb) > 5 or BuffStacks(fingers_of_frost_buff) == 2 } and Spell(ice_lance) or CastTime(blizzard) == 0 and Spell(blizzard) or PreviousGCDSpell(ebonbolt) and Spell(flurry) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) or target.DebuffRemaining(packed_ice) > ExecuteTime(flurry) + TravelTime(ice_lance) } and Spell(flurry) or Spell(comet_storm) or Spell(ebonbolt) or target.DebuffPresent(packed_ice) and Spell(ray_of_frost) or Spell(blizzard) or Spell(ice_nova) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(ice_lance)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 Spell(arcane_intellect)
 #frostbolt
 Spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 unless Spell(arcane_intellect)
 {
  #summon_water_elemental
  if not pet.Present() Spell(summon_water_elemental)
 }
}

AddFunction FrostPrecombatShortCdPostConditions
{
 Spell(arcane_intellect) or Spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless Spell(arcane_intellect) or not pet.Present() and Spell(summon_water_elemental)
 {
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  FrostUseItemActions()
  #mirror_image
  Spell(mirror_image)
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 Spell(arcane_intellect) or not pet.Present() and Spell(summon_water_elemental) or Spell(frostbolt)
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
 #blink_any,if=movement.distance>10
 if target.Distance() > 10 and CheckBoxOn(opt_blink) Spell(blink)
 #ice_floes,if=buff.ice_floes.down
 if BuffExpires(ice_floes_buff) and Speed() > 0 Spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 target.Distance() > 10 and CheckBoxOn(opt_blink) and Spell(blink) or BuffExpires(ice_floes_buff) and Speed() > 0 and Spell(ice_floes)
}

### actions.essences

AddFunction FrostEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down&debuff.packed_ice.down
 if TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesMainPostConditions
{
}

AddFunction FrostEssencesShortCdActions
{
 #focused_azerite_beam,if=buff.rune_of_power.down&debuff.packed_ice.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 Spell(focused_azerite_beam)
 #purifying_blast,if=buff.rune_of_power.down&debuff.packed_ice.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 Spell(purifying_blast)
 #ripple_in_space,if=buff.rune_of_power.down&debuff.packed_ice.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 Spell(ripple_in_space_essence)

 unless TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) and Spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
  #worldvein_resonance,if=buff.rune_of_power.down&debuff.packed_ice.down|active_enemies>3
  if BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 Spell(worldvein_resonance_essence)
 }
}

AddFunction FrostEssencesShortCdPostConditions
{
 TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) and Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesCdActions
{
 unless { BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 } and Spell(focused_azerite_beam)
 {
  #memory_of_lucid_dreams,if=active_enemies<5&debuff.packed_ice.down&cooldown.frozen_orb.remains>5&!action.frozen_orb.in_flight&ground_aoe.frozen_orb.remains=0
  if Enemies() < 5 and target.DebuffExpires(packed_ice) and SpellCooldown(frozen_orb) > 5 and not TimeSincePreviousSpell(frozen_orb) < 10 and not target.DebuffRemaining(frozen_orb_debuff) > 0 Spell(memory_of_lucid_dreams_essence)
  #blood_of_the_enemy,if=prev_gcd.1.frozen_orb|ground_aoe.frozen_orb.remains>5
  if PreviousGCDSpell(frozen_orb) or target.DebuffRemaining(frozen_orb_debuff) > 5 Spell(blood_of_the_enemy)
 }
}

AddFunction FrostEssencesCdPostConditions
{
 { BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 } and Spell(focused_azerite_beam) or { BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 } and Spell(purifying_blast) or { BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 } and Spell(ripple_in_space_essence) or TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or { BuffExpires(rune_of_power_buff) and target.DebuffExpires(packed_ice) or Enemies() > 3 } and Spell(worldvein_resonance_essence)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=prev_gcd.1.frozen_orb|target.time_to_die>10+cast_time&target.time_to_die<20
 if PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 Spell(rune_of_power)
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #guardian_of_azeroth,if=cooldown.frozen_orb.remains<5
 if SpellCooldown(frozen_orb) < 5 Spell(guardian_of_azeroth)
 #icy_veins,if=cooldown.frozen_orb.remains<5
 if SpellCooldown(frozen_orb) < 5 Spell(icy_veins)
 #mirror_image
 Spell(mirror_image)

 unless { PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 } and Spell(rune_of_power)
 {
  #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
  if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropCdActions()

  unless Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropCdPostConditions()
  {
   #potion,if=prev_gcd.1.icy_veins|target.time_to_die<30
   if { PreviousGCDSpell(icy_veins) or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
   #use_items
   FrostUseItemActions()
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #lights_judgment
   Spell(lights_judgment)
   #fireblood
   Spell(fireblood)
   #ancestral_call
   Spell(ancestral_call)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 } and Spell(rune_of_power) or Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #blizzard
 Spell(blizzard)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #ice_nova
  Spell(ice_nova)
  #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.frostbolt&(buff.icicles.stack<4|!talent.glacial_spike.enabled)|prev_gcd.1.glacial_spike)
  if PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } Spell(flurry)
  #ice_lance,if=buff.fingers_of_frost.react
  if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
  #ray_of_frost
  Spell(ray_of_frost)
  #ebonbolt
  Spell(ebonbolt)
  #glacial_spike
  Spell(glacial_spike)
  #frostbolt
  Spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   Spell(ice_lance)
  }
 }
}

AddFunction FrostAoeMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostAoeShortCdActions
{
 #frozen_orb
 Spell(frozen_orb)

 unless Spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #comet_storm
   Spell(comet_storm)

   unless Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike)
   {
    #cone_of_cold
    if target.Distance() < 12 Spell(cone_of_cold)

    unless Spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 Spell(blizzard) or FrostEssencesShortCdPostConditions() or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
 unless Spell(frozen_orb) or Spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or target.Distance() < 12 and Spell(cone_of_cold)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()

   unless Spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostAoeCdPostConditions
{
 Spell(frozen_orb) or Spell(blizzard) or FrostEssencesCdPostConditions() or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or target.Distance() < 12 and Spell(cone_of_cold) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(ice_lance)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #ice_lance,if=prev_gcd.1.flurry&!buff.fingers_of_frost.react
 if PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeMainActions()

  unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeMainPostConditions()
  {
   #call_action_list,name=single
   FrostSingleMainActions()
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 unless PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) and Spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsShortCdActions()

  unless FrostCooldownsShortCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
   if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeShortCdActions()

   unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeShortCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleShortCdActions()
   }
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or FrostCooldownsShortCdPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #counterspell
 FrostInterruptActions()

 unless PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) and Spell(ice_lance)
 {
  #call_action_list,name=cooldowns
  FrostCooldownsCdActions()

  unless FrostCooldownsCdPostConditions()
  {
   #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
   if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeCdActions()

   unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeCdPostConditions()
   {
    #call_action_list,name=single
    FrostSingleCdActions()
   }
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 PreviousGCDSpell(flurry) and not BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or FrostCooldownsCdPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
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
# ancestral_call
# arcane_intellect
# berserking
# blink
# blizzard
# blood_fury_sp
# blood_of_the_enemy
# brain_freeze_buff
# comet_storm
# comet_storm_talent
# concentrated_flame_essence
# cone_of_cold
# counterspell
# ebonbolt
# ebonbolt_talent
# fingers_of_frost_buff
# fireblood
# flurry
# focused_azerite_beam
# freezing_rain_talent
# frostbolt
# frozen_orb
# frozen_orb_debuff
# glacial_spike
# glacial_spike_talent
# guardian_of_azeroth
# ice_floes
# ice_floes_buff
# ice_lance
# ice_nova
# icicles_buff
# icy_veins
# icy_veins_buff
# item_unbridled_fury
# lights_judgment
# memory_of_lucid_dreams_essence
# mirror_image
# packed_ice
# purifying_blast
# quaking_palm
# ray_of_frost
# ray_of_frost_talent
# reckless_force_buff
# ripple_in_space_essence
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# summon_water_elemental
# the_unbound_force
# winters_chill_debuff
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
    do
        local name = "sc_t23_mage_frost_noicelance"
        local desc = "[8.2] Simulationcraft: T23_Mage_Frost_NoIceLance"
        local code = [[
# Based on SimulationCraft profile "T23_Mage_Frost_NoIceLance".
#	class=mage
#	spec=frost
#	talents=1013023

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=frost)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=frost)
AddCheckBox(opt_blink SpellName(blink) specialization=frost)

AddFunction FrostInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
 }
}

AddFunction FrostUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

### actions.talent_rop

AddFunction FrostTalentropMainActions
{
}

AddFunction FrostTalentropMainPostConditions
{
}

AddFunction FrostTalentropShortCdActions
{
 #rune_of_power,if=talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time)
 if Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) } Spell(rune_of_power)
 #rune_of_power,if=!talent.glacial_spike.enabled&(talent.ebonbolt.enabled&cooldown.ebonbolt.remains<cast_time|talent.comet_storm.enabled&cooldown.comet_storm.remains<cast_time|talent.ray_of_frost.enabled&cooldown.ray_of_frost.remains<cast_time|charges_fractional>1.9)
 if not Talent(glacial_spike_talent) and { Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) or Talent(comet_storm_talent) and SpellCooldown(comet_storm) < CastTime(rune_of_power) or Talent(ray_of_frost_talent) and SpellCooldown(ray_of_frost) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 } Spell(rune_of_power)
}

AddFunction FrostTalentropShortCdPostConditions
{
}

AddFunction FrostTalentropCdActions
{
}

AddFunction FrostTalentropCdPostConditions
{
 Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) } and Spell(rune_of_power) or not Talent(glacial_spike_talent) and { Talent(ebonbolt_talent) and SpellCooldown(ebonbolt) < CastTime(rune_of_power) or Talent(comet_storm_talent) and SpellCooldown(comet_storm) < CastTime(rune_of_power) or Talent(ray_of_frost_talent) and SpellCooldown(ray_of_frost) < CastTime(rune_of_power) or Charges(rune_of_power count=0) > 1.9 } and Spell(rune_of_power)
}

### actions.single

AddFunction FrostSingleMainActions
{
 #ice_nova,if=cooldown.ice_nova.ready&debuff.winters_chill.up
 if SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) Spell(ice_nova)
 #flurry,if=talent.ebonbolt.enabled&prev_gcd.1.ebonbolt&buff.brain_freeze.react
 if Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) Spell(flurry)
 #flurry,if=prev_gcd.1.glacial_spike&buff.brain_freeze.react
 if PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) Spell(flurry)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #blizzard,if=active_enemies>2|active_enemies>1&!talent.splitting_ice.enabled
  if Enemies() > 2 or Enemies() > 1 and not Talent(splitting_ice_talent) Spell(blizzard)
  #ebonbolt,if=buff.icicles.stack=5&!buff.brain_freeze.react
  if BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) Spell(ebonbolt)
  #glacial_spike,if=buff.brain_freeze.react|prev_gcd.1.ebonbolt|talent.incanters_flow.enabled&cast_time+travel_time>incanters_flow_time_to.5.up&cast_time+travel_time<incanters_flow_time_to.4.down
  if BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) Spell(glacial_spike)
  #ice_nova
  Spell(ice_nova)
  #frostbolt
  Spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   Spell(ice_lance)
  }
 }
}

AddFunction FrostSingleMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostSingleShortCdActions
{
 unless SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #frozen_orb
   Spell(frozen_orb)

   unless { Enemies() > 2 or Enemies() > 1 and not Talent(splitting_ice_talent) } and Spell(blizzard)
   {
    #comet_storm
    Spell(comet_storm)

    unless BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) and Spell(ebonbolt) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostSingleShortCdPostConditions
{
 SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry) or FrostEssencesShortCdPostConditions() or { Enemies() > 2 or Enemies() > 1 and not Talent(splitting_ice_talent) } and Spell(blizzard) or BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) and Spell(ebonbolt) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostSingleCdActions
{
 unless SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or Spell(frozen_orb) or { Enemies() > 2 or Enemies() > 1 and not Talent(splitting_ice_talent) } and Spell(blizzard) or Spell(comet_storm) or BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) and Spell(ebonbolt) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) } and Spell(glacial_spike) or Spell(ice_nova)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()

   unless Spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostSingleCdPostConditions
{
 SpellCooldown(ice_nova) == 0 and target.DebuffPresent(winters_chill_debuff) and Spell(ice_nova) or Talent(ebonbolt_talent) and PreviousGCDSpell(ebonbolt) and BuffPresent(brain_freeze_buff) and Spell(flurry) or PreviousGCDSpell(glacial_spike) and BuffPresent(brain_freeze_buff) and Spell(flurry) or FrostEssencesCdPostConditions() or Spell(frozen_orb) or { Enemies() > 2 or Enemies() > 1 and not Talent(splitting_ice_talent) } and Spell(blizzard) or Spell(comet_storm) or BuffStacks(icicles_buff) == 5 and not BuffPresent(brain_freeze_buff) and Spell(ebonbolt) or { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) or Talent(incanters_flow_talent) and CastTime(glacial_spike) + TravelTime(glacial_spike) > StackTimeTo(incanters_flow_buff 5 up) and CastTime(glacial_spike) + TravelTime(glacial_spike) < StackTimeTo(incanters_flow_buff 4 down) } and Spell(glacial_spike) or Spell(ice_nova) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(ice_lance)
}

### actions.precombat

AddFunction FrostPrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 Spell(arcane_intellect)
 #frostbolt
 Spell(frostbolt)
}

AddFunction FrostPrecombatMainPostConditions
{
}

AddFunction FrostPrecombatShortCdActions
{
 unless Spell(arcane_intellect)
 {
  #summon_water_elemental
  if not pet.Present() Spell(summon_water_elemental)
 }
}

AddFunction FrostPrecombatShortCdPostConditions
{
 Spell(arcane_intellect) or Spell(frostbolt)
}

AddFunction FrostPrecombatCdActions
{
 unless Spell(arcane_intellect) or not pet.Present() and Spell(summon_water_elemental)
 {
  #snapshot_stats
  #use_item,name=azsharas_font_of_power
  FrostUseItemActions()
  #mirror_image
  Spell(mirror_image)
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
 }
}

AddFunction FrostPrecombatCdPostConditions
{
 Spell(arcane_intellect) or not pet.Present() and Spell(summon_water_elemental) or Spell(frostbolt)
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
 #blink_any,if=movement.distance>10
 if target.Distance() > 10 and CheckBoxOn(opt_blink) Spell(blink)
 #ice_floes,if=buff.ice_floes.down
 if BuffExpires(ice_floes_buff) and Speed() > 0 Spell(ice_floes)
}

AddFunction FrostMovementShortCdPostConditions
{
}

AddFunction FrostMovementCdActions
{
}

AddFunction FrostMovementCdPostConditions
{
 target.Distance() > 10 and CheckBoxOn(opt_blink) and Spell(blink) or BuffExpires(ice_floes_buff) and Speed() > 0 and Spell(ice_floes)
}

### actions.essences

AddFunction FrostEssencesMainActions
{
 #concentrated_flame,line_cd=6,if=buff.rune_of_power.down
 if TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesMainPostConditions
{
}

AddFunction FrostEssencesShortCdActions
{
 #focused_azerite_beam,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies() > 3 Spell(focused_azerite_beam)
 #purifying_blast,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies() > 3 Spell(purifying_blast)
 #ripple_in_space,if=buff.rune_of_power.down|active_enemies>3
 if BuffExpires(rune_of_power_buff) or Enemies() > 3 Spell(ripple_in_space_essence)

 unless TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and Spell(concentrated_flame_essence)
 {
  #the_unbound_force,if=buff.reckless_force.up
  if BuffPresent(reckless_force_buff) Spell(the_unbound_force)
  #worldvein_resonance,if=buff.rune_of_power.down|active_enemies>3
  if BuffExpires(rune_of_power_buff) or Enemies() > 3 Spell(worldvein_resonance_essence)
 }
}

AddFunction FrostEssencesShortCdPostConditions
{
 TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and Spell(concentrated_flame_essence)
}

AddFunction FrostEssencesCdActions
{
 unless { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(focused_azerite_beam)
 {
  #memory_of_lucid_dreams,if=active_enemies<5&(buff.icicles.stack<=1|!talent.glacial_spike.enabled)&cooldown.frozen_orb.remains>10
  if Enemies() < 5 and { BuffStacks(icicles_buff) <= 1 or not Talent(glacial_spike_talent) } and SpellCooldown(frozen_orb) > 10 Spell(memory_of_lucid_dreams_essence)
  #blood_of_the_enemy,if=(talent.glacial_spike.enabled&buff.icicles.stack=5&(buff.brain_freeze.react|prev_gcd.1.ebonbolt))|((active_enemies>3|!talent.glacial_spike.enabled)&(prev_gcd.1.frozen_orb|ground_aoe.frozen_orb.remains>5))
  if Talent(glacial_spike_talent) and BuffStacks(icicles_buff) == 5 and { BuffPresent(brain_freeze_buff) or PreviousGCDSpell(ebonbolt) } or { Enemies() > 3 or not Talent(glacial_spike_talent) } and { PreviousGCDSpell(frozen_orb) or target.DebuffRemaining(frozen_orb_debuff) > 5 } Spell(blood_of_the_enemy)
 }
}

AddFunction FrostEssencesCdPostConditions
{
 { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(focused_azerite_beam) or { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(purifying_blast) or { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(ripple_in_space_essence) or TimeSincePreviousSpell(concentrated_flame_essence) > 6 and BuffExpires(rune_of_power_buff) and Spell(concentrated_flame_essence) or BuffPresent(reckless_force_buff) and Spell(the_unbound_force) or { BuffExpires(rune_of_power_buff) or Enemies() > 3 } and Spell(worldvein_resonance_essence)
}

### actions.cooldowns

AddFunction FrostCooldownsMainActions
{
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropMainActions()
}

AddFunction FrostCooldownsMainPostConditions
{
 Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropMainPostConditions()
}

AddFunction FrostCooldownsShortCdActions
{
 #rune_of_power,if=prev_gcd.1.frozen_orb|target.time_to_die>10+cast_time&target.time_to_die<20
 if PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 Spell(rune_of_power)
 #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
 if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropShortCdActions()
}

AddFunction FrostCooldownsShortCdPostConditions
{
 Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropShortCdPostConditions()
}

AddFunction FrostCooldownsCdActions
{
 #guardian_of_azeroth
 Spell(guardian_of_azeroth)
 #icy_veins
 Spell(icy_veins)
 #mirror_image
 Spell(mirror_image)

 unless { PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 } and Spell(rune_of_power)
 {
  #call_action_list,name=talent_rop,if=talent.rune_of_power.enabled&active_enemies=1&cooldown.rune_of_power.full_recharge_time<cooldown.frozen_orb.remains
  if Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) FrostTalentropCdActions()

  unless Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropCdPostConditions()
  {
   #potion,if=prev_gcd.1.icy_veins|target.time_to_die<30
   if { PreviousGCDSpell(icy_veins) or target.TimeToDie() < 30 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
   #use_items
   FrostUseItemActions()
   #blood_fury
   Spell(blood_fury_sp)
   #berserking
   Spell(berserking)
   #lights_judgment
   Spell(lights_judgment)
   #fireblood
   Spell(fireblood)
   #ancestral_call
   Spell(ancestral_call)
  }
 }
}

AddFunction FrostCooldownsCdPostConditions
{
 { PreviousGCDSpell(frozen_orb) or target.TimeToDie() > 10 + CastTime(rune_of_power) and target.TimeToDie() < 20 } and Spell(rune_of_power) or Talent(rune_of_power_talent) and Enemies() == 1 and SpellCooldown(rune_of_power) < SpellCooldown(frozen_orb) and FrostTalentropCdPostConditions()
}

### actions.aoe

AddFunction FrostAoeMainActions
{
 #blizzard
 Spell(blizzard)
 #call_action_list,name=essences
 FrostEssencesMainActions()

 unless FrostEssencesMainPostConditions()
 {
  #ice_nova
  Spell(ice_nova)
  #flurry,if=prev_gcd.1.ebonbolt|buff.brain_freeze.react&(prev_gcd.1.frostbolt&(buff.icicles.stack<4|!talent.glacial_spike.enabled)|prev_gcd.1.glacial_spike)
  if PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } Spell(flurry)
  #ice_lance,if=buff.fingers_of_frost.react
  if BuffPresent(fingers_of_frost_buff) Spell(ice_lance)
  #ray_of_frost
  Spell(ray_of_frost)
  #ebonbolt
  Spell(ebonbolt)
  #glacial_spike
  Spell(glacial_spike)
  #frostbolt
  Spell(frostbolt)
  #call_action_list,name=movement
  FrostMovementMainActions()

  unless FrostMovementMainPostConditions()
  {
   #ice_lance
   Spell(ice_lance)
  }
 }
}

AddFunction FrostAoeMainPostConditions
{
 FrostEssencesMainPostConditions() or FrostMovementMainPostConditions()
}

AddFunction FrostAoeShortCdActions
{
 #frozen_orb
 Spell(frozen_orb)

 unless Spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesShortCdActions()

  unless FrostEssencesShortCdPostConditions()
  {
   #comet_storm
   Spell(comet_storm)

   unless Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike)
   {
    #cone_of_cold
    if target.Distance() < 12 Spell(cone_of_cold)

    unless Spell(frostbolt)
    {
     #call_action_list,name=movement
     FrostMovementShortCdActions()
    }
   }
  }
 }
}

AddFunction FrostAoeShortCdPostConditions
{
 Spell(blizzard) or FrostEssencesShortCdPostConditions() or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or Spell(frostbolt) or FrostMovementShortCdPostConditions() or Spell(ice_lance)
}

AddFunction FrostAoeCdActions
{
 unless Spell(frozen_orb) or Spell(blizzard)
 {
  #call_action_list,name=essences
  FrostEssencesCdActions()

  unless FrostEssencesCdPostConditions() or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or target.Distance() < 12 and Spell(cone_of_cold)
  {
   #use_item,name=tidestorm_codex,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()
   #use_item,effect_name=cyclotronic_blast,if=buff.icy_veins.down&buff.rune_of_power.down
   if BuffExpires(icy_veins_buff) and BuffExpires(rune_of_power_buff) FrostUseItemActions()

   unless Spell(frostbolt)
   {
    #call_action_list,name=movement
    FrostMovementCdActions()
   }
  }
 }
}

AddFunction FrostAoeCdPostConditions
{
 Spell(frozen_orb) or Spell(blizzard) or FrostEssencesCdPostConditions() or Spell(comet_storm) or Spell(ice_nova) or { PreviousGCDSpell(ebonbolt) or BuffPresent(brain_freeze_buff) and { PreviousGCDSpell(frostbolt) and { BuffStacks(icicles_buff) < 4 or not Talent(glacial_spike_talent) } or PreviousGCDSpell(glacial_spike) } } and Spell(flurry) or BuffPresent(fingers_of_frost_buff) and Spell(ice_lance) or Spell(ray_of_frost) or Spell(ebonbolt) or Spell(glacial_spike) or target.Distance() < 12 and Spell(cone_of_cold) or Spell(frostbolt) or FrostMovementCdPostConditions() or Spell(ice_lance)
}

### actions.default

AddFunction FrostDefaultMainActions
{
 #call_action_list,name=cooldowns
 FrostCooldownsMainActions()

 unless FrostCooldownsMainPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeMainActions()

  unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeMainPostConditions()
  {
   #call_action_list,name=single
   FrostSingleMainActions()
  }
 }
}

AddFunction FrostDefaultMainPostConditions
{
 FrostCooldownsMainPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeMainPostConditions() or FrostSingleMainPostConditions()
}

AddFunction FrostDefaultShortCdActions
{
 #call_action_list,name=cooldowns
 FrostCooldownsShortCdActions()

 unless FrostCooldownsShortCdPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeShortCdActions()

  unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeShortCdPostConditions()
  {
   #call_action_list,name=single
   FrostSingleShortCdActions()
  }
 }
}

AddFunction FrostDefaultShortCdPostConditions
{
 FrostCooldownsShortCdPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeShortCdPostConditions() or FrostSingleShortCdPostConditions()
}

AddFunction FrostDefaultCdActions
{
 #counterspell
 FrostInterruptActions()
 #call_action_list,name=cooldowns
 FrostCooldownsCdActions()

 unless FrostCooldownsCdPostConditions()
 {
  #call_action_list,name=aoe,if=active_enemies>3&talent.freezing_rain.enabled|active_enemies>4
  if Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 FrostAoeCdActions()

  unless { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeCdPostConditions()
  {
   #call_action_list,name=single
   FrostSingleCdActions()
  }
 }
}

AddFunction FrostDefaultCdPostConditions
{
 FrostCooldownsCdPostConditions() or { Enemies() > 3 and Talent(freezing_rain_talent) or Enemies() > 4 } and FrostAoeCdPostConditions() or FrostSingleCdPostConditions()
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
# ancestral_call
# arcane_intellect
# berserking
# blink
# blizzard
# blood_fury_sp
# blood_of_the_enemy
# brain_freeze_buff
# comet_storm
# comet_storm_talent
# concentrated_flame_essence
# cone_of_cold
# counterspell
# ebonbolt
# ebonbolt_talent
# fingers_of_frost_buff
# fireblood
# flurry
# focused_azerite_beam
# freezing_rain_talent
# frostbolt
# frozen_orb
# frozen_orb_debuff
# glacial_spike
# glacial_spike_talent
# guardian_of_azeroth
# ice_floes
# ice_floes_buff
# ice_lance
# ice_nova
# icicles_buff
# icy_veins
# icy_veins_buff
# incanters_flow_talent
# item_unbridled_fury
# lights_judgment
# memory_of_lucid_dreams_essence
# mirror_image
# purifying_blast
# quaking_palm
# ray_of_frost
# ray_of_frost_talent
# reckless_force_buff
# ripple_in_space_essence
# rune_of_power
# rune_of_power_buff
# rune_of_power_talent
# splitting_ice_talent
# summon_water_elemental
# the_unbound_force
# winters_chill_debuff
# worldvein_resonance_essence
]]
        OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
    end
end
