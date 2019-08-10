local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueAssassinationXeltor = function(OvaleScripts)
do
	local name = "xeltor_stabby"
	local desc = "[Xel][8.2] Blush: Stabby"
	local code = [[

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)

# Assassination (Stabby)
AddIcon specialization=1 help=main
{
	if not mounted() and not Stealthed() and not InCombat() and not Dead() and not PlayerIsResting()
	{
		unless target.Present() and target.Distance(less 5)
		{
			if Speed() > 0 Spell(stealth)
		}
	}
	if not InCombat() and not mounted() and not Dead()
	{
		# Poisons!
		if BuffRemaining(lethal_poison_buff) < 600 and Speed() == 0 and SpellUsable(deadly_poison) Texture(spell_nature_corrosivebreath)
		if BuffRemaining(crippling_poison_buff) < 600 and Speed() == 0 Spell(crippling_poison)
		# if target.InRange(marked_for_death) and Stealthed() and not BuffPresent(cold_blood) Spell(cold_blood)
		#marked_for_death
		if target.InRange(marked_for_death) and ComboPoints() < 5 and target.Present() and target.Exists() and not target.IsFriend() Spell(marked_for_death)
	}
	
	if InCombat() InterruptActions()
	if HealthPercent() < 50 and not Dead() and Energy() > 24 Spell(crimson_vial)
	
	if target.InRange(mutilate) and HasFullControl()
	{
		# Cooldowns
		AssassinationDefaultCdActions()
		
		# Short Cooldowns
		AssassinationDefaultShortCdActions()
		
		# Default Actions
		AssassinationDefaultMainActions()
	}
	
	if InCombat() and target.Present() and not target.IsDead() and not target.IsFriend() and Falling() and { target.HealthPercent() < 100 or target.istargetingplayer() } AssassinationGetInMeleeRange()
	if InCombat() and target.Present() and not target.IsFriend() and not target.InRange(kick) and not target.DebuffPresent(deadly_poison_debuff) and target.InRange(poisoned_knife) Spell(poisoned_knife)
}

AddFunction VanishAllowed
{
	{ not target.istargetingplayer() or { unitinparty() and PartyMemberCount() >= 5 } or unitinraid() }
}

AddFunction InterruptActions
{
	if { target.HasManagedInterrupts() and target.MustBeInterrupted() } or { not target.HasManagedInterrupts() and target.IsInterruptible() }
	{
		if target.InRange(quaking_palm) and not target.Classification(worldboss) Spell(quaking_palm)
		if target.InRange(kidney_shot) and not target.Classification(worldboss) and ComboPoints() >= 1 Spell(kidney_shot)
		if target.InRange(cheap_shot) and not target.Classification(worldboss) Spell(cheap_shot)
		if target.InRange(kick) and target.IsInterruptible() Spell(kick)
	}
}

AddFunction AssassinationUseItemActions
{
 if Item(Trinket0Slot usable=1) Texture(inv_jewelry_talisman_12)
 if Item(Trinket1Slot usable=1) Texture(inv_jewelry_talisman_12)
}

AddFunction AssassinationGetInMeleeRange
{
	if not target.InRange(kick)
	{
		if target.InRange(shadowstep) Spell(shadowstep)
		# Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction skip_rupture
{
 target.DebuffPresent(vendetta_debuff) and { target.DebuffPresent(toxic_blade_debuff) or BuffRemaining(master_assassin_buff) > 0 } and target.DebuffRemaining(rupture_debuff) > 2
}

AddFunction use_filler
{
 ComboPointsDeficit() > 1 or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target()
}

AddFunction ss_vanish_condition
{
 HasAzeriteTrait(shrouded_suffocation_trait) and { Enemies(tagged=1) - DebuffCountOnAny(garrote_debuff) >= 1 or Enemies(tagged=1) == 3 } and { 0 == 0 or Enemies(tagged=1) >= 6 }
}

AddFunction energy_regen_combined
{
 EnergyRegenRate() + { DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) } * 7 / { 2 * { 100 / { 100 + SpellCastSpeedPercent() } } }
}

AddFunction skip_cycle_rupture
{
 Enemies(tagged=1) > 3 and { target.DebuffPresent(toxic_blade_debuff) or DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) > 5 and not HasAzeriteTrait(scent_of_blood_trait) }
}

AddFunction skip_cycle_garrote
{
 Enemies(tagged=1) > 3 and { target.DebuffRemaining(garrote_debuff) < SpellCooldownDuration(garrote) or DebuffCountOnAny(rupture_debuff) + DebuffCountOnAny(garrote_debuff) + Talent(internal_bleeding_talent) * DebuffCountOnAny(internal_bleeding_debuff) > 5 }
}

AddFunction single_target
{
 Enemies(tagged=1) < 2
}

### actions.default

AddFunction AssassinationDefaultMainActions
{
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedMainActions()

 unless Stealthed() and AssassinationStealthedMainPostConditions()
 {
  #call_action_list,name=cds,if=(!talent.master_assassin.enabled|dot.garrote.ticking)&(!equipped.azsharas_font_of_power|!cooldown.latent_arcana.up)
  if { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } AssassinationCdsMainActions()

  unless { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } and AssassinationCdsMainPostConditions()
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
 Stealthed() and AssassinationStealthedMainPostConditions() or { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } and AssassinationCdsMainPostConditions() or AssassinationDotMainPostConditions() or AssassinationDirectMainPostConditions()
}

AddFunction AssassinationDefaultShortCdActions
{
 #stealth
 # Spell(stealth)
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedShortCdActions()

 unless Stealthed() and AssassinationStealthedShortCdPostConditions()
 {
  #call_action_list,name=cds,if=(!talent.master_assassin.enabled|dot.garrote.ticking)&(!equipped.azsharas_font_of_power|!cooldown.latent_arcana.up)
  if { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } AssassinationCdsShortCdActions()

  unless { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } and AssassinationCdsShortCdPostConditions()
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
 Stealthed() and AssassinationStealthedShortCdPostConditions() or { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } and AssassinationCdsShortCdPostConditions() or AssassinationDotShortCdPostConditions() or AssassinationDirectShortCdPostConditions()
}

AddFunction AssassinationDefaultCdActions
{
 # AssassinationInterruptActions()
 #variable,name=energy_regen_combined,value=energy.regen+poisoned_bleeds*7%(2*spell_haste)
 #variable,name=single_target,value=spell_targets.fan_of_knives<2
 #use_item,name=azsharas_font_of_power,if=!stealthed.all&buff.master_assassin.remains<=0&cooldown.vendetta.remains<10+10*equipped.ashvanes_razor_coral&!debuff.vendetta.up&!debuff.toxic_blade.up
 if not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and SpellCooldown(vendetta) < 10 + 10 * HasEquippedItem(ashvanes_razor_coral_item) and not target.DebuffPresent(vendetta_debuff) and not target.DebuffPresent(toxic_blade_debuff) AssassinationUseItemActions()
 #call_action_list,name=stealthed,if=stealthed.rogue
 if Stealthed() AssassinationStealthedCdActions()

 unless Stealthed() and AssassinationStealthedCdPostConditions()
 {
  #call_action_list,name=cds,if=(!talent.master_assassin.enabled|dot.garrote.ticking)&(!equipped.azsharas_font_of_power|!cooldown.latent_arcana.up)
  if { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } AssassinationCdsCdActions()

  unless { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } and AssassinationCdsCdPostConditions()
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
 Stealthed() and AssassinationStealthedCdPostConditions() or { not Talent(master_assassin_talent) or target.DebuffPresent(garrote_debuff) } and { not HasEquippedItem(azsharas_font_of_power_item) or not { not SpellCooldown(latent_arcana) > 0 } } and AssassinationCdsCdPostConditions() or AssassinationDotCdPostConditions() or AssassinationDirectCdPostConditions()
}

### actions.cds

AddFunction AssassinationCdsMainActions
{
 #call_action_list,name=essences,if=!stealthed.all&dot.rupture.ticking&buff.master_assassin.remains<=0
 if not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 AssassinationEssencesMainActions()

 unless not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 and AssassinationEssencesMainPostConditions()
 {
  #variable,name=ss_vanish_condition,value=azerite.shrouded_suffocation.enabled&(non_ss_buffed_targets>=1|spell_targets.fan_of_knives=3)&(ss_buffed_targets_above_pandemic=0|spell_targets.fan_of_knives>=6)
  #pool_resource,for_next=1,extra_amount=45
  #vanish,if=talent.subterfuge.enabled&!stealthed.rogue&cooldown.garrote.up&(variable.ss_vanish_condition|!azerite.shrouded_suffocation.enabled&dot.garrote.refreshable)&combo_points.deficit>=((1+2*azerite.shrouded_suffocation.enabled)*spell_targets.fan_of_knives)>?4&raid_event.adds.in>12
  unless Talent(subterfuge_talent) and not Stealthed() and not SpellCooldown(garrote) > 0 and { ss_vanish_condition() or not HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and ComboPointsDeficit() >= { 1 + 2 * HasAzeriteTrait(shrouded_suffocation_trait) } * Enemies(tagged=1) >? 4 and 600 > 12 and VanishAllowed() and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(45)
  {
   #exsanguinate,if=dot.rupture.remains>4+4*cp_max_spend&!dot.garrote.refreshable
   if target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) Spell(exsanguinate)
   #toxic_blade,if=dot.rupture.ticking
   if target.DebuffPresent(rupture_debuff) Spell(toxic_blade)
  }
 }
}

AddFunction AssassinationCdsMainPostConditions
{
 not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 and AssassinationEssencesMainPostConditions()
}

AddFunction AssassinationCdsShortCdActions
{
 #call_action_list,name=essences,if=!stealthed.all&dot.rupture.ticking&buff.master_assassin.remains<=0
 if not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 AssassinationEssencesShortCdActions()

 unless not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 and AssassinationEssencesShortCdPostConditions()
 {
  #marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit*1.5|combo_points.deficit>=cp_max_spend)
  if False(raid_event_adds_exists) and { target.TimeToDie() < ComboPointsDeficit() * 1.5 or ComboPointsDeficit() >= MaxComboPoints() } Spell(marked_for_death)
  #marked_for_death,if=combo_points.deficit>=cp_max_spend
  if ComboPointsDeficit() >= MaxComboPoints() Spell(marked_for_death)
  #vanish,if=talent.exsanguinate.enabled&(talent.nightstalker.enabled|talent.subterfuge.enabled&variable.single_target)&combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier<=1)
  if Talent(exsanguinate_talent) and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and single_target() } and ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) <= 1 } and VanishAllowed() Spell(vanish)
  #vanish,if=talent.nightstalker.enabled&!talent.exsanguinate.enabled&combo_points>=cp_max_spend&debuff.vendetta.up
  if Talent(nightstalker_talent) and not Talent(exsanguinate_talent) and ComboPoints() >= MaxComboPoints() and target.DebuffPresent(vendetta_debuff) and VanishAllowed() Spell(vanish)
  #variable,name=ss_vanish_condition,value=azerite.shrouded_suffocation.enabled&(non_ss_buffed_targets>=1|spell_targets.fan_of_knives=3)&(ss_buffed_targets_above_pandemic=0|spell_targets.fan_of_knives>=6)
  #pool_resource,for_next=1,extra_amount=45
  #vanish,if=talent.subterfuge.enabled&!stealthed.rogue&cooldown.garrote.up&(variable.ss_vanish_condition|!azerite.shrouded_suffocation.enabled&dot.garrote.refreshable)&combo_points.deficit>=((1+2*azerite.shrouded_suffocation.enabled)*spell_targets.fan_of_knives)>?4&raid_event.adds.in>12
  if Talent(subterfuge_talent) and not Stealthed() and not SpellCooldown(garrote) > 0 and { ss_vanish_condition() or not HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and ComboPointsDeficit() >= { 1 + 2 * HasAzeriteTrait(shrouded_suffocation_trait) } * Enemies(tagged=1) >? 4 and 600 > 12 and VanishAllowed() Spell(vanish)
  unless Talent(subterfuge_talent) and not Stealthed() and not SpellCooldown(garrote) > 0 and { ss_vanish_condition() or not HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and ComboPointsDeficit() >= { 1 + 2 * HasAzeriteTrait(shrouded_suffocation_trait) } * Enemies(tagged=1) >? 4 and 600 > 12 and VanishAllowed() and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(45)
  {
   #vanish,if=talent.master_assassin.enabled&!stealthed.all&buff.master_assassin.remains<=0&!dot.rupture.refreshable&dot.garrote.remains>3&debuff.vendetta.up&(!talent.toxic_blade.enabled|debuff.toxic_blade.up)&(!essence.blood_of_the_enemy.major|debuff.blood_of_the_enemy.up)
   if Talent(master_assassin_talent) and not Stealthed() and BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffRefreshable(rupture_debuff) and target.DebuffRemaining(garrote_debuff) > 3 and target.DebuffPresent(vendetta_debuff) and { not Talent(toxic_blade_talent) or target.DebuffPresent(toxic_blade_debuff) } and { not AzeriteEssenceIsMajor(blood_of_the_enemy_essence_id) or target.DebuffPresent(blood_of_the_enemy) } and VanishAllowed() Spell(vanish)
  }
 }
}

AddFunction AssassinationCdsShortCdPostConditions
{
 not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 and AssassinationEssencesShortCdPostConditions() or not { Talent(subterfuge_talent) and not Stealthed() and not SpellCooldown(garrote) > 0 and { ss_vanish_condition() or not HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and ComboPointsDeficit() >= { 1 + 2 * HasAzeriteTrait(shrouded_suffocation_trait) } * Enemies(tagged=1) >? 4 and 600 > 12 and VanishAllowed() and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(45) } and { target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade) }
}

AddFunction AssassinationCdsCdActions
{
 #call_action_list,name=essences,if=!stealthed.all&dot.rupture.ticking&buff.master_assassin.remains<=0
 if not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 AssassinationEssencesCdActions()

 unless not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 and AssassinationEssencesCdPostConditions()
 {
  #vendetta,if=!stealthed.rogue&dot.rupture.ticking&!debuff.vendetta.up&(!talent.subterfuge.enabled|!azerite.shrouded_suffocation.enabled|dot.garrote.pmultiplier>1&(spell_targets.fan_of_knives<6|!cooldown.vanish.up))&(!talent.nightstalker.enabled|!talent.exsanguinate.enabled|cooldown.exsanguinate.remains<5-2*talent.deeper_stratagem.enabled)&(!equipped.azsharas_font_of_power|azerite.shrouded_suffocation.enabled|debuff.razor_coral_debuff.down&cooldown.toxic_blade.remains<1)
  if not Stealthed() and target.DebuffPresent(rupture_debuff) and not target.DebuffPresent(vendetta_debuff) and { not Talent(subterfuge_talent) or not HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffPersistentMultiplier(garrote_debuff) > 1 and { Enemies(tagged=1) < 6 or not { not SpellCooldown(vanish) > 0 } } } and { not Talent(nightstalker_talent) or not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) < 5 - 2 * TalentPoints(deeper_stratagem_talent) } and { not HasEquippedItem(azsharas_font_of_power_item) or HasAzeriteTrait(shrouded_suffocation_trait) or target.DebuffExpires(razor_coral) and SpellCooldown(toxic_blade) < 1 } Spell(vendetta)
  #variable,name=ss_vanish_condition,value=azerite.shrouded_suffocation.enabled&(non_ss_buffed_targets>=1|spell_targets.fan_of_knives=3)&(ss_buffed_targets_above_pandemic=0|spell_targets.fan_of_knives>=6)
  #pool_resource,for_next=1,extra_amount=45
  #vanish,if=talent.subterfuge.enabled&!stealthed.rogue&cooldown.garrote.up&(variable.ss_vanish_condition|!azerite.shrouded_suffocation.enabled&dot.garrote.refreshable)&combo_points.deficit>=((1+2*azerite.shrouded_suffocation.enabled)*spell_targets.fan_of_knives)>?4&raid_event.adds.in>12
  unless Talent(subterfuge_talent) and not Stealthed() and not SpellCooldown(garrote) > 0 and { ss_vanish_condition() or not HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and ComboPointsDeficit() >= { 1 + 2 * HasAzeriteTrait(shrouded_suffocation_trait) } * Enemies(tagged=1) >? 4 and 600 > 12 and VanishAllowed() and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(45)
  {
   #shadowmeld,if=!stealthed.all&azerite.shrouded_suffocation.enabled&dot.garrote.refreshable&dot.garrote.pmultiplier<=1&combo_points.deficit>=1
   if not Stealthed() and HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) and target.DebuffPersistentMultiplier(garrote_debuff) <= 1 and ComboPointsDeficit() >= 1 Spell(shadowmeld)

   unless target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade)
   {
    #potion,if=buff.bloodlust.react|debuff.vendetta.up
    if { BuffPresent(bloodlust) or target.DebuffPresent(vendetta_debuff) } and CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
    #blood_fury,if=debuff.vendetta.up
    if target.DebuffPresent(vendetta_debuff) Spell(blood_fury_ap)
    #berserking,if=debuff.vendetta.up
    if target.DebuffPresent(vendetta_debuff) Spell(berserking)
    #fireblood,if=debuff.vendetta.up
    if target.DebuffPresent(vendetta_debuff) Spell(fireblood)
    #ancestral_call,if=debuff.vendetta.up
    if target.DebuffPresent(vendetta_debuff) Spell(ancestral_call)
    #use_item,name=galecallers_boon,if=cooldown.vendetta.remains>45
    if SpellCooldown(vendetta) > 45 AssassinationUseItemActions()
    #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.vendetta.remains>10-4*equipped.azsharas_font_of_power|target.time_to_die<20
    if target.DebuffExpires(razor_coral) or target.DebuffRemaining(vendetta_debuff) > 10 - 4 * HasEquippedItem(azsharas_font_of_power_item) or target.TimeToDie() < 20 AssassinationUseItemActions()
    #use_item,name=lurkers_insidious_gift,if=debuff.vendetta.up
    if target.DebuffPresent(vendetta_debuff) AssassinationUseItemActions()
    #use_item,name=lustrous_golden_plumage,if=debuff.vendetta.up
    if target.DebuffPresent(vendetta_debuff) AssassinationUseItemActions()
    #use_item,effect_name=gladiators_medallion,if=debuff.vendetta.up
    if target.DebuffPresent(vendetta_debuff) AssassinationUseItemActions()
    #use_item,effect_name=gladiators_badge,if=debuff.vendetta.up
    if target.DebuffPresent(vendetta_debuff) AssassinationUseItemActions()
    #use_item,effect_name=cyclotronic_blast,if=buff.master_assassin.remains<=0&!debuff.vendetta.up&!debuff.toxic_blade.up&buff.memory_of_lucid_dreams.down&energy<80&dot.rupture.remains>4
    if BuffRemaining(master_assassin_buff) <= 0 and not target.DebuffPresent(vendetta_debuff) and not target.DebuffPresent(toxic_blade_debuff) and BuffExpires(memory_of_lucid_dreams_essence_buff) and Energy() < 80 and target.DebuffRemaining(rupture_debuff) > 4 AssassinationUseItemActions()
    #use_items
    AssassinationUseItemActions()
   }
  }
 }
}

AddFunction AssassinationCdsCdPostConditions
{
 not Stealthed() and target.DebuffPresent(rupture_debuff) and BuffRemaining(master_assassin_buff) <= 0 and AssassinationEssencesCdPostConditions() or not { Talent(subterfuge_talent) and not Stealthed() and not SpellCooldown(garrote) > 0 and { ss_vanish_condition() or not HasAzeriteTrait(shrouded_suffocation_trait) and target.DebuffRefreshable(garrote_debuff) } and ComboPointsDeficit() >= { 1 + 2 * HasAzeriteTrait(shrouded_suffocation_trait) } * Enemies(tagged=1) >? 4 and 600 > 12 and VanishAllowed() and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(45) } and { target.DebuffRemaining(rupture_debuff) > 4 + 4 * MaxComboPoints() and not target.DebuffRefreshable(garrote_debuff) and Spell(exsanguinate) or target.DebuffPresent(rupture_debuff) and Spell(toxic_blade) }
}

### actions.direct

AddFunction AssassinationDirectMainActions
{
 #envenom,if=combo_points>=4+talent.deeper_stratagem.enabled&(debuff.vendetta.up|debuff.toxic_blade.up|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target)&(!talent.exsanguinate.enabled|cooldown.exsanguinate.remains>2)
 if ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } Spell(envenom)
 #variable,name=use_filler,value=combo_points.deficit>1|energy.deficit<=25+variable.energy_regen_combined|!variable.single_target
 #fan_of_knives,if=variable.use_filler&azerite.echoing_blades.enabled&spell_targets.fan_of_knives>=2
 if use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies(tagged=1) >= 2 Spell(fan_of_knives)
 #fan_of_knives,if=variable.use_filler&(buff.hidden_blades.stack>=19|(!priority_rotation&spell_targets.fan_of_knives>=4+(azerite.double_dose.rank>2)+stealthed.rogue))
 if use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or not CheckBoxOn(opt_priority_rotation) and Enemies(tagged=1) >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } Spell(fan_of_knives)
 #fan_of_knives,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives>=3
 if use_filler() and Enemies(tagged=1) >= 3 and not target.DebuffPresent(deadly_poison_debuff) Spell(fan_of_knives)
 #blindside,if=variable.use_filler&(buff.blindside.up|!talent.venom_rush.enabled&!azerite.double_dose.enabled)
 if use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } Spell(blindside)
 #mutilate,target_if=!dot.deadly_poison_dot.ticking,if=variable.use_filler&spell_targets.fan_of_knives=2
 if use_filler() and Enemies(tagged=1) == 2 and not target.DebuffPresent(deadly_poison_debuff) Spell(mutilate)
 #mutilate,if=variable.use_filler
 if use_filler() Spell(mutilate)
}

AddFunction AssassinationDirectMainPostConditions
{
}

AddFunction AssassinationDirectShortCdActions
{
}

AddFunction AssassinationDirectShortCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies(tagged=1) >= 2 and Spell(fan_of_knives) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or not CheckBoxOn(opt_priority_rotation) and Enemies(tagged=1) >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } and Spell(fan_of_knives) or use_filler() and Enemies(tagged=1) >= 3 and not target.DebuffPresent(deadly_poison_debuff) and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } and Spell(blindside) or use_filler() and Enemies(tagged=1) == 2 and not target.DebuffPresent(deadly_poison_debuff) and Spell(mutilate) or use_filler() and Spell(mutilate)
}

AddFunction AssassinationDirectCdActions
{
}

AddFunction AssassinationDirectCdPostConditions
{
 ComboPoints() >= 4 + TalentPoints(deeper_stratagem_talent) and { target.DebuffPresent(vendetta_debuff) or target.DebuffPresent(toxic_blade_debuff) or EnergyDeficit() <= 25 + energy_regen_combined() or not single_target() } and { not Talent(exsanguinate_talent) or SpellCooldown(exsanguinate) > 2 } and Spell(envenom) or use_filler() and HasAzeriteTrait(echoing_blades_trait) and Enemies(tagged=1) >= 2 and Spell(fan_of_knives) or use_filler() and { BuffStacks(hidden_blades_buff) >= 19 or not CheckBoxOn(opt_priority_rotation) and Enemies(tagged=1) >= 4 + { AzeriteTraitRank(double_dose_trait) > 2 } + Stealthed() } and Spell(fan_of_knives) or use_filler() and Enemies(tagged=1) >= 3 and not target.DebuffPresent(deadly_poison_debuff) and Spell(fan_of_knives) or use_filler() and { BuffPresent(blindside_buff) or not Talent(venom_rush_talent) and not HasAzeriteTrait(double_dose_trait) } and Spell(blindside) or use_filler() and Enemies(tagged=1) == 2 and not target.DebuffPresent(deadly_poison_debuff) and Spell(mutilate) or use_filler() and Spell(mutilate)
}

### actions.dot

AddFunction AssassinationDotMainActions
{
 #variable,name=skip_cycle_garrote,value=priority_rotation&spell_targets.fan_of_knives>3&(dot.garrote.remains<cooldown.garrote.duration|poisoned_bleeds>5)
 #variable,name=skip_cycle_rupture,value=priority_rotation&spell_targets.fan_of_knives>3&(debuff.toxic_blade.up|(poisoned_bleeds>5&!azerite.scent_of_blood.enabled))
 #variable,name=skip_rupture,value=debuff.vendetta.up&(debuff.toxic_blade.up|buff.master_assassin.remains>0)&dot.rupture.remains>2
 #rupture,if=talent.exsanguinate.enabled&((combo_points>=cp_max_spend&cooldown.exsanguinate.remains<1)|(!ticking&(time>10|combo_points>=2)))
 if Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } Spell(rupture)
 #pool_resource,for_next=1
 #garrote,if=(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1+3*(azerite.shrouded_suffocation.enabled&cooldown.vanish.up)&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains)>4&(buff.master_assassin.remains=0|!ticking&azerite.shrouded_suffocation.enabled)
 if { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } Spell(garrote)
 unless { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
 {
  #pool_resource,for_next=1
  #garrote,cycle_targets=1,if=!variable.skip_cycle_garrote&target!=self.target&(!talent.subterfuge.enabled|!(cooldown.vanish.up&cooldown.vendetta.remains<=4))&combo_points.deficit>=1+3*(azerite.shrouded_suffocation.enabled&cooldown.vanish.up)&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&!ss_buffed&(target.time_to_die-remains)>12&(buff.master_assassin.remains=0|!ticking&azerite.shrouded_suffocation.enabled)
  if not skip_cycle_garrote() and not False(target_is_target) and { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } Spell(garrote)
  unless not skip_cycle_garrote() and not False(target_is_target) and { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
  {
   #crimson_tempest,if=spell_targets>=2&remains<2+(spell_targets>=5)&combo_points>=4
   if Enemies(tagged=1) >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies(tagged=1) >= 5 } and ComboPoints() >= 4 Spell(crimson_tempest)
   #rupture,if=!variable.skip_rupture&combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
   if not skip_rupture() and ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 Spell(rupture)
   #rupture,cycle_targets=1,if=!variable.skip_cycle_rupture&!variable.skip_rupture&target!=self.target&combo_points>=4&refreshable&(pmultiplier<=1|remains<=tick_time&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&(!exsanguinated|remains<=tick_time*2&spell_targets.fan_of_knives>=3+azerite.shrouded_suffocation.enabled)&target.time_to_die-remains>4
   if not skip_cycle_rupture() and not skip_rupture() and not False(target_is_target) and ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 Spell(rupture)
  }
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
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { not skip_cycle_garrote() and not False(target_is_target) and { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and Spell(garrote) or not { not skip_cycle_garrote() and not False(target_is_target) and { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies(tagged=1) >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies(tagged=1) >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or not skip_rupture() and ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) or not skip_cycle_rupture() and not skip_rupture() and not False(target_is_target) and ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) } }
}

AddFunction AssassinationDotCdActions
{
}

AddFunction AssassinationDotCdPostConditions
{
 Talent(exsanguinate_talent) and { ComboPoints() >= MaxComboPoints() and SpellCooldown(exsanguinate) < 1 or not target.DebuffPresent(rupture_debuff) and { TimeInCombat() > 10 or ComboPoints() >= 2 } } and Spell(rupture) or { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and Spell(garrote) or not { { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 4 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { not skip_cycle_garrote() and not False(target_is_target) and { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and Spell(garrote) or not { not skip_cycle_garrote() and not False(target_is_target) and { not Talent(subterfuge_talent) or not { not SpellCooldown(vanish) > 0 and SpellCooldown(vendetta) <= 4 } } and ComboPointsDeficit() >= 1 + 3 * { HasAzeriteTrait(shrouded_suffocation_trait) and not SpellCooldown(vanish) > 0 } and target.Refreshable(garrote_debuff) and { PersistentMultiplier(garrote_debuff) <= 1 or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(garrote_debuff) <= target.CurrentTickTime(garrote_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and not False(ss_buffed) and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 12 and { not BuffRemaining(master_assassin_buff) > 0 or not target.DebuffPresent(garrote_debuff) and HasAzeriteTrait(shrouded_suffocation_trait) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Enemies(tagged=1) >= 2 and target.DebuffRemaining(crimson_tempest_debuff) < 2 + { Enemies(tagged=1) >= 5 } and ComboPoints() >= 4 and Spell(crimson_tempest) or not skip_rupture() and ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) or not skip_cycle_rupture() and not skip_rupture() and not False(target_is_target) and ComboPoints() >= 4 and target.Refreshable(rupture_debuff) and { PersistentMultiplier(rupture_debuff) <= 1 or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and { not target.DebuffPresent(exsanguinated) or target.DebuffRemaining(rupture_debuff) <= target.CurrentTickTime(rupture_debuff) * 2 and Enemies(tagged=1) >= 3 + HasAzeriteTrait(shrouded_suffocation_trait) } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 4 and Spell(rupture) } }
}

### actions.essences

AddFunction AssassinationEssencesMainActions
{
 #concentrated_flame,if=energy.time_to_max>1&!debuff.vendetta.up&(!dot.concentrated_flame_burn.ticking&!action.concentrated_flame.in_flight|full_recharge_time<gcd.max)
 if TimeToMaxEnergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } Spell(concentrated_flame_essence)
}

AddFunction AssassinationEssencesMainPostConditions
{
}

AddFunction AssassinationEssencesShortCdActions
{
 unless TimeToMaxEnergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } and Spell(concentrated_flame_essence)
 {
  #focused_azerite_beam,if=spell_targets.fan_of_knives>=2|raid_event.adds.in>60&energy<70
  if Enemies(tagged=1) >= 2 or 600 > 60 and Energy() < 70 Spell(focused_azerite_beam)
  #purifying_blast,if=spell_targets.fan_of_knives>=2|raid_event.adds.in>60
  if Enemies(tagged=1) >= 2 or 600 > 60 Spell(purifying_blast)
  #the_unbound_force,if=buff.reckless_force.up|buff.reckless_force_counter.stack<10
  if BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 Spell(the_unbound_force)
  #ripple_in_space
  Spell(ripple_in_space_essence)
  #worldvein_resonance,if=buff.lifeblood.stack<3
  if BuffStacks(lifeblood_buff) < 3 Spell(worldvein_resonance_essence)
 }
}

AddFunction AssassinationEssencesShortCdPostConditions
{
 TimeToMaxEnergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } and Spell(concentrated_flame_essence)
}

AddFunction AssassinationEssencesCdActions
{
 unless TimeToMaxEnergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } and Spell(concentrated_flame_essence)
 {
  #blood_of_the_enemy,if=debuff.vendetta.up&(!talent.toxic_blade.enabled|debuff.toxic_blade.up&combo_points.deficit<=1|debuff.vendetta.remains<=10)|target.time_to_die<=10
  if target.DebuffPresent(vendetta_debuff) and { not Talent(toxic_blade_talent) or target.DebuffPresent(toxic_blade_debuff) and ComboPointsDeficit() <= 1 or target.DebuffRemaining(vendetta_debuff) <= 10 } or target.TimeToDie() <= 10 Spell(blood_of_the_enemy)
  #guardian_of_azeroth,if=cooldown.vendetta.remains<3|debuff.vendetta.up|target.time_to_die<30
  if SpellCooldown(vendetta) < 3 or target.DebuffPresent(vendetta_debuff) or target.TimeToDie() < 30 Spell(guardian_of_azeroth)
  #guardian_of_azeroth,if=floor((target.time_to_die-30)%cooldown)>floor((target.time_to_die-30-cooldown.vendetta.remains)%cooldown)
  if { target.TimeToDie() - 30 } / SpellCooldown(guardian_of_azeroth) > { target.TimeToDie() - 30 - SpellCooldown(vendetta) } / SpellCooldown(guardian_of_azeroth) Spell(guardian_of_azeroth)

  unless { Enemies(tagged=1) >= 2 or 600 > 60 and Energy() < 70 } and Spell(focused_azerite_beam) or { Enemies(tagged=1) >= 2 or 600 > 60 } and Spell(purifying_blast) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or Spell(ripple_in_space_essence) or BuffStacks(lifeblood_buff) < 3 and Spell(worldvein_resonance_essence)
  {
   #memory_of_lucid_dreams,if=energy<50&!cooldown.vendetta.up
   if Energy() < 50 and not { not SpellCooldown(vendetta) > 0 } Spell(memory_of_lucid_dreams_essence)
  }
 }
}

AddFunction AssassinationEssencesCdPostConditions
{
 TimeToMaxEnergy() > 1 and not target.DebuffPresent(vendetta_debuff) and { not target.DebuffPresent(concentrated_flame_burn_debuff) and not InFlightToTarget(concentrated_flame_essence) or SpellFullRecharge(concentrated_flame_essence) < GCD() } and Spell(concentrated_flame_essence) or { Enemies(tagged=1) >= 2 or 600 > 60 and Energy() < 70 } and Spell(focused_azerite_beam) or { Enemies(tagged=1) >= 2 or 600 > 60 } and Spell(purifying_blast) or { BuffPresent(reckless_force_buff) or BuffStacks(reckless_force_counter) < 10 } and Spell(the_unbound_force) or Spell(ripple_in_space_essence) or BuffStacks(lifeblood_buff) < 3 and Spell(worldvein_resonance_essence)
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
 #marked_for_death,precombat_seconds=5,if=raid_event.adds.in>15
 if 600 > 15 Spell(marked_for_death)
 #apply_poison
 #stealth
 Spell(stealth)
}

AddFunction AssassinationPrecombatShortCdPostConditions
{
}

AddFunction AssassinationPrecombatCdActions
{
 #flask
 #augmentation
 #food
 #snapshot_stats
 #potion
 # if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_potion_of_unbridled_fury usable=1)
 #use_item,name=azsharas_font_of_power
 AssassinationUseItemActions()
}

AddFunction AssassinationPrecombatCdPostConditions
{
}

### actions.stealthed

AddFunction AssassinationStealthedMainActions
{
 #rupture,if=combo_points>=4&(talent.nightstalker.enabled|talent.subterfuge.enabled&(talent.exsanguinate.enabled&cooldown.exsanguinate.remains<=2|!ticking)&variable.single_target)&target.time_to_die-remains>6
 if ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 Spell(rupture)
 #pool_resource,for_next=1
 #garrote,if=azerite.shrouded_suffocation.enabled&buff.subterfuge.up&buff.subterfuge.remains<1.3&!ss_buffed
 if HasAzeriteTrait(shrouded_suffocation_trait) and BuffPresent(subterfuge_buff) and BuffRemaining(subterfuge_buff) < 1.3 and not False(ss_buffed) Spell(garrote)
 unless HasAzeriteTrait(shrouded_suffocation_trait) and BuffPresent(subterfuge_buff) and BuffRemaining(subterfuge_buff) < 1.3 and not False(ss_buffed) and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
 {
  #pool_resource,for_next=1
  #garrote,target_if=min:remains,if=talent.subterfuge.enabled&(remains<12|pmultiplier<=1)&target.time_to_die-remains>2
  if Talent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or PersistentMultiplier(garrote_debuff) <= 1 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 Spell(garrote)
  unless Talent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or PersistentMultiplier(garrote_debuff) <= 1 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
  {
   #rupture,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&!dot.rupture.ticking&variable.single_target
   if Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and single_target() Spell(rupture)
   #pool_resource,for_next=1
   #garrote,target_if=min:remains,if=talent.subterfuge.enabled&azerite.shrouded_suffocation.enabled&target.time_to_die>remains&(remains<18|!ss_buffed)
   if Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not False(ss_buffed) } Spell(garrote)
   unless Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not False(ss_buffed) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
   {
    #pool_resource,for_next=1
    #garrote,if=talent.subterfuge.enabled&talent.exsanguinate.enabled&cooldown.exsanguinate.remains<1&prev_gcd.1.rupture&dot.rupture.remains>5+4*cp_max_spend
    if Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() Spell(garrote)
   }
  }
 }
}

AddFunction AssassinationStealthedMainPostConditions
{
}

AddFunction AssassinationStealthedShortCdActions
{
}

AddFunction AssassinationStealthedShortCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or HasAzeriteTrait(shrouded_suffocation_trait) and BuffPresent(subterfuge_buff) and BuffRemaining(subterfuge_buff) < 1.3 and not False(ss_buffed) and Spell(garrote) or not { HasAzeriteTrait(shrouded_suffocation_trait) and BuffPresent(subterfuge_buff) and BuffRemaining(subterfuge_buff) < 1.3 and not False(ss_buffed) and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Talent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or PersistentMultiplier(garrote_debuff) <= 1 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not { Talent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or PersistentMultiplier(garrote_debuff) <= 1 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and single_target() and Spell(rupture) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not False(ss_buffed) } and Spell(garrote) or not { Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not False(ss_buffed) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote) } }
}

AddFunction AssassinationStealthedCdActions
{
}

AddFunction AssassinationStealthedCdPostConditions
{
 ComboPoints() >= 4 and { Talent(nightstalker_talent) or Talent(subterfuge_talent) and { Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) <= 2 or not target.DebuffPresent(rupture_debuff) } and single_target() } and target.TimeToDie() - target.DebuffRemaining(rupture_debuff) > 6 and Spell(rupture) or HasAzeriteTrait(shrouded_suffocation_trait) and BuffPresent(subterfuge_buff) and BuffRemaining(subterfuge_buff) < 1.3 and not False(ss_buffed) and Spell(garrote) or not { HasAzeriteTrait(shrouded_suffocation_trait) and BuffPresent(subterfuge_buff) and BuffRemaining(subterfuge_buff) < 1.3 and not False(ss_buffed) and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Talent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or PersistentMultiplier(garrote_debuff) <= 1 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and Spell(garrote) or not { Talent(subterfuge_talent) and { target.DebuffRemaining(garrote_debuff) < 12 or PersistentMultiplier(garrote_debuff) <= 1 } and target.TimeToDie() - target.DebuffRemaining(garrote_debuff) > 2 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and { Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and not target.DebuffPresent(rupture_debuff) and single_target() and Spell(rupture) or Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not False(ss_buffed) } and Spell(garrote) or not { Talent(subterfuge_talent) and HasAzeriteTrait(shrouded_suffocation_trait) and target.TimeToDie() > target.DebuffRemaining(garrote_debuff) and { target.DebuffRemaining(garrote_debuff) < 18 or not False(ss_buffed) } and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote) } and Talent(subterfuge_talent) and Talent(exsanguinate_talent) and SpellCooldown(exsanguinate) < 1 and PreviousGCDSpell(rupture) and target.DebuffRemaining(rupture_debuff) > 5 + 4 * MaxComboPoints() and Spell(garrote) } }
}
]]

		OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
	end
end
