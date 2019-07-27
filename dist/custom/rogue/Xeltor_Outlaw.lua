local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueOutlawXeltor = function(OvaleScripts)
do
	local name = "xeltor_pokey"
	local desc = "[Xel][8.1.5] Blush: Outlaw edition"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)

# Outlaw
AddIcon specialization=outlaw help=main
{
	# Precombat
	if not mounted() and not Stealthed() and not InCombat() and not Dead() and not PlayerIsResting()
	{
		unless target.Present() and target.Distance(less 5)
		{
			if Speed() > 0 Spell(stealth)
		}
	}
	if not InCombat() and target.Present() and target.Exists() and not target.IsFriend() and not mounted() and not Dead()
	{
		if target.InRange(marked_for_death) and Stealthed() Spell(cold_blood)
		#marked_for_death
		if target.InRange(marked_for_death) and ComboPoints() < 5 Spell(marked_for_death)
	}

	if InCombat() and { not target.IsFriend() or target.IsPvP() } InterruptActions()
	if { HealthPercent() <= 25 or HealthPercent() < 70 and not InCombat() and not mounted() } and not Dead() and Energy() > 30 Spell(crimson_vial)

	if target.InRange(sinister_strike_outlaw) and HasFullControl()
	{
		# Cooldowns
		if Boss() OutlawDefaultCdActions()
		
		# Short Cooldowns
		OutlawDefaultShortCdActions()
		
		# Default Actions
		OutlawDefaultMainActions()
	}

	if InCombat() and not target.IsDead() and not target.IsFriend() and target.Distance(more 5) OutlawGetInMeleeRange()
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(kick) and target.IsInterruptible() Spell(kick)
		if target.InRange(gouge) and not target.Classification(worldboss) and target.istargetingplayer() Spell(gouge)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(between_the_eyes) and not target.Classification(worldboss) and ComboPoints() >= 1 Spell(between_the_eyes)
		if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
	}
}

AddFunction VanishAllowed
{
	{ not target.istargetingplayer() or { unitinparty() and PartyMemberCount() >= 5 } or unitinraid() }
}

AddFunction OutlawGetInMeleeRange
{
	if { not IsBossFight() or Falling() } and { target.Health() < target.MaxHealth() or target.istargetingplayer() } Spell(shadowstep)
	# Texture(misc_arrowlup help=L(not_in_melee_range))
	if target.Health() < target.MaxHealth() or target.istargetingplayer() Spell(pistol_shot)
}

AddFunction OutlawUseItemActions
{
 if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
 if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

AddFunction rtb_reroll
{
 if AzeriteTraitRank(snake_eyes_trait) >= 2 BuffCount(roll_the_bones_buff) < 2
 if HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or BuffRemaining(ruthless_precision_buff) <= SpellCooldown(between_the_eyes) }
 BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or not BuffPresent(grand_melee_buff) and not BuffPresent(ruthless_precision_buff) }
}

AddFunction blade_flurry_sync
{
 Enemies(tagged=1) < 2 and 600 > 20 or BuffPresent(blade_flurry_buff)
}

AddFunction ambush_condition
{
 ComboPointsDeficit() >= 2 + 2 * { Talent(ghostly_strike_talent) and SpellCooldown(ghostly_strike) < 1 } + BuffPresent(broadside_buff) and Energy() > 60 and not BuffPresent(skull_and_crossbones_buff)
}

### actions.default

AddFunction OutlawDefaultMainActions
{
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthMainActions()

 unless Stealthed() and OutlawStealthMainPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsMainActions()

  unless OutlawCdsMainPostConditions()
  {
   #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishMainActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishMainPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildMainActions()
   }
  }
 }
}

AddFunction OutlawDefaultMainPostConditions
{
 Stealthed() and OutlawStealthMainPostConditions() or OutlawCdsMainPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishMainPostConditions() or OutlawBuildMainPostConditions()
}

AddFunction OutlawDefaultShortCdActions
{
 #stealth
 # Spell(stealth)
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthShortCdActions()

 unless Stealthed() and OutlawStealthShortCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsShortCdActions()

  unless OutlawCdsShortCdPostConditions()
  {
   #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishShortCdActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishShortCdPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildShortCdActions()
   }
  }
 }
}

AddFunction OutlawDefaultShortCdPostConditions
{
 Stealthed() and OutlawStealthShortCdPostConditions() or OutlawCdsShortCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishShortCdPostConditions() or OutlawBuildShortCdPostConditions()
}

AddFunction OutlawDefaultCdActions
{
 # OutlawInterruptActions()
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthCdActions()

 unless Stealthed() and OutlawStealthCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsCdActions()

  unless OutlawCdsCdPostConditions()
  {
   #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } OutlawFinishCdActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishCdPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildCdActions()

    unless OutlawBuildCdPostConditions()
    {
     #arcane_torrent,if=energy.deficit>=15+energy.regen
     if EnergyDeficit() >= 15 + EnergyRegenRate() Spell(arcane_torrent_energy)
     #arcane_pulse
     Spell(arcane_pulse)
     #lights_judgment
     Spell(lights_judgment)
    }
   }
  }
 }
}

AddFunction OutlawDefaultCdPostConditions
{
 Stealthed() and OutlawStealthCdPostConditions() or OutlawCdsCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } and OutlawFinishCdPostConditions() or OutlawBuildCdPostConditions()
}

### actions.build

AddFunction OutlawBuildMainActions
{
 #pistol_shot,if=buff.opportunity.up&(buff.keep_your_wits_about_you.stack<25|buff.deadshot.up|energy<45)
 if BuffPresent(opportunity_buff) and { BuffStacks(keep_your_wits_about_you_buff) < 25 or BuffPresent(deadshot_buff) or Energy() < 45 } Spell(pistol_shot)
 #sinister_strike
 Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildMainPostConditions
{
}

AddFunction OutlawBuildShortCdActions
{
}

AddFunction OutlawBuildShortCdPostConditions
{
 BuffPresent(opportunity_buff) and { BuffStacks(keep_your_wits_about_you_buff) < 25 or BuffPresent(deadshot_buff) or Energy() < 45 } and Spell(pistol_shot) or Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildCdActions
{
}

AddFunction OutlawBuildCdPostConditions
{
 BuffPresent(opportunity_buff) and { BuffStacks(keep_your_wits_about_you_buff) < 25 or BuffPresent(deadshot_buff) or Energy() < 45 } and Spell(pistol_shot) or Spell(sinister_strike_outlaw)
}

### actions.cds

AddFunction OutlawCdsMainActions
{
 #blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
 if Enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } Spell(blade_flurry)
 #ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up
 if blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) Spell(ghostly_strike)
}

AddFunction OutlawCdsMainPostConditions
{
}

AddFunction OutlawCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
 if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1
 if 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 Spell(marked_for_death)

 unless Enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
 {
  #blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1
  if blade_flurry_sync() and TimeToMaxEnergy() > 1 Spell(blade_rush)
  #vanish,if=!stealthed.all&variable.ambush_condition
  if not Stealthed() and ambush_condition() and VanishAllowed() Spell(vanish)
 }
}

AddFunction OutlawCdsShortCdPostConditions
{
 Enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
}

AddFunction OutlawCdsCdActions
{
 #potion,if=buff.bloodlust.react|buff.adrenaline_rush.up
 # if { BuffPresent(burst_haste_buff any=1) or BuffPresent(adrenaline_rush_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=variable_intensity_gigavolt_oscillating_reactor,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
 if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 20 or ComboPointsDeficit() <= 2 OutlawUseItemActions()
 #blood_fury
 Spell(blood_fury_ap)
 #berserking
 Spell(berserking)
 #fireblood
 Spell(fireblood)
 #ancestral_call
 Spell(ancestral_call)
 #adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1
 if not BuffPresent(adrenaline_rush_buff) and TimeToMaxEnergy() > 1 and EnergyDeficit() > 1 Spell(adrenaline_rush)

 unless Enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
 {
  #killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
  if blade_flurry_sync() and { TimeToMaxEnergy() > 5 or Energy() < 15 } Spell(killing_spree)

  unless blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush)
  {
   #shadowmeld,if=!stealthed.all&variable.ambush_condition
   if not Stealthed() and ambush_condition() Spell(shadowmeld)
  }
 }
}

AddFunction OutlawCdsCdPostConditions
{
 Enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike) or blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush)
}

### actions.finish

AddFunction OutlawFinishMainActions
{
 #slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
 if BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 Spell(slice_and_dice)
 #roll_the_bones,if=buff.roll_the_bones.remains<=3|variable.rtb_reroll
 if BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() Spell(roll_the_bones)
 #dispatch
 Spell(dispatch)
}

AddFunction OutlawFinishMainPostConditions
{
}

AddFunction OutlawFinishShortCdActions
{
 #between_the_eyes,if=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
 if BuffPresent(ruthless_precision_buff) or { HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) } and DebuffPresent(roll_the_bones) Spell(between_the_eyes)

 unless BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones)
 {
  #between_the_eyes,if=azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
  if HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) Spell(between_the_eyes)
 }
}

AddFunction OutlawFinishShortCdPostConditions
{
 BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or Spell(dispatch)
}

AddFunction OutlawFinishCdActions
{
}

AddFunction OutlawFinishCdPostConditions
{
 { BuffPresent(ruthless_precision_buff) or { HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) } and DebuffPresent(roll_the_bones) } and Spell(between_the_eyes) or BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or { HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) } and Spell(between_the_eyes) or Spell(dispatch)
}

### actions.precombat

AddFunction OutlawPrecombatMainActions
{
 #roll_the_bones,precombat_seconds=2
 Spell(roll_the_bones)
 #slice_and_dice,precombat_seconds=2
 Spell(slice_and_dice)
}

AddFunction OutlawPrecombatMainPostConditions
{
}

AddFunction OutlawPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #stealth
 Spell(stealth)
 #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
 if 600 > 40 Spell(marked_for_death)
}

AddFunction OutlawPrecombatShortCdPostConditions
{
 Spell(roll_the_bones) or Spell(slice_and_dice)
}

AddFunction OutlawPrecombatCdActions
{
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)

 unless Spell(roll_the_bones) or Spell(slice_and_dice)
 {
  #adrenaline_rush,precombat_seconds=1
  if EnergyDeficit() > 1 Spell(adrenaline_rush)
 }
}

AddFunction OutlawPrecombatCdPostConditions
{
 Spell(roll_the_bones) or Spell(slice_and_dice)
}

### actions.stealth

AddFunction OutlawStealthMainActions
{
 #ambush
 Spell(ambush)
}

AddFunction OutlawStealthMainPostConditions
{
}

AddFunction OutlawStealthShortCdActions
{
}

AddFunction OutlawStealthShortCdPostConditions
{
 Spell(ambush)
}

AddFunction OutlawStealthCdActions
{
}

AddFunction OutlawStealthCdPostConditions
{
 Spell(ambush)
}
]]

		OvaleScripts:RegisterScript("ROGUE", "outlaw", name, desc, code, "script")
	end
end
