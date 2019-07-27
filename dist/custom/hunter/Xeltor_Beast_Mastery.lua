local __exports = LibStub:GetLibrary("ovale/scripts/ovale_hunter")
if not __exports then return end
__exports.registerHunterBeastMasteryXeltor = function(OvaleScripts)
do
	local name = "xeltor_beast_mastery"
	local desc = "[Xel][8.2] Hunter: Beast Mastery"
	local code = [[
# Common functions.
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddIcon specialization=1 help=main
{
	# Silence
	if InCombat() and { not target.IsFriend() or target.IsPvP() }
	{
		InterruptActions()
	}
	
	if HasFullControl() and InCombat() and target.Present() and target.InRange(cobra_shot)
	{
		# Pet we needs it.
		SummonPet()
		if { not IsDead() and not Dead() and HealthPercent() < 50 } or { not pet.IsDead() and pet.HealthPercent() < 15 } Spell(exhilaration)
	
		# Cooldowns
		if Boss() BeastMasteryDefaultCdActions()
		
		# Short Cooldowns
		BeastMasteryDefaultShortCdActions()
		
		# Default Actions
		BeastMasteryDefaultMainActions()
	}
}

# Custom functions.
AddFunction SummonPet
{
 if pet.HealthPercent() <= 0 and pet.Exists()
 {
  if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
  if Spell(revive_pet) Spell(revive_pet)
 }
 if not pet.HealthPercent() <= 0 and pet.HealthPercent() < 85 and not pet.BuffStacks(mend_pet) and pet.InRange(mend_pet) Spell(mend_pet)
 if not pet.Present() and not pet.Exists() and not PreviousSpell(revive_pet) Texture(icon_orangebird_toy)
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(counter_shot) and target.IsInterruptible() Spell(counter_shot)
	}
}

AddFunction BeastMasteryUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction BeastMasteryDefaultMainActions
{
 #call_action_list,name=cds
 BeastMasteryCdsMainActions()

 unless BeastMasteryCdsMainPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if Enemies(tagged=1) < 2 BeastMasteryStMainActions()

  unless Enemies(tagged=1) < 2 and BeastMasteryStMainPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if Enemies(tagged=1) > 1 BeastMasteryCleaveMainActions()
  }
 }
}

AddFunction BeastMasteryDefaultMainPostConditions
{
 BeastMasteryCdsMainPostConditions() or Enemies(tagged=1) < 2 and BeastMasteryStMainPostConditions() or Enemies(tagged=1) > 1 and BeastMasteryCleaveMainPostConditions()
}

AddFunction BeastMasteryDefaultShortCdActions
{
 #call_action_list,name=cds
 BeastMasteryCdsShortCdActions()

 unless BeastMasteryCdsShortCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if Enemies(tagged=1) < 2 BeastMasteryStShortCdActions()

  unless Enemies(tagged=1) < 2 and BeastMasteryStShortCdPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if Enemies(tagged=1) > 1 BeastMasteryCleaveShortCdActions()
  }
 }
}

AddFunction BeastMasteryDefaultShortCdPostConditions
{
 BeastMasteryCdsShortCdPostConditions() or Enemies(tagged=1) < 2 and BeastMasteryStShortCdPostConditions() or Enemies(tagged=1) > 1 and BeastMasteryCleaveShortCdPostConditions()
}

AddFunction BeastMasteryDefaultCdActions
{
 # BeastMasteryInterruptActions()
 #auto_shot
 #use_items
 BeastMasteryUseItemActions()
 #call_action_list,name=cds
 BeastMasteryCdsCdActions()

 unless BeastMasteryCdsCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<2
  if Enemies(tagged=1) < 2 BeastMasteryStCdActions()

  unless Enemies(tagged=1) < 2 and BeastMasteryStCdPostConditions()
  {
   #call_action_list,name=cleave,if=active_enemies>1
   if Enemies(tagged=1) > 1 BeastMasteryCleaveCdActions()
  }
 }
}

AddFunction BeastMasteryDefaultCdPostConditions
{
 BeastMasteryCdsCdPostConditions() or Enemies(tagged=1) < 2 and BeastMasteryStCdPostConditions() or Enemies(tagged=1) > 1 and BeastMasteryCleaveCdPostConditions()
}

### actions.cds

AddFunction BeastMasteryCdsMainActions
{
}

AddFunction BeastMasteryCdsMainPostConditions
{
}

AddFunction BeastMasteryCdsShortCdActions
{
 #worldvein_resonance
 Spell(worldvein_resonance)
 #ripple_in_space
 Spell(ripple_in_space)
}

AddFunction BeastMasteryCdsShortCdPostConditions
{
}

AddFunction BeastMasteryCdsCdActions
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
 # if { BuffPresent(bestial_wrath_buff) and BuffPresent(aspect_of_the_wild_buff) and { target.HealthPercent() < 35 or not Talent(killer_instinct_talent) } or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)

 unless Spell(worldvein_resonance)
 {
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)

  unless Spell(ripple_in_space)
  {
   #memory_of_lucid_dreams
   Spell(memory_of_lucid_dreams)
  }
 }
}

AddFunction BeastMasteryCdsCdPostConditions
{
 Spell(worldvein_resonance) or Spell(ripple_in_space)
}

### actions.cleave

AddFunction BeastMasteryCleaveMainActions
{
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max
 if pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() Spell(barbed_shot)
 #multishot,if=gcd.max-pet.cat.buff.beast_cleave.remains>0.25
 if GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 Spell(multishot_bm)
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=full_recharge_time<gcd.max&cooldown.bestial_wrath.remains
 if SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 Spell(barbed_shot)
 #kill_command,if=active_enemies<4|!azerite.rapid_reload.enabled
 if { Enemies(tagged=1) < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() Spell(kill_command)
 #dire_beast
 Spell(dire_beast)
 #barbed_shot,target_if=min:dot.barbed_shot.remains,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.cat.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|charges_fractional>1.4|target.time_to_die<9
 if pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 Spell(barbed_shot)
 #multishot,if=azerite.rapid_reload.enabled&active_enemies>2
 if HasAzeriteTrait(rapid_reload_trait) and Enemies(tagged=1) > 2 Spell(multishot_bm)
 #cobra_shot,if=cooldown.kill_command.remains>focus.time_to_max&(active_enemies<3|!azerite.rapid_reload.enabled)
 if SpellCooldown(kill_command) > TimeToMaxFocus() and { Enemies(tagged=1) < 3 or not HasAzeriteTrait(rapid_reload_trait) } Spell(cobra_shot)
}

AddFunction BeastMasteryCleaveMainPostConditions
{
}

AddFunction BeastMasteryCleaveShortCdActions
{
 unless pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 and Spell(barbed_shot)
 {
  #bestial_wrath,if=cooldown.aspect_of_the_wild.remains_guess>20|talent.one_with_the_pack.enabled|target.time_to_die<15
  if SpellCooldown(aspect_of_the_wild) > 20 or Talent(one_with_the_pack_talent) or target.TimeToDie() < 15 Spell(bestial_wrath)
  #chimaera_shot
  Spell(chimaera_shot)
  #a_murder_of_crows
  Spell(a_murder_of_crows)
  #barrage
  Spell(barrage)

  unless { Enemies(tagged=1) < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 } and Spell(barbed_shot)
  {
   #purifying_blast
   Spell(purifying_blast)
   #concentrated_flame
   Spell(concentrated_flame)
   #blood_of_the_enemy
   Spell(blood_of_the_enemy)
   #the_unbound_force
   Spell(the_unbound_force)

   unless HasAzeriteTrait(rapid_reload_trait) and Enemies(tagged=1) > 2 and Spell(multishot_bm) or SpellCooldown(kill_command) > TimeToMaxFocus() and { Enemies(tagged=1) < 3 or not HasAzeriteTrait(rapid_reload_trait) } and Spell(cobra_shot)
   {
    #spitting_cobra
    Spell(spitting_cobra)
   }
  }
 }
}

AddFunction BeastMasteryCleaveShortCdPostConditions
{
 pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 and Spell(barbed_shot) or { Enemies(tagged=1) < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 } and Spell(barbed_shot) or HasAzeriteTrait(rapid_reload_trait) and Enemies(tagged=1) > 2 and Spell(multishot_bm) or SpellCooldown(kill_command) > TimeToMaxFocus() and { Enemies(tagged=1) < 3 or not HasAzeriteTrait(rapid_reload_trait) } and Spell(cobra_shot)
}

AddFunction BeastMasteryCleaveCdActions
{
 unless pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 and Spell(barbed_shot)
 {
  #aspect_of_the_wild
  Spell(aspect_of_the_wild)
  #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
  if BuffPresent(aspect_of_the_wild_buff) and BuffPresent(bestial_wrath_buff) or target.TimeToDie() < 15 Spell(stampede)

  unless { SpellCooldown(aspect_of_the_wild) > 20 or Talent(one_with_the_pack_talent) or target.TimeToDie() < 15 } and Spell(bestial_wrath) or Spell(a_murder_of_crows) or Spell(barrage) or { Enemies(tagged=1) < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 } and Spell(barbed_shot)
  {
   #focused_azerite_beam
   Spell(focused_azerite_beam)
  }
 }
}

AddFunction BeastMasteryCleaveCdPostConditions
{
 pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() and Spell(barbed_shot) or GCD() - pet.BuffRemaining(pet_beast_cleave_buff) > 0.25 and Spell(multishot_bm) or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 and Spell(barbed_shot) or { SpellCooldown(aspect_of_the_wild) > 20 or Talent(one_with_the_pack_talent) or target.TimeToDie() < 15 } and Spell(bestial_wrath) or Spell(a_murder_of_crows) or Spell(barrage) or { Enemies(tagged=1) < 4 or not HasAzeriteTrait(rapid_reload_trait) } and pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or Charges(barbed_shot count=0) > 1.4 or target.TimeToDie() < 9 } and Spell(barbed_shot) or Spell(purifying_blast) or Spell(concentrated_flame) or Spell(blood_of_the_enemy) or Spell(the_unbound_force) or HasAzeriteTrait(rapid_reload_trait) and Enemies(tagged=1) > 2 and Spell(multishot_bm) or SpellCooldown(kill_command) > TimeToMaxFocus() and { Enemies(tagged=1) < 3 or not HasAzeriteTrait(rapid_reload_trait) } and Spell(cobra_shot) or Spell(spitting_cobra)
}

### actions.precombat

AddFunction BeastMasteryPrecombatMainActions
{
}

AddFunction BeastMasteryPrecombatMainPostConditions
{
}

AddFunction BeastMasteryPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #summon_pet
 # BeastMasterySummonPet()
 #worldvein_resonance
 Spell(worldvein_resonance)
 #bestial_wrath,precast_time=1.5,if=azerite.primal_instincts.enabled
 if HasAzeriteTrait(primal_instincts_trait) Spell(bestial_wrath)
}

AddFunction BeastMasteryPrecombatShortCdPostConditions
{
}

AddFunction BeastMasteryPrecombatCdActions
{
 #snapshot_stats
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_agility usable=1)

 unless Spell(worldvein_resonance)
 {
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)
  #memory_of_lucid_dreams
  Spell(memory_of_lucid_dreams)
  #aspect_of_the_wild,precast_time=1.1,if=!azerite.primal_instincts.enabled
  if not HasAzeriteTrait(primal_instincts_trait) Spell(aspect_of_the_wild)
 }
}

AddFunction BeastMasteryPrecombatCdPostConditions
{
 Spell(worldvein_resonance) or HasAzeriteTrait(primal_instincts_trait) and Spell(bestial_wrath)
}

### actions.st

AddFunction BeastMasteryStMainActions
{
 #barbed_shot,if=pet.cat.buff.frenzy.up&pet.cat.buff.frenzy.remains<=gcd.max|full_recharge_time<gcd.max&cooldown.bestial_wrath.remains|azerite.primal_instincts.enabled&cooldown.aspect_of_the_wild.remains<gcd
 if pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() Spell(barbed_shot)
 #kill_command
 if pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() Spell(kill_command)
 #dire_beast
 Spell(dire_beast)
 #barbed_shot,if=pet.cat.buff.frenzy.down&(charges_fractional>1.8|buff.bestial_wrath.up)|cooldown.aspect_of_the_wild.remains<pet.cat.buff.frenzy.duration-gcd&azerite.primal_instincts.enabled|azerite.dance_of_death.rank>1&buff.dance_of_death.down&crit_pct_current>40|target.time_to_die<9
 if pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 Spell(barbed_shot)
 #cobra_shot,if=(focus-cost+focus.regen*(cooldown.kill_command.remains-1)>action.kill_command.cost|cooldown.kill_command.remains>1+gcd|buff.memory_of_lucid_dreams.up)&cooldown.kill_command.remains>1
 if { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() or DebuffPresent(memory_of_lucid_dreams) } and SpellCooldown(kill_command) > 1 Spell(cobra_shot)
 #barbed_shot,if=charges_fractional>1.4
 if Charges(barbed_shot count=0) > 1.4 Spell(barbed_shot)
}

AddFunction BeastMasteryStMainPostConditions
{
}

AddFunction BeastMasteryStShortCdActions
{
 unless { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } and Spell(barbed_shot)
 {
  #a_murder_of_crows
  Spell(a_murder_of_crows)
  #bestial_wrath,if=cooldown.aspect_of_the_wild.remains>20|target.time_to_die<15
  if SpellCooldown(aspect_of_the_wild) > 20 or target.TimeToDie() < 15 Spell(bestial_wrath)

  unless pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command)
  {
   #chimaera_shot
   Spell(chimaera_shot)

   unless Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 } and Spell(barbed_shot)
   {
    #purifying_blast
    Spell(purifying_blast)
    #concentrated_flame
    Spell(concentrated_flame)
    #blood_of_the_enemy
    Spell(blood_of_the_enemy)
    #the_unbound_force
    Spell(the_unbound_force)
    #barrage
    Spell(barrage)

    unless { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() or DebuffPresent(memory_of_lucid_dreams) } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot)
    {
     #spitting_cobra
     Spell(spitting_cobra)
    }
   }
  }
 }
}

AddFunction BeastMasteryStShortCdPostConditions
{
 { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } and Spell(barbed_shot) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 } and Spell(barbed_shot) or { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() or DebuffPresent(memory_of_lucid_dreams) } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot) or Charges(barbed_shot count=0) > 1.4 and Spell(barbed_shot)
}

AddFunction BeastMasteryStCdActions
{
 unless { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } and Spell(barbed_shot)
 {
  #aspect_of_the_wild
  Spell(aspect_of_the_wild)

  unless Spell(a_murder_of_crows)
  {
   #stampede,if=buff.aspect_of_the_wild.up&buff.bestial_wrath.up|target.time_to_die<15
   if BuffPresent(aspect_of_the_wild_buff) and BuffPresent(bestial_wrath_buff) or target.TimeToDie() < 15 Spell(stampede)

   unless { SpellCooldown(aspect_of_the_wild) > 20 or target.TimeToDie() < 15 } and Spell(bestial_wrath) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 } and Spell(barbed_shot)
   {
    #focused_azerite_beam
    Spell(focused_azerite_beam)
   }
  }
 }
}

AddFunction BeastMasteryStCdPostConditions
{
 { pet.BuffPresent(pet_frenzy_buff) and pet.BuffRemaining(pet_frenzy_buff) <= GCD() or SpellFullRecharge(barbed_shot) < GCD() and SpellCooldown(bestial_wrath) > 0 or HasAzeriteTrait(primal_instincts_trait) and SpellCooldown(aspect_of_the_wild) < GCD() } and Spell(barbed_shot) or Spell(a_murder_of_crows) or { SpellCooldown(aspect_of_the_wild) > 20 or target.TimeToDie() < 15 } and Spell(bestial_wrath) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command) or Spell(dire_beast) or { pet.BuffExpires(pet_frenzy_buff) and { Charges(barbed_shot count=0) > 1.8 or BuffPresent(bestial_wrath_buff) } or SpellCooldown(aspect_of_the_wild) < BaseDuration(pet_frenzy_buff) - GCD() and HasAzeriteTrait(primal_instincts_trait) or AzeriteTraitRank(dance_of_death_trait) > 1 and BuffExpires(dance_of_death_buff) and SpellCritChance() > 40 or target.TimeToDie() < 9 } and Spell(barbed_shot) or Spell(purifying_blast) or Spell(concentrated_flame) or Spell(blood_of_the_enemy) or Spell(the_unbound_force) or Spell(barrage) or { Focus() - PowerCost(cobra_shot) + FocusRegenRate() * { SpellCooldown(kill_command) - 1 } > PowerCost(kill_command) or SpellCooldown(kill_command) > 1 + GCD() or DebuffPresent(memory_of_lucid_dreams) } and SpellCooldown(kill_command) > 1 and Spell(cobra_shot) or Spell(spitting_cobra) or Charges(barbed_shot count=0) > 1.4 and Spell(barbed_shot)
}
]]

		OvaleScripts:RegisterScript("HUNTER", "beast_mastery", name, desc, code, "script")
	end
end
