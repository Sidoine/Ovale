local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueAssassinationXeltor = function(OvaleScripts)
do
	local name = "xeltor_stabby"
	local desc = "[Xel][8.0] Blush: Stabby"
	local code = [[

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)

# Assassination (Stabby)
AddIcon specialization=1 help=main
{
	# Stealth
	if not mounted() and not Stealthed() and not InCombat() and not Dead() and not PlayerIsResting()
	{
		unless target.Present() and target.Distance(less 5)
		{
			if Speed() > 0 Spell(stealth)
		}
	}
	
	if not InCombat() and target.Present() and target.Exists() and not target.IsFriend() and not mounted()
	{
		#marked_for_death
		if target.InRange(marked_for_death) Spell(marked_for_death)
		#slice_and_dice,if=talent.marked_for_death.enabled
		# if ComboPoints() >0 and not BuffPresent(slice_and_dice_buff) Spell(slice_and_dice)
	}
	
	if HealthPercent() < 50 and HealthPercent() > 0 Spell(crimson_vial)
	if InCombat() InterruptActions()
	
	if { Spell(mutilate) and target.InRange(mutilate) and HasFullControl() } or { Spell(sinister_strike) and target.InRange(sinister_strike) and HasFullControl() }
	{
		# Cooldowns
		if Boss() AssassinationDefaultCdActions()
		
		# Short Cooldowns
		AssassinationDefaultShortCdActions()
		
		# Default Actions
		AssassinationDefaultMainActions()
	}
	
	if InCombat() and target.Present() and not target.IsFriend() and { TimeInCombat() < 6 or Falling() } AssassinationGetInMeleeRange()
	if InCombat() and target.Present() and not target.IsFriend() and not target.InRange(kick) and not target.DebuffPresent(deadly_poison_debuff) Spell(poisoned_knife)
}

AddFunction VanishAllowed
{
	{ not target.istargetingplayer() or unitinparty() or unitinraid() }
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(kick) and target.IsInterruptible() Spell(kick)
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(kidney_shot) and not target.Classification(worldboss) and ComboPoints() >= 1 Spell(kidney_shot)
		if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
	}
}

AddFunction AssassinationUseItemActions
{
 # if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
 # if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

AddFunction AssassinationGetInMeleeRange
{
	if not target.InRange(kick)
	{
		Spell(shadowstep)
		# Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * 7 / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } }
}

AddFunction use_filler
{
 ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target()
}

AddFunction single_target
{
 Enemies(tagged=1) < 2
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #variable,name=single_target,value=spell_targets.fan_of_knives<2
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedMainActions()

 unless Stealthed() and AssassinationStealthedMainPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsMainActions()

  unless AssassinationCdsMainPostConditions()
  {
   #call_action_list,name=dot
   AssassinationDotMainActions()

   unless AssassinationDotMainPostConditions()
   {
    #call_action_list,name=direct
    AssassinationDirectMainActions()
   }
  }
 }
}

AddFunction AssassinationDefaultMainPostConditions
{
 Stealthed() and AssassinationStealthedMainPostConditions() or AssassinationCdsMainPostConditions() or AssassinationDotMainPostConditions() or AssassinationDirectMainPostConditions()
}

AddFunction AssassinationDefaultShortCdActions
{
 #stealth
 Spell(stealth)
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #variable,name=single_target,value=spell_targets.fan_of_knives<2
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedShortCdActions()

 unless Stealthed() and AssassinationStealthedShortCdPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsShortCdActions()

  unless AssassinationCdsShortCdPostConditions()
  {
   #call_action_list,name=dot
   AssassinationDotShortCdActions()

   unless AssassinationDotShortCdPostConditions()
   {
    #call_action_list,name=direct
    AssassinationDirectShortCdActions()
   }
  }
 }
}

AddFunction AssassinationDefaultShortCdPostConditions
{
 Stealthed() and AssassinationStealthedShortCdPostConditions() or AssassinationCdsShortCdPostConditions() or AssassinationDotShortCdPostConditions() or AssassinationDirectShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 # AssassinationInterruptActions()
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #variable,name=single_target,value=spell_targets.fan_of_knives<2
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedCdActions()

 unless Stealthed() and AssassinationStealthedCdPostConditions()
 {
  #call_action_list,name=cds
  AssassinationCdsCdActions()

  unless AssassinationCdsCdPostConditions()
  {
   #call_action_list,name=dot
   AssassinationDotCdActions()

   unless AssassinationDotCdPostConditions()
   {
    #call_action_list,name=direct
    AssassinationDirectCdActions()

    unless AssassinationDirectCdPostConditions()
    {
     #arcane_torrent,if=energy.deficit>=15+variable.energy_regen_combined
     if EnergyDeficit() >= 15 + energy_regen_combined() Spell(arcane_torrent_energy)
     #arcane_pulse
     Spell(arcane_pulse)
     #lights_judgment
     Spell(lights_judgment)
    }
   }
  }
 }
}

AddFunction AssassinationDefaultCdPostConditions
{
 Stealthed() and AssassinationStealthedCdPostConditions() or AssassinationCdsCdPostConditions() or AssassinationDotCdPostConditions() or AssassinationDirectCdPostConditions()
}

### actions.cds

AddFunction AssassinationCdsMainActions
{
 #exsanguinate,if=dot.rupture.remains>4+4*cp_max_spend&!dot.garrote.refreshable
 if target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) Spell(exsanguinate)
 #toxic_blade,if=dot.rupture.ticking
 if target.DebuffPresent(rupture_debuff) Spell(toxic_blade)
}

AddFunction AssassinationCdsMainPostConditions
{
}

AddFunction AssassinationCdsShortCdActions
{
 #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend)
 if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() * 1.5 or ComboPointsDeficit() >= MaxComboPoints() } Spell(marked_for_death)
 #marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&combo_points.deficit>=cp_max_spend
 if 600 > 30 - 10 and ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
 #vanish,if=talent.subterfuge.enabled&!dot.garrote.ticking&variable.single_target
 if Talent(subterfuge_talent) and not target.DebuffPresent(garrote_debuff) and single_target() and VanishAllowed() Spell(vanish)
 #vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&variable.single_target)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier<=1)
 if Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and single_target() } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and VanishAllowed() Spell(vanish)
 #vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up
 if Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and VanishAllowed() Spell(vanish)
 #vanish,if=talent.subterfuge.enabled&(!talent.exsanguinate.enabled|!variable.single_target)&!stealthed.rogue&cooldown.garrote.up&dot.garrote.refreshable&(spell_targets.fan_of_knives<=3&combo_points.deficit>=1+spell_targets.fan_of_knives|spell_targets.fan_of_knives>=4&combo_points.deficit>=4)
 if Talent(subterfuge_talent) and { not Talent(exsanguinate_talent) or not single_target() } and not Stealthed() and not SpellCooldown(garrote) > 0 and target.DebuffRefreshable(garrote_debuff) and { Enemies(tagged=1) <= 3 and ComboPointsDeficit() >= 1 + Enemies(tagged=1) or Enemies(tagged=1) >= 4 and ComboPointsDeficit() >= 4 } and VanishAllowed() Spell(vanish)
 #vanish,if=talent.master_assassin.enabled&!stealthed.all&master_assassin_remains<=0&!dot.rupture.refreshable
 if Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and VanishAllowed() Spell(vanish)
}

AddFunction AssassinationCdsShortCdPostConditions
{
 target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

AddFunction AssassinationCdsCdActions
{
 #potion,if=buff.bloodlust.react|debuff.vendetta.up
 # if { BuffPresent(burst_haste_buff any=1) or target.DebuffPresent(vendetta_debuff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
 #use_item,name=galecallers_boon,if=cooldown.vendetta.remains<=1&(!talent.subterfuge.enabled|dot.garrote.pmultiplier>1)|cooldown.vendetta.remains>45
 if SpellCooldown(vendetta) <= 1 and { not Talent(subterfuge_talent) or target.DebuffPersistentMultiplier(garrote_debuff) > 1 } or SpellCooldown(vendetta) > 45 AssassinationUseItemActions()
 #blood_fury,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(blood_fury_ap)
 #berserking,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(berserking)
 #fireblood,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(fireblood)
 #ancestral_call,if=debuff.vendetta.up
 if target.DebuffPresent(vendetta_debuff) Spell(ancestral_call)
 #vendetta,if=!stealthed.rogue&dot.rupture.ticking&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1)
 if not Stealthed() and target.DebuffPresent(rupture_debuff) and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) > 1 } Spell(vendetta)
}

AddFunction AssassinationCdsCdPostConditions
{
 target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
}

### actions.direct

AddFunction AssassinationDirectMainActions
{
 #envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
 if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } Spell(envenom)
 if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and not Spell(envenom) Texture(ability_rogue_disembowel)
 #variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target
 #poisoned_knife,if=variable.use_filler&buff.sharpened_blades.stack>=29
 if use_filler() and BuffStacks(sharpened_blades_buff) >= 29 Spell(poisoned_knife)
 #fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue)
 if use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies(tagged=1) >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } Spell(fan_of_knives)
 #fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3
 if use_filler() and Enemies(tagged=1) >= 3 and not target.DebuffPresent(deadly_poison_debuff) Spell(fan_of_knives)
 #blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled)
 if use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } Spell(blindside)
 #mutilate,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives=2
 if use_filler() and Enemies(tagged=1) == 2 and not target.DebuffPresent(deadly_poison_debuff) Spell(mutilate)
 if use_filler() and Enemies(tagged=1) == 2 and not target.DebuffPresent(deadly_poison_debuff) Spell(sinister_strike)
 #mutilate,if=variable.use_filler
 if use_filler() Spell(mutilate)
 if use_filler() Spell(sinister_strike)
}

AddFunction AssassinationDirectMainPostConditions
{
}

AddFunction AssassinationDirectShortCdActions
{
}

AddFunction AssassinationDirectShortCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and BuffStacks(sharpened_blades_buff) >= 29 and Spell(poisoned_knife) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies(tagged=1) >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } and Spell(fan_of_knives) or use_filler() and Enemies(tagged=1) >= 3 and not target.DebuffPresent(deadly_poison_debuff) and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } and Spell(blindside) or use_filler() and Enemies(tagged=1) == 2 and not target.DebuffPresent(deadly_poison_debuff) and Spell(mutilate) or use_filler() and Spell(mutilate)
}

AddFunction AssassinationDirectCdActions
{
}

AddFunction AssassinationDirectCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and BuffStacks(sharpened_blades_buff) >= 29 and Spell(poisoned_knife) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or Enemies(tagged=1) >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } and Spell(fan_of_knives) or use_filler() and Enemies(tagged=1) >= 3 and not target.DebuffPresent(deadly_poison_debuff) and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) } and Spell(blindside) or use_filler() and Enemies(tagged=1) == 2 and not target.DebuffPresent(deadly_poison_debuff) and Spell(mutilate) or use_filler() and Spell(mutilate)
}

### actions.dot

AddFunction AssassinationDotMainActions
{
 #rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2)))
 if Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } Spell(rupture)
 #pool_resource,for_next=1
 #garrote,cycle_targets=1,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(target.time_to_die-remains>4&spell_targets.fan_of_knives<=1|target.time_to_die-remains>12)
 if { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies(tagged=1) <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) Texture(ability_skeer_bloodletting)
 unless { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies(tagged=1) <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
 {
  #crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4
  if Enemies(tagged=1) >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies(tagged=1) >= 5 } and ComboPoints() >= 4 Spell(crimson_tempest)
  #rupture,cycle_targets=1,if=combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
  if ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 Spell(rupture)
 }
}

AddFunction AssassinationDotMainPostConditions
{
}

AddFunction AssassinationDotShortCdActions
{
}

AddFunction AssassinationDotShortCdPostConditions
{
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies(tagged=1) <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies(tagged=1) <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies(tagged=1) >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies(tagged=1) >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

AddFunction AssassinationDotCdActions
{
}

AddFunction AssassinationDotCdPostConditions
{
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies(tagged=1) <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and Enemies(tagged=1) <= 1 or target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies(tagged=1) >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies(tagged=1) >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) }
}

### actions.precombat

AddFunction AssassinationPrecombatMainActions
{
}

AddFunction AssassinationPrecombatMainPostConditions
{
}

AddFunction AssassinationPrecombatShortCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #apply_poison
 #stealth
 Spell(stealth)
 #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
 if 600 > 40 Spell(marked_for_death)
}

AddFunction AssassinationPrecombatShortCdPostConditions
{
}

AddFunction AssassinationPrecombatCdActions
{
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(battle_potion_of_agility usable=1)
}

AddFunction AssassinationPrecombatCdPostConditions
{
}

### actions.stealthed

AddFunction AssassinationStealthedMainActions
{
 #rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&(talent.exsanguinate.enabled&cooldown.exsanguinate.remains<=2|!ticking)&variable.single_target)&target.time_to_die-remains>6
 if ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 Spell(rupture)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&refreshable&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and SpellUsable(garrote) Texture(ability_skeer_bloodletting)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&remains<=10&pmultiplier<=1&target.time_to_die-remains>2
 if Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and SpellUsable(garrote) Texture(ability_skeer_bloodletting)
 #rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking
 if Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) Spell(rupture)
 #garrote,cycle_targets=1,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&target.time_to_die>remains&combo_points.deficit>1
 if Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 and SpellUsable(garrote) Texture(ability_skeer_bloodletting)
 #pool_resource,for_next=1
 #garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&prev_gcd.1.rupture&dot.rupture.remains>5+4*cp_max_spend
 if Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and SpellUsable(garrote) Texture(ability_skeer_bloodletting)
}

AddFunction AssassinationStealthedMainPostConditions
{
}

AddFunction AssassinationStealthedShortCdActions
{
}

AddFunction AssassinationStealthedShortCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and Spell(rupture) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
}

AddFunction AssassinationStealthedCdActions
{
}

AddFunction AssassinationStealthedCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or Talent(subterfuge_talent) and target.Refreshable(garrote_debuff) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and target.DebuffRemaining(garrote_debuff) <= 10 and PersistentMultiplier(garrote_debuff) <= 1 and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and Spell(rupture) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and ComboPointsDeficit() > 1 and Spell(garrote) or Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote)
}
]]

		OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
	end
end
