local __exports = LibStub:GetLibrary("ovale/scripts/ovale_mage")
if not __exports then return end
__exports.registerMageArcaneXeltor = function(OvaleScripts)
do
	local name = "xeltor_arcane"
	local desc = "[Xel][8.0] Mage: Arcane"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_mage_spells)

# Arcane
AddIcon specialization=1 help=main
{
	if not mounted() and not PlayerIsResting() and not IsDead()
	{
		#arcane_intellect
		if not BuffPresent(arcane_intellect_buff any=1) and not target.IsFriend() Spell(arcane_intellect)
		if not target.BuffPresent(arcane_intellect_buff any=1) and target.IsFriend() Spell(arcane_intellect)
		#summon_arcane_familiar
		if not BuffPresent(arcane_familiar_buff) Spell(summon_arcane_familiar)
	}
	
	if InCombat() and not target.IsFriend() SafetyDance()
	if InCombat() InterruptActions()
	
	if InCombat() and target.InRange(arcane_blast) and HasFullControl()
	{
		ArcaneDefaultCdActions()
		
		ArcaneDefaultShortCdActions()
		
		ArcaneDefaultMainActions()
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(counterspell) and target.IsInterruptible() Spell(counterspell)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
	}
}

AddFunction SafetyDance
{
	if target.istargetingplayer() and { target.distance() <= 8 or IncomingDamage(3) >= MaxHealth() * 0.01 } and not BuffPresent(prismatic_barrier_buff) Spell(prismatic_barrier)
	if target.InRange(slow) and target.DebuffRemains(slow_debuff) <= 2 and not target.DebuffPresent(frost_nova_debuff) and target.IsPvP() and not IsBossFight() Spell(slow)
	if target.Distance(less 12) and not target.DebuffPresent(frost_nova_debuff) and target.IsPvP() and not IsBossFight() Spell(frost_nova)
	if target.BuffStealable() and target.InRange(spellsteal) Spell(spellsteal)
}

AddFunction NotMoving
{
	{ Speed() == 0 or Talent(slipstream_talent) }
}

AddFunction total_burns
{
 if not GetState(burn_phase) > 0 1
}

AddFunction conserve_mana
{
 60
}

AddFunction average_burn_length
{
 { 0 * total_burns() - 0 + GetStateDuration(burn_phase) } / total_burns()
}

AddFunction ArcaneUseItemActions
{
 if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
 if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction ArcaneDefaultMainActions
{
 #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
 if { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() ArcaneBurnMainActions()

 unless { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() and ArcaneBurnMainPostConditions()
 {
  #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
  if not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() ArcaneBurnMainActions()

  unless not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() and ArcaneBurnMainPostConditions()
  {
   #call_action_list,name=conserve,if=!burn_phase
   if not GetState(burn_phase) > 0 ArcaneConserveMainActions()

   unless not GetState(burn_phase) > 0 and ArcaneConserveMainPostConditions()
   {
    #call_action_list,name=movement
    if Speed() >= 0 ArcaneMovementMainActions()
   }
  }
 }
}

AddFunction ArcaneDefaultMainPostConditions
{
 { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() and ArcaneBurnMainPostConditions() or not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() and ArcaneBurnMainPostConditions() or not GetState(burn_phase) > 0 and ArcaneConserveMainPostConditions() or ArcaneMovementMainPostConditions()
}

AddFunction ArcaneDefaultShortCdActions
{
 #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
 if { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() ArcaneBurnShortCdActions()

 unless { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() and ArcaneBurnShortCdPostConditions()
 {
  #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
  if not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() ArcaneBurnShortCdActions()

  unless not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() and ArcaneBurnShortCdPostConditions()
  {
   #call_action_list,name=conserve,if=!burn_phase
   if not GetState(burn_phase) > 0 ArcaneConserveShortCdActions()

   unless not GetState(burn_phase) > 0 and ArcaneConserveShortCdPostConditions()
   {
    #call_action_list,name=movement
    if Speed() >= 0 ArcaneMovementShortCdActions()
   }
  }
 }
}

AddFunction ArcaneDefaultShortCdPostConditions
{
 { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() and ArcaneBurnShortCdPostConditions() or not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() and ArcaneBurnShortCdPostConditions() or not GetState(burn_phase) > 0 and ArcaneConserveShortCdPostConditions() or ArcaneMovementShortCdPostConditions()
}

AddFunction ArcaneDefaultCdActions
{
 #counterspell,if=target.debuff.casting.react
 # if target.IsInterruptible() ArcaneInterruptActions()
 #call_action_list,name=burn,if=burn_phase|target.time_to_die<variable.average_burn_length
 if { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() ArcaneBurnCdActions()

 unless { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() and ArcaneBurnCdPostConditions()
 {
  #call_action_list,name=burn,if=(cooldown.arcane_power.remains=0&cooldown.evocation.remains<=variable.average_burn_length&(buff.arcane_charge.stack=buff.arcane_charge.max_stack|(talent.charged_up.enabled&cooldown.charged_up.remains=0&buff.arcane_charge.stack<=1)))
  if not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() ArcaneBurnCdActions()

  unless not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() and ArcaneBurnCdPostConditions()
  {
   #call_action_list,name=conserve,if=!burn_phase
   if not GetState(burn_phase) > 0 ArcaneConserveCdActions()

   unless not GetState(burn_phase) > 0 and ArcaneConserveCdPostConditions()
   {
    #call_action_list,name=movement
    if Speed() >= 0 ArcaneMovementCdActions()
   }
  }
 }
}

AddFunction ArcaneDefaultCdPostConditions
{
 { GetState(burn_phase) > 0 or target.TimeToDie() < average_burn_length() } and Boss() and ArcaneBurnCdPostConditions() or not SpellCooldown(arcane_power) > 0 and SpellCooldown(evocation) <= average_burn_length() and { ArcaneCharges() == MaxArcaneCharges() or Talent(charged_up_talent) and not SpellCooldown(charged_up) > 0 and ArcaneCharges() <= 1 } and Boss() and ArcaneBurnCdPostConditions() or not GetState(burn_phase) > 0 and ArcaneConserveCdPostConditions() or ArcaneMovementCdPostConditions()
}

### actions.burn

AddFunction ArcaneBurnMainActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not GetState(burn_phase) > 0 and not GetState(burn_phase) > 0 SetState(burn_phase 1)
 #stop_burn_phase,if=burn_phase&prev_gcd.1.evocation&target.time_to_die>variable.average_burn_length&burn_phase_duration>0
 if GetState(burn_phase) > 0 and PreviousGCDSpell(evocation) and target.TimeToDie() > average_burn_length() and GetStateDuration(burn_phase) > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)
 #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.rune_of_power.down&buff.arcane_power.down
 if { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(nether_tempest)
 #arcane_blast,if=buff.rule_of_threes.up&talent.overpowered.enabled&active_enemies<3
 if BuffPresent(rule_of_threes_buff) and Talent(overpowered_talent) and Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } Spell(arcane_blast)
 #arcane_barrage,if=active_enemies>=3&(buff.arcane_charge.stack=buff.arcane_charge.max_stack)
 if Enemies(tagged=1) >= 3 and ArcaneCharges() == MaxArcaneCharges() Spell(arcane_barrage)
 #arcane_explosion,if=active_enemies>=3
 if Enemies(tagged=1) >= 3 and target.Distance(less 10) Spell(arcane_explosion)
 #arcane_missiles,if=buff.clearcasting.react&active_enemies<3&(talent.amplification.enabled|(!talent.overpowered.enabled&azerite.arcane_pummeling.rank>=2)|buff.arcane_power.down),chain=1
 if BuffPresent(clearcasting_buff) and Enemies(tagged=1) < 3 and { Talent(amplification_talent) or not Talent(overpowered_talent) and AzeriteTraitRank(arcane_pummeling_trait) >= 2 or BuffExpires(arcane_power_buff) } and { Speed() == 0 or Talent(slipstream_talent) } Spell(arcane_missiles)
 #arcane_blast,if=active_enemies<3
 if Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } Spell(arcane_blast)
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
 if GetState(burn_phase) > 0 and PreviousGCDSpell(evocation) and target.TimeToDie() > average_burn_length() and GetStateDuration(burn_phase) > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)
 #charged_up,if=buff.arcane_charge.stack<=1
 if ArcaneCharges() <= 1 Spell(charged_up)

 unless { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes_buff) and Talent(overpowered_talent) and Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast)
 {
  #rune_of_power,if=!buff.arcane_power.up&(mana.pct>=50|cooldown.arcane_power.remains=0)&(buff.arcane_charge.stack=buff.arcane_charge.max_stack)
  if not BuffPresent(arcane_power_buff) and { ManaPercent() >= 50 or not SpellCooldown(arcane_power) > 0 } and ArcaneCharges() == MaxArcaneCharges() and { Speed() == 0 or CastTime(rune_of_power) <= 0 } Spell(rune_of_power)
  #presence_of_mind,if=buff.rune_of_power.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time|buff.arcane_power.remains<=buff.presence_of_mind.max_stack*action.arcane_blast.execute_time
  if TotemRemaining(rune_of_power) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) or BuffRemaining(arcane_power_buff) <= SpellData(presence_of_mind_buff max_stacks) * ExecuteTime(arcane_blast) Spell(presence_of_mind)
  #arcane_orb,if=buff.arcane_charge.stack=0|(active_enemies<3|(active_enemies<2&talent.resonance.enabled))
  if ArcaneCharges() == 0 or Enemies(tagged=1) < 3 or Enemies(tagged=1) < 2 and Talent(resonance_talent) Spell(arcane_orb)
 }
}

AddFunction ArcaneBurnShortCdPostConditions
{
 { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes_buff) and Talent(overpowered_talent) and Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast) or Enemies(tagged=1) >= 3 and ArcaneCharges() == MaxArcaneCharges() and Spell(arcane_barrage) or Enemies(tagged=1) >= 3 and target.Distance(less 10) and Spell(arcane_explosion) or BuffPresent(clearcasting_buff) and Enemies(tagged=1) < 3 and { Talent(amplification_talent) or not Talent(overpowered_talent) and AzeriteTraitRank(arcane_pummeling_trait) >= 2 or BuffExpires(arcane_power_buff) } and { Speed() == 0 or Talent(slipstream_talent) } and Spell(arcane_missiles) or Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast) or Spell(arcane_barrage)
}

AddFunction ArcaneBurnCdActions
{
 #variable,name=total_burns,op=add,value=1,if=!burn_phase
 #start_burn_phase,if=!burn_phase
 if not GetState(burn_phase) > 0 and not GetState(burn_phase) > 0 SetState(burn_phase 1)
 #stop_burn_phase,if=burn_phase&prev_gcd.1.evocation&target.time_to_die>variable.average_burn_length&burn_phase_duration>0
 if GetState(burn_phase) > 0 and PreviousGCDSpell(evocation) and target.TimeToDie() > average_burn_length() and GetStateDuration(burn_phase) > 0 and GetState(burn_phase) > 0 SetState(burn_phase 0)

 unless ArcaneCharges() <= 1 and Spell(charged_up)
 {
  #mirror_image
  Spell(mirror_image)

  unless { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes_buff) and Talent(overpowered_talent) and Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast)
  {
   #lights_judgment,if=buff.arcane_power.down
   if BuffExpires(arcane_power_buff) Spell(lights_judgment)

   unless not BuffPresent(arcane_power_buff) and { ManaPercent() >= 50 or not SpellCooldown(arcane_power) > 0 } and ArcaneCharges() == MaxArcaneCharges() and { Speed() == 0 or CastTime(rune_of_power) <= 0 } and Spell(rune_of_power)
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
    #potion,if=buff.arcane_power.up&(buff.berserking.up|buff.blood_fury.up|!(race.troll|race.orc))
    # if BuffPresent(arcane_power_buff) and { BuffPresent(berserking_buff) or BuffPresent(blood_fury_sp_buff) or not { Race(Troll) or Race(Orc) } } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)

    unless { ArcaneCharges() == 0 or Enemies(tagged=1) < 3 or Enemies(tagged=1) < 2 and Talent(resonance_talent) } and Spell(arcane_orb) or Enemies(tagged=1) >= 3 and ArcaneCharges() == MaxArcaneCharges() and Spell(arcane_barrage) or Enemies(tagged=1) >= 3 and target.Distance(less 10) and Spell(arcane_explosion) or BuffPresent(clearcasting_buff) and Enemies(tagged=1) < 3 and { Talent(amplification_talent) or not Talent(overpowered_talent) and AzeriteTraitRank(arcane_pummeling_trait) >= 2 or BuffExpires(arcane_power_buff) } and { Speed() == 0 or Talent(slipstream_talent) } and Spell(arcane_missiles) or Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast)
    {
     #variable,name=average_burn_length,op=set,value=(variable.average_burn_length*variable.total_burns-variable.average_burn_length+(burn_phase_duration))%variable.total_burns
     #evocation,interrupt_if=mana.pct>=85,interrupt_immediate=1
     if Speed() == 0 or Talent(slipstream_talent) Spell(evocation)
    }
   }
  }
 }
}

AddFunction ArcaneBurnCdPostConditions
{
 ArcaneCharges() <= 1 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes_buff) and Talent(overpowered_talent) and Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast) or not BuffPresent(arcane_power_buff) and { ManaPercent() >= 50 or not SpellCooldown(arcane_power) > 0 } and ArcaneCharges() == MaxArcaneCharges() and { Speed() == 0 or CastTime(rune_of_power) <= 0 } and Spell(rune_of_power) or { ArcaneCharges() == 0 or Enemies(tagged=1) < 3 or Enemies(tagged=1) < 2 and Talent(resonance_talent) } and Spell(arcane_orb) or Enemies(tagged=1) >= 3 and ArcaneCharges() == MaxArcaneCharges() and Spell(arcane_barrage) or Enemies(tagged=1) >= 3 and target.Distance(less 10) and Spell(arcane_explosion) or BuffPresent(clearcasting_buff) and Enemies(tagged=1) < 3 and { Talent(amplification_talent) or not Talent(overpowered_talent) and AzeriteTraitRank(arcane_pummeling_trait) >= 2 or BuffExpires(arcane_power_buff) } and { Speed() == 0 or Talent(slipstream_talent) } and Spell(arcane_missiles) or Enemies(tagged=1) < 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast) or Spell(arcane_barrage)
}

### actions.conserve

AddFunction ArcaneConserveMainActions
{
 #nether_tempest,if=(refreshable|!ticking)&buff.arcane_charge.stack=buff.arcane_charge.max_stack&buff.rune_of_power.down&buff.arcane_power.down
 if { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) Spell(nether_tempest)
 #arcane_blast,if=buff.rule_of_threes.up&buff.arcane_charge.stack>3
 if BuffPresent(rule_of_threes_buff) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } Spell(arcane_blast)
 #arcane_missiles,if=mana.pct<=95&buff.clearcasting.react,chain=1
 if ManaPercent() <= 95 and BuffPresent(clearcasting_buff) and { Speed() == 0 or Talent(slipstream_talent) } Spell(arcane_missiles)
 #arcane_barrage,if=((buff.arcane_charge.stack=buff.arcane_charge.max_stack)&((mana.pct<=variable.conserve_mana)|(cooldown.arcane_power.remains>cooldown.rune_of_power.full_recharge_time&mana.pct<=variable.conserve_mana+25))|(talent.arcane_orb.enabled&cooldown.arcane_orb.remains<=gcd&cooldown.arcane_power.remains>10))|mana.pct<=(variable.conserve_mana-10)
 if ArcaneCharges() == MaxArcaneCharges() and { ManaPercent() <= conserve_mana() or SpellCooldown(arcane_power) > SpellCooldown(rune_of_power) and ManaPercent() <= conserve_mana() + 25 } or Talent(arcane_orb_talent) and SpellCooldown(arcane_orb) <= GCD() and SpellCooldown(arcane_power) > 10 or ManaPercent() <= conserve_mana() - 10 Spell(arcane_barrage)
 #supernova,if=mana.pct<=95
 if ManaPercent() <= 95 Spell(supernova)
 #arcane_explosion,if=active_enemies>=3&(mana.pct>=variable.conserve_mana|buff.arcane_charge.stack=3)
 if Enemies(tagged=1) >= 3 and { ManaPercent() >= conserve_mana() or ArcaneCharges() == 3 } and target.Distance(less 10) Spell(arcane_explosion)
 #arcane_blast
 if Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } Spell(arcane_blast)
 #arcane_barrage
 Spell(arcane_barrage)
}

AddFunction ArcaneConserveMainPostConditions
{
}

AddFunction ArcaneConserveShortCdActions
{
 #charged_up,if=buff.arcane_charge.stack=0
 if ArcaneCharges() == 0 Spell(charged_up)

 unless { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest)
 {
  #arcane_orb,if=buff.arcane_charge.stack<=2&(cooldown.arcane_power.remains>10|active_enemies<=2)
  if ArcaneCharges() <= 2 and { SpellCooldown(arcane_power) > 10 or Enemies(tagged=1) <= 2 } Spell(arcane_orb)

  unless BuffPresent(rule_of_threes_buff) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast)
  {
   #rune_of_power,if=buff.arcane_charge.stack=buff.arcane_charge.max_stack&(full_recharge_time<=execute_time|full_recharge_time<=cooldown.arcane_power.remains|target.time_to_die<=cooldown.arcane_power.remains)
   if ArcaneCharges() == MaxArcaneCharges() and { SpellFullRecharge(rune_of_power) <= ExecuteTime(rune_of_power) or SpellFullRecharge(rune_of_power) <= SpellCooldown(arcane_power) or target.TimeToDie() <= SpellCooldown(arcane_power) } Spell(rune_of_power)
  }
 }
}

AddFunction ArcaneConserveShortCdPostConditions
{
 { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or BuffPresent(rule_of_threes_buff) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast) or ManaPercent() <= 95 and BuffPresent(clearcasting_buff) and { Speed() == 0 or Talent(slipstream_talent) } and Spell(arcane_missiles) or { ArcaneCharges() == MaxArcaneCharges() and { ManaPercent() <= conserve_mana() or SpellCooldown(arcane_power) > SpellCooldown(rune_of_power) and ManaPercent() <= conserve_mana() + 25 } or Talent(arcane_orb_talent) and SpellCooldown(arcane_orb) <= GCD() and SpellCooldown(arcane_power) > 10 or ManaPercent() <= conserve_mana() - 10 } and Spell(arcane_barrage) or ManaPercent() <= 95 and Spell(supernova) or Enemies(tagged=1) >= 3 and { ManaPercent() >= conserve_mana() or ArcaneCharges() == 3 } and target.Distance(less 10) and Spell(arcane_explosion) or Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast) or Spell(arcane_barrage)
}

AddFunction ArcaneConserveCdActions
{
 #mirror_image
 Spell(mirror_image)
}

AddFunction ArcaneConserveCdPostConditions
{
 ArcaneCharges() == 0 and Spell(charged_up) or { target.Refreshable(nether_tempest_debuff) or not target.DebuffPresent(nether_tempest_debuff) } and ArcaneCharges() == MaxArcaneCharges() and BuffExpires(rune_of_power_buff) and BuffExpires(arcane_power_buff) and Spell(nether_tempest) or ArcaneCharges() <= 2 and { SpellCooldown(arcane_power) > 10 or Enemies(tagged=1) <= 2 } and Spell(arcane_orb) or BuffPresent(rule_of_threes_buff) and ArcaneCharges() > 3 and Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast) or ArcaneCharges() == MaxArcaneCharges() and { SpellFullRecharge(rune_of_power) <= ExecuteTime(rune_of_power) or SpellFullRecharge(rune_of_power) <= SpellCooldown(arcane_power) or target.TimeToDie() <= SpellCooldown(arcane_power) } and Spell(rune_of_power) or ManaPercent() <= 95 and BuffPresent(clearcasting_buff) and { Speed() == 0 or Talent(slipstream_talent) } and Spell(arcane_missiles) or { ArcaneCharges() == MaxArcaneCharges() and { ManaPercent() <= conserve_mana() or SpellCooldown(arcane_power) > SpellCooldown(rune_of_power) and ManaPercent() <= conserve_mana() + 25 } or Talent(arcane_orb_talent) and SpellCooldown(arcane_orb) <= GCD() and SpellCooldown(arcane_power) > 10 or ManaPercent() <= conserve_mana() - 10 } and Spell(arcane_barrage) or ManaPercent() <= 95 and Spell(supernova) or Enemies(tagged=1) >= 3 and { ManaPercent() >= conserve_mana() or ArcaneCharges() == 3 } and target.Distance(less 10) and Spell(arcane_explosion) or Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } and Spell(arcane_blast) or Spell(arcane_barrage)
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
 #shimmer,if=movement.distance>=10
 # if target.Distance() >= 10 Spell(shimmer)
 #blink,if=movement.distance>=10
 # if target.Distance() >= 10 Spell(blink)
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
 target.Distance() >= 10 and Spell(blink) or Spell(arcane_missiles) or Spell(arcane_orb) or Spell(supernova)
}

### actions.precombat

AddFunction ArcanePrecombatMainActions
{
 #flask
 #food
 #augmentation
 #arcane_intellect
 Spell(arcane_intellect)
 #summon_arcane_familiar
 Spell(arcane_familiar)
 #arcane_blast
 if Mana() > ManaCost(arcane_blast) and { Speed() == 0 or CastTime(arcane_blast) <= 0 } Spell(arcane_blast)
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
  #variable,name=conserve_mana,op=set,value=60
  #snapshot_stats
  #mirror_image
  Spell(mirror_image)
  #potion
  # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_intellect usable=1)
 }
}

AddFunction ArcanePrecombatCdPostConditions
{
 Spell(arcane_intellect) or Spell(arcane_familiar) or Mana() > ManaCost(arcane_blast) and Spell(arcane_blast)
}
]]

		OvaleScripts:RegisterScript("MAGE", "arcane", name, desc, code, "script")
	end
end