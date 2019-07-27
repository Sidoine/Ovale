local __exports = LibStub:GetLibrary("ovale/scripts/ovale_hunter")
if not __exports then return end
__exports.registerHunterMarksmanshipXeltor = function(OvaleScripts)
do
	local name = "xeltor_marksmanship"
	local desc = "[Xel][8.2] Hunter: Marksmanship"
	local code = [[
# Common functions.
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddIcon specialization=2 help=main
{
	if not InCombat() and target.Present() and target.Exists() and not target.IsFriend() and not target.DebuffPresent(hunters_mark_debuff) and target.InRange(hunters_mark) and not Mounted()
	{
		if Boss() Spell(hunters_mark)
	}
	
	if HasFullControl() and InCombat() and target.Present() and target.InRange(arcane_shot)
	{
		InterruptActions()
		if not IsDead() and not Dead() and HealthPercent() < 50  Spell(exhilaration)
		if target.istargetingplayer() and target.Distance(less 8) Spell(bursting_shot)
		SummonPet()
	
		# Cooldowns
		if Boss() MarksmanshipDefaultCdActions()
		
		# Short Cooldowns
		MarksmanshipDefaultShortCdActions()
		
		# Default Actions
		MarksmanshipDefaultMainActions()
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(counter_shot) and target.IsInterruptible() Spell(counter_shot)
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
	}
}

AddFunction MarksmanshipUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

AddFunction CanBurst
{
	{ not target.istargetingplayer() or { unitinparty() and PartyMemberCount() >= 5 } or unitinraid() }
}

AddFunction SummonPet
{
 if pet.HealthPercent() <= 0 and pet.Exists()
 {
  if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
  if Spell(revive_pet) Spell(revive_pet)
 }
 if not pet.HealthPercent() <= 0 and pet.HealthPercent() < 85 and not pet.BuffStacks(mend_pet) and pet.InRange(mend_pet) and pet.Present() and pet.Exists() Spell(mend_pet)
}

### actions.default

AddFunction MarksmanshipDefaultMainActions
{
 #call_action_list,name=cds
 MarksmanshipCdsMainActions()

 unless MarksmanshipCdsMainPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if Enemies(tagged=1) < 3 MarksmanshipStMainActions()

  unless Enemies(tagged=1) < 3 and MarksmanshipStMainPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if Enemies(tagged=1) > 2 MarksmanshipTrickshotsMainActions()
  }
 }
}

AddFunction MarksmanshipDefaultMainPostConditions
{
 MarksmanshipCdsMainPostConditions() or Enemies(tagged=1) < 3 and MarksmanshipStMainPostConditions() or Enemies(tagged=1) > 2 and MarksmanshipTrickshotsMainPostConditions()
}

AddFunction MarksmanshipDefaultShortCdActions
{
 #call_action_list,name=cds
 MarksmanshipCdsShortCdActions()

 unless MarksmanshipCdsShortCdPostConditions()
 {
  #call_action_list,name=st,if=active_enemies<3
  if Enemies(tagged=1) < 3 MarksmanshipStShortCdActions()

  unless Enemies(tagged=1) < 3 and MarksmanshipStShortCdPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if Enemies(tagged=1) > 2 MarksmanshipTrickshotsShortCdActions()
  }
 }
}

AddFunction MarksmanshipDefaultShortCdPostConditions
{
 MarksmanshipCdsShortCdPostConditions() or Enemies(tagged=1) < 3 and MarksmanshipStShortCdPostConditions() or Enemies(tagged=1) > 2 and MarksmanshipTrickshotsShortCdPostConditions()
}

AddFunction MarksmanshipDefaultCdActions
{
 # MarksmanshipInterruptActions()
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
  if Enemies(tagged=1) < 3 MarksmanshipStCdActions()

  unless Enemies(tagged=1) < 3 and MarksmanshipStCdPostConditions()
  {
   #call_action_list,name=trickshots,if=active_enemies>2
   if Enemies(tagged=1) > 2 MarksmanshipTrickshotsCdActions()
  }
 }
}

AddFunction MarksmanshipDefaultCdPostConditions
{
 MarksmanshipCdsCdPostConditions() or Enemies(tagged=1) < 3 and MarksmanshipStCdPostConditions() or Enemies(tagged=1) > 2 and MarksmanshipTrickshotsCdPostConditions()
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
    # if { BuffPresent(trueshot_buff) and BuffPresent(bloodlust) or BuffPresent(trueshot_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } or target.TimeToDie() < 25 } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)
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

### actions.precombat

AddFunction MarksmanshipPrecombatMainActions
{
 #hunters_mark
 Spell(hunters_mark)
 #aimed_shot,if=active_enemies<3
 if Enemies(tagged=1) < 3 and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } Spell(aimed_shot)
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
 Spell(hunters_mark) or Enemies(tagged=1) < 3 and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_unbridled_fury usable=1)

 unless Spell(hunters_mark) or Spell(double_tap) or Spell(worldvein_resonance_essence)
 {
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)
  #memory_of_lucid_dreams
  Spell(memory_of_lucid_dreams_essence)
  #trueshot,precast_time=1.5,if=active_enemies>2
  if Enemies(tagged=1) > 2 Spell(trueshot)
 }
}

AddFunction MarksmanshipPrecombatCdPostConditions
{
 Spell(hunters_mark) or Spell(double_tap) or Spell(worldvein_resonance_essence) or Enemies(tagged=1) < 3 and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot)
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
 if { BuffPresent(trueshot_buff) or { BuffExpires(double_tap_buff) or Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } } and BuffExpires(precise_shots_buff) or SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) and SpellCooldown(trueshot) > 0 } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } Spell(aimed_shot)
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
 if Enemies(tagged=1) > 1 Spell(barrage)
 #a_murder_of_crows
 Spell(a_murder_of_crows)

 unless target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(trueshot_buff) or Focus() < 70 } and Spell(rapid_fire) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or { BuffPresent(trueshot_buff) or { BuffExpires(double_tap_buff) or Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } } and BuffExpires(precise_shots_buff) or SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) and SpellCooldown(trueshot) > 0 } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot)
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

AddFunction MarksmanshipStShortCdPostConditions
{
 target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(trueshot_buff) or Focus() < 70 } and Spell(rapid_fire) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or { BuffPresent(trueshot_buff) or { BuffExpires(double_tap_buff) or Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } } and BuffExpires(precise_shots_buff) or SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) and SpellCooldown(trueshot) > 0 } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or not BuffPresent(trueshot_buff) and Spell(concentrated_flame_essence) or BuffExpires(trueshot_buff) and { BuffPresent(precise_shots_buff) and { Focus() > 41 or BuffPresent(master_marksman_buff) } or { Focus() > 50 and HasAzeriteTrait(focused_fire_trait) or Focus() > 75 } and { SpellCooldown(trueshot) > 5 or Focus() > 80 } or target.TimeToDie() < 5 } and Spell(arcane_shot) or Spell(steady_shot)
}

AddFunction MarksmanshipStCdActions
{
 unless Spell(explosive_shot) or Enemies(tagged=1) > 1 and Spell(barrage) or Spell(a_murder_of_crows) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(trueshot_buff) or Focus() < 70 } and Spell(rapid_fire)
 {
  #blood_of_the_enemy,if=buff.trueshot.up&(buff.unerring_vision.stack>4|!azerite.unerring_vision.enabled)|target.time_to_die<11
  if BuffPresent(trueshot_buff) and { BuffStacks(unerring_vision_buff) > 4 or not HasAzeriteTrait(unerring_vision_trait) } or target.TimeToDie() < 11 Spell(blood_of_the_enemy)
  #focused_azerite_beam,if=!buff.trueshot.up
  if not BuffPresent(trueshot_buff) Spell(focused_azerite_beam)
 }
}

AddFunction MarksmanshipStCdPostConditions
{
 Spell(explosive_shot) or Enemies(tagged=1) > 1 and Spell(barrage) or Spell(a_murder_of_crows) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or { BuffExpires(trueshot_buff) or Focus() < 70 } and Spell(rapid_fire) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and not BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or { BuffPresent(trueshot_buff) or { BuffExpires(double_tap_buff) or Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } } and BuffExpires(precise_shots_buff) or SpellFullRecharge(aimed_shot) < CastTime(aimed_shot) and SpellCooldown(trueshot) > 0 } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trueshot_buff) and BuffPresent(master_marksman_buff) and BuffPresent(memory_of_lucid_dreams_essence_buff) and Spell(arcane_shot) or Spell(piercing_shot) or not BuffPresent(trueshot_buff) and Spell(purifying_blast) or not BuffPresent(trueshot_buff) and Spell(concentrated_flame_essence) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or BuffExpires(trueshot_buff) and { BuffPresent(precise_shots_buff) and { Focus() > 41 or BuffPresent(master_marksman_buff) } or { Focus() > 50 and HasAzeriteTrait(focused_fire_trait) or Focus() > 75 } and { SpellCooldown(trueshot) > 5 or Focus() > 80 } or target.TimeToDie() < 5 } and Spell(arcane_shot) or Spell(steady_shot)
}

### actions.trickshots

AddFunction MarksmanshipTrickshotsMainActions
{
 #aimed_shot,if=buff.trick_shots.up&ca_execute&buff.double_tap.up
 if BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } Spell(aimed_shot)
 #rapid_fire,if=buff.trick_shots.up&(azerite.focused_fire.enabled|azerite.in_the_rhythm.rank>1|azerite.surging_shots.enabled|talent.streamline.enabled)
 if BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } Spell(rapid_fire)
 #aimed_shot,if=buff.trick_shots.up&(buff.precise_shots.down|cooldown.aimed_shot.full_recharge_time<action.aimed_shot.cast_time|buff.trueshot.up)
 if BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } Spell(aimed_shot)
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

 unless BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 } and Spell(multishot_mm)
 {
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
 BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 } and Spell(multishot_mm) or Spell(concentrated_flame_essence) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or Spell(steady_shot)
}

AddFunction MarksmanshipTrickshotsCdActions
{
 unless Spell(barrage) or Spell(explosive_shot) or BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 } and Spell(multishot_mm)
 {
  #focused_azerite_beam
  Spell(focused_azerite_beam)

  unless Spell(purifying_blast) or Spell(concentrated_flame_essence)
  {
   #blood_of_the_enemy
   Spell(blood_of_the_enemy)
  }
 }
}

AddFunction MarksmanshipTrickshotsCdPostConditions
{
 Spell(barrage) or Spell(explosive_shot) or BuffPresent(trick_shots_buff) and Talent(careful_aim_talent) and { target.HealthPercent() > 80 or target.HealthPercent() < 20 } and BuffPresent(double_tap_buff) and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and { HasAzeriteTrait(focused_fire_trait) or AzeriteTraitRank(in_the_rhythm_trait) > 1 or HasAzeriteTrait(surging_shots_trait) or Talent(streamline_talent) } and Spell(rapid_fire) or BuffPresent(trick_shots_buff) and { BuffExpires(precise_shots_buff) or SpellCooldown(aimed_shot) < CastTime(aimed_shot) or BuffPresent(trueshot_buff) } and { Speed() == 0 or CastTime(aimed_shot) <= CastTime(arcane_shot) } and Spell(aimed_shot) or BuffPresent(trick_shots_buff) and Spell(rapid_fire) or { BuffExpires(trick_shots_buff) or BuffPresent(precise_shots_buff) and not BuffPresent(trueshot_buff) or Focus() > 70 } and Spell(multishot_mm) or Spell(purifying_blast) or Spell(concentrated_flame_essence) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or Spell(piercing_shot) or Spell(a_murder_of_crows) or target.Refreshable(serpent_sting_mm_debuff) and not InFlightToTarget(serpent_sting_mm) and Spell(serpent_sting_mm) or Spell(steady_shot)
}
]]

		OvaleScripts:RegisterScript("HUNTER", "marksmanship", name, desc, code, "script")
	end
end
