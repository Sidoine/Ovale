local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueOutlawHooves = function(OvaleScripts)
do
	local name = "hooves_outlaw"
	local desc = "[Hooves][8.2] Rogue: Outlaw"
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
AddFunction bte_condition
{
 BuffPresent(ruthless_precision_buff) or { HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) } and BuffPresent(roll_the_bones_buff)
}

AddFunction blade_flurry_sync
{
 enemies(tagged=1) < 2 and 600 > 20 or BuffPresent(blade_flurry_buff)
}

AddFunction rtb_reroll
{
 if BuffPresent(blade_flurry_buff) BuffCount(roll_the_bones_buff) - BuffPresent(skull_and_crossbones_buff) < 2 and { BuffPresent(loaded_dice_buff) or not BuffPresent(grand_melee_buff) and not BuffPresent(ruthless_precision_buff) and not BuffPresent(broadside_buff) }
 if AzeriteTraitRank(snake_eyes_trait) >= 2 BuffCount(roll_the_bones_buff) < 2
 if HasAzeriteTrait(deadshot_trait) or HasAzeriteTrait(ace_up_your_sleeve_trait) BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or BuffRemaining(ruthless_precision_buff) <= SpellCooldown(between_the_eyes) }
 BuffCount(roll_the_bones_buff) < 2 and { BuffPresent(loaded_dice_buff) or not BuffPresent(grand_melee_buff) and not BuffPresent(ruthless_precision_buff) }
}

AddFunction ambush_condition
{
 ComboPointsDeficit() >= 2 + 2 * { Talent(ghostly_strike_talent) and SpellCooldown(ghostly_strike) < 1 } + BuffPresent(broadside_buff) and Energy() > 60 and not BuffPresent(skull_and_crossbones_buff) and not BuffPresent(keep_your_wits_about_you_buff)
}

AddFunction OutlawInterruptActions
{
 if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
 {
  if target.InRange(gouge) and not target.Classification(worldboss) Spell(gouge)
  if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
  if target.InRange(between_the_eyes) and not target.Classification(worldboss) and ComboPoints() >= 1 Spell(between_the_eyes)
  if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
  if target.InRange(kick) and target.IsInterruptible() Spell(kick)
 }
}

AddFunction OutlawUseItemActions
{
 Item(Trinket0Slot text=13 usable=1)
 Item(Trinket1Slot text=14 usable=1)
}

AddFunction OutlawGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
 {
  Spell(shadowstep)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.default

AddFunction OutlawDefaultMainActions
{
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=rtb_reroll,op=set,if=buff.blade_flurry.up,value=rtb_buffs-buff.skull_and_crossbones.up<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up&!buff.broadside.up)
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up&!buff.keep_your_wits_about_you.up
 #variable,name=bte_condition,value=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthMainActions()

 unless Stealthed() and OutlawStealthMainPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsMainActions()

  unless OutlawCdsMainPostConditions()
  {
   #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))*(azerite.ace_up_your_sleeve.rank<2|!cooldown.between_the_eyes.up|!buff.roll_the_bones.up)
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } OutlawFinishMainActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } and OutlawFinishMainPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildMainActions()
   }
  }
 }
}

AddFunction OutlawDefaultMainPostConditions
{
 Stealthed() and OutlawStealthMainPostConditions() or OutlawCdsMainPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } and OutlawFinishMainPostConditions() or OutlawBuildMainPostConditions()
}

AddFunction OutlawDefaultShortCdActions
{
 #stealth
 Spell(stealth)
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=rtb_reroll,op=set,if=buff.blade_flurry.up,value=rtb_buffs-buff.skull_and_crossbones.up<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up&!buff.broadside.up)
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up&!buff.keep_your_wits_about_you.up
 #variable,name=bte_condition,value=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthShortCdActions()

 unless Stealthed() and OutlawStealthShortCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsShortCdActions()

  unless OutlawCdsShortCdPostConditions()
  {
   #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))*(azerite.ace_up_your_sleeve.rank<2|!cooldown.between_the_eyes.up|!buff.roll_the_bones.up)
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } OutlawFinishShortCdActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } and OutlawFinishShortCdPostConditions()
   {
    #call_action_list,name=build
    OutlawBuildShortCdActions()
   }
  }
 }
}

AddFunction OutlawDefaultShortCdPostConditions
{
 Stealthed() and OutlawStealthShortCdPostConditions() or OutlawCdsShortCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } and OutlawFinishShortCdPostConditions() or OutlawBuildShortCdPostConditions()
}

AddFunction OutlawDefaultCdActions
{
 #OutlawInterruptActions()
 #variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
 #variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
 #variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.rank>=2,value=rtb_buffs<2
 #variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
 #variable,name=rtb_reroll,op=set,if=buff.blade_flurry.up,value=rtb_buffs-buff.skull_and_crossbones.up<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up&!buff.broadside.up)
 #variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up&!buff.keep_your_wits_about_you.up
 #variable,name=bte_condition,value=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
 #variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
 #call_action_list,name=stealth,if=stealthed.all
 if Stealthed() OutlawStealthCdActions()

 unless Stealthed() and OutlawStealthCdPostConditions()
 {
  #call_action_list,name=cds
  OutlawCdsCdActions()

  unless OutlawCdsCdPostConditions()
  {
   #run_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))*(azerite.ace_up_your_sleeve.rank<2|!cooldown.between_the_eyes.up|!buff.roll_the_bones.up)
   if ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } OutlawFinishCdActions()

   unless ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } and OutlawFinishCdPostConditions()
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
 Stealthed() and OutlawStealthCdPostConditions() or OutlawCdsCdPostConditions() or ComboPoints() >= MaxComboPoints() - { BuffPresent(broadside_buff) + BuffPresent(opportunity_buff) } * { Talent(quick_draw_talent) and { not Talent(marked_for_death_talent) or SpellCooldown(marked_for_death) > 1 } } * { AzeriteTraitRank(ace_up_your_sleeve_trait) < 2 or not { not SpellCooldown(between_the_eyes) > 0 } or not BuffPresent(roll_the_bones_buff) } and OutlawFinishCdPostConditions() or OutlawBuildCdPostConditions()
}

### actions.build

AddFunction OutlawBuildMainActions
{
 #pistol_shot,if=buff.opportunity.up&(buff.keep_your_wits_about_you.stack<14|buff.deadshot.up|energy<45)
 if BuffPresent(opportunity_buff) and { BuffStacks(keep_your_wits_about_you_buff) < 14 or BuffPresent(deadshot_buff) or Energy() < 45 } Spell(pistol_shot)
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
 BuffPresent(opportunity_buff) and { BuffStacks(keep_your_wits_about_you_buff) < 14 or BuffPresent(deadshot_buff) or Energy() < 45 } and Spell(pistol_shot) or Spell(sinister_strike_outlaw)
}

AddFunction OutlawBuildCdActions
{
}

AddFunction OutlawBuildCdPostConditions
{
 BuffPresent(opportunity_buff) and { BuffStacks(keep_your_wits_about_you_buff) < 14 or BuffPresent(deadshot_buff) or Energy() < 45 } and Spell(pistol_shot) or Spell(sinister_strike_outlaw)
}

### actions.cds

AddFunction OutlawCdsMainActions
{
 #call_action_list,name=essences,if=!stealthed.all
 if not Stealthed() OutlawEssencesMainActions()

 unless not Stealthed() and OutlawEssencesMainPostConditions()
 {
  #blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
  if enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } Spell(blade_flurry)
  #ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up
  if blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) Spell(ghostly_strike)
 }
}

AddFunction OutlawCdsMainPostConditions
{
 not Stealthed() and OutlawEssencesMainPostConditions()
}

AddFunction OutlawCdsShortCdActions
{
 #call_action_list,name=essences,if=!stealthed.all
 if not Stealthed() OutlawEssencesShortCdActions()

 unless not Stealthed() and OutlawEssencesShortCdPostConditions()
 {
  #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
  if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() or not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 } Spell(marked_for_death)
  #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1
  if 600 > 30 - 10 and not Stealthed() and ComboPointsDeficit() >= MaxComboPoints() - 1 Spell(marked_for_death)

  unless enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
  {
   #blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1
   if blade_flurry_sync() and TimeToMaxEnergy() > 1 Spell(blade_rush)
   #vanish,if=!stealthed.all&variable.ambush_condition
   if not Stealthed() and ambush_condition() Spell(vanish)
  }
 }
}

AddFunction OutlawCdsShortCdPostConditions
{
 not Stealthed() and OutlawEssencesShortCdPostConditions() or enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
}

AddFunction OutlawCdsCdActions
{
 #call_action_list,name=essences,if=!stealthed.all
 if not Stealthed() OutlawEssencesCdActions()

 unless not Stealthed() and OutlawEssencesCdPostConditions()
 {
  #adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1&(!equipped.azsharas_font_of_power|cooldown.latent_arcana.remains>20)
  if not BuffPresent(adrenaline_rush_buff) and TimeToMaxEnergy() > 1 and { not HasEquippedItem(azsharas_font_of_power_item) or SpellCooldown(latent_arcana) > 20 } and EnergyDeficit() > 1 Spell(adrenaline_rush)

  unless enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 } and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike)
  {
   #killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
   if blade_flurry_sync() and { TimeToMaxEnergy() > 5 or Energy() < 15 } Spell(killing_spree)

   unless blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush)
   {
    #shadowmeld,if=!stealthed.all&variable.ambush_condition
    if not Stealthed() and ambush_condition() Spell(shadowmeld)
    #potion,if=buff.bloodlust.react|buff.adrenaline_rush.up
    if { BuffPresent(bloodlust) or BuffPresent(adrenaline_rush_buff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
    #blood_fury
    Spell(blood_fury_ap)
    #berserking
    Spell(berserking)
    #fireblood
    Spell(fireblood)
    #ancestral_call
    Spell(ancestral_call)
    #use_item,effect_name=cyclotronic_blast,if=!stealthed.all&buff.adrenaline_rush.down&buff.memory_of_lucid_dreams.down&energy.time_to_max>4&rtb_buffs<5
    #if not Stealthed() and BuffExpires(adrenaline_rush_buff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and TimeToMaxEnergy() > 4 and BuffCount(roll_the_bones_buff) < 5 OutlawUseItemActions()
    #use_item,name=azsharas_font_of_power,if=!buff.adrenaline_rush.up&!buff.blade_flurry.up&cooldown.adrenaline_rush.remains<15
    #if not BuffPresent(adrenaline_rush_buff) and not BuffPresent(blade_flurry_buff) and SpellCooldown(adrenaline_rush) < 15 OutlawUseItemActions()
    #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.health.pct<32&target.health.pct>=30|!debuff.conductive_ink_debuff.up&(debuff.razor_coral_debuff.stack>=20-10*debuff.blood_of_the_enemy.up|target.time_to_die<60)&buff.adrenaline_rush.remains>18
    #if target.DebuffExpires(razor_coral_debuff) or target.DebuffPresent(conductive_ink_debuff) and target.HealthPercent() < 32 and target.HealthPercent() >= 30 or not target.DebuffPresent(conductive_ink_debuff) and { target.DebuffStacks(razor_coral_debuff) >= 20 - 10 * target.DebuffPresent(blood_of_the_enemy) or target.TimeToDie() < 60 } and BuffRemaining(adrenaline_rush_buff) > 18 OutlawUseItemActions()
    #use_items,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
    #if BuffPresent(bloodlust) or target.TimeToDie() <= 20 or ComboPointsDeficit() <= 2 OutlawUseItemActions()
   }
  }
 }
}

AddFunction OutlawCdsCdPostConditions
{
 not Stealthed() and OutlawEssencesCdPostConditions() or enemies(tagged=1) >= 2 and not BuffPresent(blade_flurry_buff) and { not False(raid_event_adds_exists) or 0 > 8 or 600 > { 2 - SpellCharges(blade_flurry count=0) } * 25 }  and Spell(blade_flurry) or blade_flurry_sync() and ComboPointsDeficit() >= 1 + BuffPresent(broadside_buff) and Spell(ghostly_strike) or blade_flurry_sync() and TimeToMaxEnergy() > 1 and Spell(blade_rush)
}

### actions.essences

AddFunction OutlawEssencesMainActions
{
 #concentrated_flame,if=energy.time_to_max>1&!buff.blade_flurry.up&(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
 if TimeToMaxEnergy() > 1 and not BuffPresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } Spell(concentrated_flame_essence)
}

AddFunction OutlawEssencesMainPostConditions
{
}

AddFunction OutlawEssencesShortCdActions
{
 unless TimeToMaxEnergy() > 1 and not BuffPresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } and Spell(concentrated_flame_essence)
 {
  #blood_of_the_enemy,if=variable.blade_flurry_sync&cooldown.between_the_eyes.up&variable.bte_condition
  if blade_flurry_sync() and not SpellCooldown(between_the_eyes) > 0 and bte_condition() Spell(blood_of_the_enemy)
  #focused_azerite_beam,if=spell_targets.blade_flurry>=2|raid_event.adds.in>60&!buff.adrenaline_rush.up
  if enemies(tagged=1) >= 2 or 600 > 60 and not BuffPresent(adrenaline_rush_buff) Spell(focused_azerite_beam)
  #purifying_blast,if=spell_targets.blade_flurry>=2|raid_event.adds.in>60
  if enemies(tagged=1) >= 2 or 600 > 60 Spell(purifying_blast)
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
  if BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 Spell(the_unbound_force)
  #ripple_in_space
  Spell(ripple_in_space_essence)
  #worldvein_resonance,if=buff.lifeblood.stack<3
  if BuffStacks(lifeblood_buff) < 3 Spell(worldvein_resonance_essence)
 }
}

AddFunction OutlawEssencesShortCdPostConditions
{
 TimeToMaxEnergy() > 1 and not BuffPresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } and Spell(concentrated_flame_essence)
}

AddFunction OutlawEssencesCdActions
{
 unless TimeToMaxEnergy() > 1 and not BuffPresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } and Spell(concentrated_flame_essence)
 {
  #guardian_of_azeroth
  Spell(guardian_of_azeroth)

  unless { enemies(tagged=1) >= 2 or 600 > 60 and not BuffPresent(adrenaline_rush_buff) } and Spell(focused_azerite_beam) or { enemies(tagged=1) >= 2 or 600 > 60 } and Spell(purifying_blast) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or Spell(ripple_in_space_essence) or BuffStacks(lifeblood_buff) < 3 and Spell(worldvein_resonance_essence)
  {
   #memory_of_lucid_dreams,if=energy<45
   if Energy() < 45 Spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction OutlawEssencesCdPostConditions
{
 TimeToMaxEnergy() > 1 and not BuffPresent(blade_flurry_buff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } and Spell(concentrated_flame_essence) or { enemies(tagged=1) >= 2 or 600 > 60 and not BuffPresent(adrenaline_rush_buff) } and Spell(focused_azerite_beam) or { enemies(tagged=1) >= 2 or 600 > 60 } and Spell(purifying_blast) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or Spell(ripple_in_space_essence) or BuffStacks(lifeblood_buff) < 3 and Spell(worldvein_resonance_essence)
}

### actions.finish

AddFunction OutlawFinishMainActions
{
 #between_the_eyes,if=variable.bte_condition
 if bte_condition() Spell(between_the_eyes)
 #slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
 if BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 Spell(slice_and_dice)
 #roll_the_bones,if=buff.roll_the_bones.remains<=3|variable.rtb_reroll
 if BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() Spell(roll_the_bones)
 #between_the_eyes,if=azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
 if HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) Spell(between_the_eyes)
 #dispatch
 Spell(dispatch)
}

AddFunction OutlawFinishMainPostConditions
{
}

AddFunction OutlawFinishShortCdActions
{
}

AddFunction OutlawFinishShortCdPostConditions
{
 bte_condition() and Spell(between_the_eyes) or BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or { HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) } and Spell(between_the_eyes) or Spell(dispatch)
}

AddFunction OutlawFinishCdActions
{
}

AddFunction OutlawFinishCdPostConditions
{
 bte_condition() and Spell(between_the_eyes) or BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and BuffRemaining(slice_and_dice_buff) < { 1 + ComboPoints() } * 1.8 and Spell(slice_and_dice) or { BuffRemaining(roll_the_bones_buff) <= 3 or rtb_reroll() } and Spell(roll_the_bones) or { HasAzeriteTrait(ace_up_your_sleeve_trait) or HasAzeriteTrait(deadshot_trait) } and Spell(between_the_eyes) or Spell(dispatch)
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
 #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
 if 600 > 40 Spell(marked_for_death)
 #stealth,if=(!equipped.pocketsized_computation_device|!cooldown.cyclotronic_blast.duration|raid_event.invulnerable.exists)
 if not HasEquippedItem(pocket_sized_computation_device_item) or not SpellCooldownDuration(cyclotronic_blast) or 0 Spell(stealth)
}

AddFunction OutlawPrecombatShortCdPostConditions
{
 Spell(roll_the_bones) or Spell(slice_and_dice)
}

AddFunction OutlawPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)

 unless Spell(roll_the_bones) or Spell(slice_and_dice)
 {
  #adrenaline_rush,precombat_seconds=1,if=(!equipped.pocketsized_computation_device|!cooldown.cyclotronic_blast.duration|raid_event.invulnerable.exists)
  if { not HasEquippedItem(pocket_sized_computation_device_item) or not SpellCooldownDuration(cyclotronic_blast) or 0 } and EnergyDeficit() > 1 Spell(adrenaline_rush)
  #use_item,name=azsharas_font_of_power
  #OutlawUseItemActions()
  #use_item,effect_name=cyclotronic_blast,if=!raid_event.invulnerable.exists
  #if not 0 OutlawUseItemActions()
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
