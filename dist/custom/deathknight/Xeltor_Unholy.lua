local __exports = LibStub:GetLibrary("ovale/scripts/ovale_deathknight")
if not __exports then return end
__exports.registerDeathKnightUnholyXeltor = function(OvaleScripts)
do
	local name = "xeltor_unholy"
	local desc = "[Xel][8.2] Death Knight: Unholy"
	local code = [[
# Common functions.
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_deathknight_spells)

# Unholy
AddIcon specialization=3 help=main
{
	# Interrupt
	if InCombat() InterruptActions()
	
	if wet() and not BuffPresent(path_of_frost_buff) Spell(path_of_frost)
	
    if { target.InRange(festering_strike) or InCombat() and target.HealthPercent() < 100 and target.InRange(outbreak) } and HasFullControl()
    {
		unless pet.Present() Spell(raise_dead)
		if BuffStacks(dark_succor_buff) and HealthPercent() < 100 Spell(death_strike)
		
		# Cooldown
		if Boss() UnholyDefaultCdActions()

		# Short cooldown
		UnholyDefaultShortCdActions()
		
		# Rotation
		UnholyDefaultMainActions()
	}
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.Distance(less 5) and not target.Classification(worldboss) Spell(war_stomp)
		if target.InRange(asphyxiate) and not target.Classification(worldboss) Spell(asphyxiate)
		if target.InRange(mind_freeze) and target.IsInterruptible() Spell(mind_freeze)
	}
}

AddFunction pooling_for_gargoyle
{
 SpellCooldown(summon_gargoyle) < 5 and Talent(summon_gargoyle_talent)
}

AddFunction UnholyUseItemActions
{
	if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
	if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

### actions.default

AddFunction UnholyDefaultMainActions
{
 #outbreak,target_if=dot.virulent_plague.remains<=gcd
 if target.DebuffRemaining(virulent_plague_debuff) <= GCD() Spell(outbreak)
 #call_action_list,name=essences
 UnholyEssencesMainActions()

 unless UnholyEssencesMainPostConditions()
 {
  #call_action_list,name=cooldowns
  UnholyCooldownsMainActions()

  unless UnholyCooldownsMainPostConditions()
  {
   #run_action_list,name=aoe,if=active_enemies>=2
   if Enemies(tagged=1) >= 2 UnholyAoeMainActions()

   unless Enemies(tagged=1) >= 2 and UnholyAoeMainPostConditions()
   {
    #call_action_list,name=generic
    UnholyGenericMainActions()
   }
  }
 }
}

AddFunction UnholyDefaultMainPostConditions
{
 UnholyEssencesMainPostConditions() or UnholyCooldownsMainPostConditions() or Enemies(tagged=1) >= 2 and UnholyAoeMainPostConditions() or UnholyGenericMainPostConditions()
}

AddFunction UnholyDefaultShortCdActions
{
 #auto_attack
 # UnholyGetInMeleeRange()

 unless target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak)
 {
  #call_action_list,name=essences
  UnholyEssencesShortCdActions()

  unless UnholyEssencesShortCdPostConditions()
  {
   #call_action_list,name=cooldowns
   UnholyCooldownsShortCdActions()

   unless UnholyCooldownsShortCdPostConditions()
   {
    #run_action_list,name=aoe,if=active_enemies>=2
    if Enemies(tagged=1) >= 2 UnholyAoeShortCdActions()

    unless Enemies(tagged=1) >= 2 and UnholyAoeShortCdPostConditions()
    {
     #call_action_list,name=generic
     UnholyGenericShortCdActions()
    }
   }
  }
 }
}

AddFunction UnholyDefaultShortCdPostConditions
{
 target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak) or UnholyEssencesShortCdPostConditions() or UnholyCooldownsShortCdPostConditions() or Enemies(tagged=1) >= 2 and UnholyAoeShortCdPostConditions() or UnholyGenericShortCdPostConditions()
}

AddFunction UnholyDefaultCdActions
{
 # UnholyInterruptActions()
 #variable,name=pooling_for_gargoyle,value=cooldown.summon_gargoyle.remains<5&talent.summon_gargoyle.enabled
 #arcane_torrent,if=runic_power.deficit>65&(pet.gargoyle.active|!talent.summon_gargoyle.enabled)&rune.deficit>=5
 if RunicPowerDeficit() > 65 and { pet.Present() or not Talent(summon_gargoyle_talent) } and RuneDeficit() >= 5 Spell(arcane_torrent_runicpower)
 #blood_fury,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled
 if pet.Present() or not Talent(summon_gargoyle_talent) Spell(blood_fury_ap)
 #berserking,if=buff.unholy_frenzy.up|pet.gargoyle.active|!talent.summon_gargoyle.enabled
 if BuffPresent(unholy_frenzy_buff) or pet.Present() or not Talent(summon_gargoyle_talent) Spell(berserking)
 #use_items,if=time>20|!equipped.ramping_amplitude_gigavolt_engine
 if TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) UnholyUseItemActions()
 #use_item,name=ramping_amplitude_gigavolt_engine,if=cooldown.apocalypse.remains<2|talent.army_of_the_damned.enabled|raid_event.adds.in<5
 if SpellCooldown(apocalypse) < 2 or Talent(army_of_the_damned_talent) or 600 < 5 UnholyUseItemActions()
 #use_item,name=bygone_bee_almanac,if=cooldown.summon_gargoyle.remains>60|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
 if SpellCooldown(summon_gargoyle) > 60 or not Talent(summon_gargoyle_talent) and TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) UnholyUseItemActions()
 #use_item,name=jes_howler,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
 if pet.Present() or not Talent(summon_gargoyle_talent) and TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) UnholyUseItemActions()
 #use_item,name=galecallers_beak,if=pet.gargoyle.active|!talent.summon_gargoyle.enabled&time>20|!equipped.ramping_amplitude_gigavolt_engine
 if pet.Present() or not Talent(summon_gargoyle_talent) and TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) UnholyUseItemActions()
 #use_item,name=grongs_primal_rage,if=rune<=3&(time>20|!equipped.ramping_amplitude_gigavolt_engine)
 if RuneCount() <= 3 and { TimeInCombat() > 20 or not HasEquippedItem(ramping_amplitude_gigavolt_engine_item) } UnholyUseItemActions()
 #potion,if=cooldown.army_of_the_dead.ready|pet.gargoyle.active|buff.unholy_frenzy.up
 # if { SpellCooldown(army_of_the_dead) == 0 or pet.Present() or BuffPresent(unholy_frenzy_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)

 unless target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak)
 {
  #call_action_list,name=essences
  UnholyEssencesCdActions()

  unless UnholyEssencesCdPostConditions()
  {
   #call_action_list,name=cooldowns
   UnholyCooldownsCdActions()

   unless UnholyCooldownsCdPostConditions()
   {
    #run_action_list,name=aoe,if=active_enemies>=2
    if Enemies(tagged=1) >= 2 UnholyAoeCdActions()

    unless Enemies(tagged=1) >= 2 and UnholyAoeCdPostConditions()
    {
     #call_action_list,name=generic
     UnholyGenericCdActions()
    }
   }
  }
 }
}

AddFunction UnholyDefaultCdPostConditions
{
 target.DebuffRemaining(virulent_plague_debuff) <= GCD() and Spell(outbreak) or UnholyEssencesCdPostConditions() or UnholyCooldownsCdPostConditions() or Enemies(tagged=1) >= 2 and UnholyAoeCdPostConditions() or UnholyGenericCdPostConditions()
}

### actions.aoe

AddFunction UnholyAoeMainActions
{
 #death_and_decay,if=cooldown.apocalypse.remains
 if SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) Spell(death_and_decay)
 #defile
 if target.InRange(festering_strike) Spell(defile)
 #epidemic,if=death_and_decay.ticking&rune<2&!variable.pooling_for_gargoyle
 if BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and DebuffCountOnAny(virulent_plague_debuff) >= 1 Spell(epidemic)
 #death_coil,if=death_and_decay.ticking&rune<2&!variable.pooling_for_gargoyle
 if BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() Spell(death_coil)
 #scourge_strike,if=death_and_decay.ticking&cooldown.apocalypse.remains
 if BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and target.InRange(scourge_strike) Spell(scourge_strike)
 #clawing_shadows,if=death_and_decay.ticking&cooldown.apocalypse.remains
 if BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 Spell(clawing_shadows)
 #epidemic,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() and DebuffCountOnAny(virulent_plague_debuff) >= 1 Spell(epidemic)
 #festering_strike,target_if=debuff.festering_wound.stack<=1&cooldown.death_and_decay.remains
 if target.DebuffStacks(festering_wound_debuff) <= 1 and SpellCooldown(death_and_decay) > 0 and target.InRange(festering_strike) Spell(festering_strike)
 #festering_strike,if=talent.bursting_sores.enabled&spell_targets.bursting_sores>=2&debuff.festering_wound.stack<=1
 if Talent(bursting_sores_talent) and Enemies(tagged=1) >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 and target.InRange(festering_strike) Spell(festering_strike)
 #death_coil,if=buff.sudden_doom.react&rune.deficit>=4
 if BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 Spell(death_coil)
 #death_coil,if=buff.sudden_doom.react&!variable.pooling_for_gargoyle|pet.gargoyle.active
 if BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() Spell(death_coil)
 #death_coil,if=runic_power.deficit<14&(cooldown.apocalypse.remains>5|debuff.festering_wound.stack>4)&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() Spell(death_coil)
 #scourge_strike,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and target.InRange(scourge_strike) Spell(scourge_strike)
 #clawing_shadows,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 Spell(clawing_shadows)
 #death_coil,if=runic_power.deficit<20&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 20 and not pooling_for_gargoyle() Spell(death_coil)
 #festering_strike,if=((((debuff.festering_wound.stack<4&!buff.unholy_frenzy.up)|debuff.festering_wound.stack<3)&cooldown.apocalypse.remains<3)|debuff.festering_wound.stack<1)&cooldown.army_of_the_dead.remains>5
 if { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and target.InRange(festering_strike) Spell(festering_strike)
 #death_coil,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() Spell(death_coil)
}

AddFunction UnholyAoeMainPostConditions
{
}

AddFunction UnholyAoeShortCdActions
{
}

AddFunction UnholyAoeShortCdPostConditions
{
 SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) and Spell(death_and_decay) or target.InRange(festering_strike) and Spell(defile) or BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and DebuffCountOnAny(virulent_plague_debuff) >= 1 and Spell(epidemic) or BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and Spell(death_coil) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and target.InRange(scourge_strike) and Spell(scourge_strike) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(clawing_shadows) or not pooling_for_gargoyle() and DebuffCountOnAny(virulent_plague_debuff) >= 1 and Spell(epidemic) or target.DebuffStacks(festering_wound_debuff) <= 1 and SpellCooldown(death_and_decay) > 0 and target.InRange(festering_strike) and Spell(festering_strike) or Talent(bursting_sores_talent) and Enemies(tagged=1) >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 and target.InRange(festering_strike) and Spell(festering_strike) or BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 and Spell(death_coil) or { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and target.InRange(scourge_strike) and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and target.InRange(festering_strike) and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

AddFunction UnholyAoeCdActions
{
}

AddFunction UnholyAoeCdPostConditions
{
 SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) and Spell(death_and_decay) or target.InRange(festering_strike) and Spell(defile) or BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and DebuffCountOnAny(virulent_plague_debuff) >= 1 and Spell(epidemic) or BuffPresent(death_and_decay) and RuneCount() < 2 and not pooling_for_gargoyle() and Spell(death_coil) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and target.InRange(scourge_strike) and Spell(scourge_strike) or BuffPresent(death_and_decay) and SpellCooldown(apocalypse) > 0 and Spell(clawing_shadows) or not pooling_for_gargoyle() and DebuffCountOnAny(virulent_plague_debuff) >= 1 and Spell(epidemic) or target.DebuffStacks(festering_wound_debuff) <= 1 and SpellCooldown(death_and_decay) > 0 and target.InRange(festering_strike) and Spell(festering_strike) or Talent(bursting_sores_talent) and Enemies(tagged=1) >= 2 and target.DebuffStacks(festering_wound_debuff) <= 1 and target.InRange(festering_strike) and Spell(festering_strike) or BuffPresent(sudden_doom_buff) and RuneDeficit() >= 4 and Spell(death_coil) or { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and target.InRange(scourge_strike) and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and target.InRange(festering_strike) and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

### actions.cooldowns

AddFunction UnholyCooldownsMainActions
{
}

AddFunction UnholyCooldownsMainPostConditions
{
}

AddFunction UnholyCooldownsShortCdActions
{
 #apocalypse,if=debuff.festering_wound.stack>=4
 if target.DebuffStacks(festering_wound_debuff) >= 4 and target.InRange(apocalypse) Spell(apocalypse)
 #dark_transformation,if=!raid_event.adds.exists|raid_event.adds.in>15
 if not False(raid_event_adds_exists) or 600 > 15 Spell(dark_transformation)
 #unholy_frenzy,if=debuff.festering_wound.stack<4&!(equipped.ramping_amplitude_gigavolt_engine|azerite.magus_of_the_dead.enabled)
 if target.DebuffStacks(festering_wound_debuff) < 4 and not { HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or HasAzeriteTrait(magus_of_the_dead_trait) } and target.InRange(festering_strike) Spell(unholy_frenzy)
 #unholy_frenzy,if=cooldown.apocalypse.remains<2&(equipped.ramping_amplitude_gigavolt_engine|azerite.magus_of_the_dead.enabled)
 if SpellCooldown(apocalypse) < 2 and { HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or HasAzeriteTrait(magus_of_the_dead_trait) } and target.InRange(festering_strike) Spell(unholy_frenzy)
 #unholy_frenzy,if=active_enemies>=2&((cooldown.death_and_decay.remains<=gcd&!talent.defile.enabled)|(cooldown.defile.remains<=gcd&talent.defile.enabled))
 if Enemies(tagged=1) >= 2 and { SpellCooldown(death_and_decay) <= GCD() and not Talent(defile_talent) or SpellCooldown(defile) <= GCD() and Talent(defile_talent) } and target.InRange(festering_strike) Spell(unholy_frenzy)
 #soul_reaper,target_if=target.time_to_die<8&target.time_to_die>4
 if target.TimeToDie() < 8 and target.TimeToDie() > 4 and target.InRange(soul_reaper) Spell(soul_reaper)
 #soul_reaper,if=(!raid_event.adds.exists|raid_event.adds.in>20)&rune<=(1-buff.unholy_frenzy.up)
 if { not False(raid_event_adds_exists) or 600 > 20 } and RuneCount() <= 1 - BuffPresent(unholy_frenzy_buff) and target.InRange(soul_reaper) Spell(soul_reaper)
 #unholy_blight
 if target.InRange(festering_strike) Spell(unholy_blight)
}

AddFunction UnholyCooldownsShortCdPostConditions
{
}

AddFunction UnholyCooldownsCdActions
{
 #army_of_the_dead
 if target.InRange(festering_strike) Spell(army_of_the_dead)

 unless target.DebuffStacks(festering_wound_debuff) >= 4 and target.InRange(apocalypse) and Spell(apocalypse) or { not False(raid_event_adds_exists) or 600 > 15 } and Spell(dark_transformation)
 {
  #summon_gargoyle,if=runic_power.deficit<14
  if RunicPowerDeficit() < 14 and target.InRange(festering_strike) Spell(summon_gargoyle)
 }
}

AddFunction UnholyCooldownsCdPostConditions
{
 target.DebuffStacks(festering_wound_debuff) >= 4 and target.InRange(apocalypse) and Spell(apocalypse) or { not False(raid_event_adds_exists) or 600 > 15 } and Spell(dark_transformation) or target.DebuffStacks(festering_wound_debuff) < 4 and not { HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or HasAzeriteTrait(magus_of_the_dead_trait) } and target.InRange(festering_strike) and Spell(unholy_frenzy) or SpellCooldown(apocalypse) < 2 and { HasEquippedItem(ramping_amplitude_gigavolt_engine_item) or HasAzeriteTrait(magus_of_the_dead_trait) } and target.InRange(festering_strike) and Spell(unholy_frenzy) or Enemies(tagged=1) >= 2 and { SpellCooldown(death_and_decay) <= GCD() and not Talent(defile_talent) or SpellCooldown(defile) <= GCD() and Talent(defile_talent) } and target.InRange(festering_strike) and Spell(unholy_frenzy) or target.TimeToDie() < 8 and target.TimeToDie() > 4 and target.InRange(soul_reaper) and Spell(soul_reaper) or { not False(raid_event_adds_exists) or 600 > 20 } and RuneCount() <= 1 - BuffPresent(unholy_frenzy_buff) and target.InRange(soul_reaper) and Spell(soul_reaper) or target.InRange(festering_strike) and Spell(unholy_blight)
}

### actions.essences

AddFunction UnholyEssencesMainActions
{
 #concentrated_flame,if=dot.concentrated_flame_burn.remains=0
 if not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 Spell(concentrated_flame_essence)
}

AddFunction UnholyEssencesMainPostConditions
{
}

AddFunction UnholyEssencesShortCdActions
{
 unless not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence)
 {
  #purifying_blast,if=!death_and_decay.ticking
  if not BuffPresent(death_and_decay) Spell(purifying_blast)
  #worldvein_resonance,if=!death_and_decay.ticking
  if not BuffPresent(death_and_decay) Spell(worldvein_resonance_essence)
  #ripple_in_space,if=!death_and_decay.ticking
  if not BuffPresent(death_and_decay) Spell(ripple_in_space_essence)
 }
}

AddFunction UnholyEssencesShortCdPostConditions
{
 not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence)
}

AddFunction UnholyEssencesCdActions
{
 #memory_of_lucid_dreams,if=rune.time_to_1>gcd&runic_power<40
 if TimeToRunes(1) > GCD() and RunicPower() < 40 Spell(memory_of_lucid_dreams_essence)
 #blood_of_the_enemy,if=(cooldown.death_and_decay.remains&spell_targets.death_and_decay>1)|(cooldown.defile.remains&spell_targets.defile>1)|(cooldown.apocalypse.remains&cooldown.death_and_decay.ready)
 if SpellCooldown(death_and_decay) > 0 and Enemies(tagged=1) > 1 or SpellCooldown(defile) > 0 and Enemies(tagged=1) > 1 or SpellCooldown(apocalypse) > 0 and SpellCooldown(death_and_decay) == 0 Spell(blood_of_the_enemy)
 #guardian_of_azeroth,if=cooldown.apocalypse.ready
 if SpellCooldown(apocalypse) == 0 Spell(guardian_of_azeroth)
 #focused_azerite_beam,if=!death_and_decay.ticking
 if not BuffPresent(death_and_decay) Spell(focused_azerite_beam)
}

AddFunction UnholyEssencesCdPostConditions
{
 not target.DebuffRemaining(concentrated_flame_burn_debuff) > 0 and Spell(concentrated_flame_essence) or not BuffPresent(death_and_decay) and Spell(purifying_blast) or not BuffPresent(death_and_decay) and Spell(worldvein_resonance_essence) or not BuffPresent(death_and_decay) and Spell(ripple_in_space_essence)
}

### actions.generic

AddFunction UnholyGenericMainActions
{
 #death_coil,if=buff.sudden_doom.react&!variable.pooling_for_gargoyle|pet.gargoyle.active
 if BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() Spell(death_coil)
 #death_coil,if=runic_power.deficit<14&(cooldown.apocalypse.remains>5|debuff.festering_wound.stack>4)&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() Spell(death_coil)
 #death_and_decay,if=talent.pestilence.enabled&cooldown.apocalypse.remains
 if Talent(pestilence_talent) and SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) Spell(death_and_decay)
 #defile,if=cooldown.apocalypse.remains
 if SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) Spell(defile)
 #scourge_strike,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and target.InRange(scourge_strike) Spell(scourge_strike)
 #clawing_shadows,if=((debuff.festering_wound.up&cooldown.apocalypse.remains>5)|debuff.festering_wound.stack>4)&cooldown.army_of_the_dead.remains>5
 if { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 Spell(clawing_shadows)
 #death_coil,if=runic_power.deficit<20&!variable.pooling_for_gargoyle
 if RunicPowerDeficit() < 20 and not pooling_for_gargoyle() Spell(death_coil)
 #festering_strike,if=((((debuff.festering_wound.stack<4&!buff.unholy_frenzy.up)|debuff.festering_wound.stack<3)&cooldown.apocalypse.remains<3)|debuff.festering_wound.stack<1)&cooldown.army_of_the_dead.remains>5
 if { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and target.InRange(festering_strike) Spell(festering_strike)
 #death_coil,if=!variable.pooling_for_gargoyle
 if not pooling_for_gargoyle() Spell(death_coil)
}

AddFunction UnholyGenericMainPostConditions
{
}

AddFunction UnholyGenericShortCdActions
{
}

AddFunction UnholyGenericShortCdPostConditions
{
 { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or Talent(pestilence_talent) and SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) and Spell(death_and_decay) or SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) and Spell(defile) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and target.InRange(scourge_strike) and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and target.InRange(festering_strike) and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

AddFunction UnholyGenericCdActions
{
}

AddFunction UnholyGenericCdPostConditions
{
 { BuffPresent(sudden_doom_buff) and not pooling_for_gargoyle() or pet.Present() } and Spell(death_coil) or RunicPowerDeficit() < 14 and { SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and not pooling_for_gargoyle() and Spell(death_coil) or Talent(pestilence_talent) and SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) and Spell(death_and_decay) or SpellCooldown(apocalypse) > 0 and target.InRange(festering_strike) and Spell(defile) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and target.InRange(scourge_strike) and Spell(scourge_strike) or { target.DebuffPresent(festering_wound_debuff) and SpellCooldown(apocalypse) > 5 or target.DebuffStacks(festering_wound_debuff) > 4 } and 480 > 5 and Spell(clawing_shadows) or RunicPowerDeficit() < 20 and not pooling_for_gargoyle() and Spell(death_coil) or { { target.DebuffStacks(festering_wound_debuff) < 4 and not BuffPresent(unholy_frenzy_buff) or target.DebuffStacks(festering_wound_debuff) < 3 } and SpellCooldown(apocalypse) < 3 or target.DebuffStacks(festering_wound_debuff) < 1 } and 480 > 5 and target.InRange(festering_strike) and Spell(festering_strike) or not pooling_for_gargoyle() and Spell(death_coil)
}

### actions.precombat

AddFunction UnholyPrecombatMainActions
{
}

AddFunction UnholyPrecombatMainPostConditions
{
}

AddFunction UnholyPrecombatShortCdActions
{
 #raise_dead
 Spell(raise_dead)
}

AddFunction UnholyPrecombatShortCdPostConditions
{
}

AddFunction UnholyPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_battle_potion_of_strength usable=1)

 unless Spell(raise_dead)
 {
  #army_of_the_dead,delay=2
  if target.InRange(festering_strike) Spell(army_of_the_dead)
 }
}

AddFunction UnholyPrecombatCdPostConditions
{
 Spell(raise_dead)
}
]]

	OvaleScripts:RegisterScript("DEATHKNIGHT", "unholy", name, desc, code, "script")
end
end