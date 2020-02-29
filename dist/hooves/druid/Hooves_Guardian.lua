local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidGuardianHooves = function(OvaleScripts)
do
	local name = "hooves_guardian"
	local desc = "[Hooves][8.2] Druid: Guardian"
	local code = [[
# Based on SimulationCraft profile "Druid_Guardian_T19P".
#	class=druid
#	spec=guardian
#	talents=3323323
	
Include(ovale_common)

Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

Define(travel_form 783)
Define(travel_form_buff 783)

# Guardian
AddIcon specialization=3 help=main
{
	# Pre-combat stuff
	if not mounted() and HealthPercent() > 1
	{
		#mark_of_the_wild,if=!aura.str_agi_int.up
		# if not BuffPresent(str_agi_int_buff any=1) Spell(mark_of_the_wild)
		# CHANGE: Cast Healing Touch to gain Bloodtalons buff if less than 20s remaining on the buff.
		#healing_touch,if=talent.bloodtalons.enabled
		#if Talent(bloodtalons_talent) Spell(healing_touch)
		# if Talent(bloodtalons_talent) and BuffRemaining(bloodtalons_buff) < 20 and not InCombat() and Speed() == 0 Spell(healing_touch)
		if target.Present() and target.Exists() and not target.IsFriend()
		{
			#bear_form
			#if not BuffPresent(bear_form) Spell(bear_form)
		}
	}
	
	# Activate cat form when this checkbox is on.
		
	# Rotation
	if Stance(2) and target.InRange(rake) and HasFullControl() and target.Present()
	{
	
		#cat rotation
		if BuffPresent(prowl_buff) or BuffPresent(shadowmeld_buff) Spell(rake)
		#ferocious_bite,target_if=dot.rip.ticking&dot.rip.remains<3&target.time_to_die>10&(talent.sabertooth.enabled)
		if target.DebuffPresent(rip_debuff) and target.DebuffRemaining(rip_debuff) < 3 and target.TimeToDie() > 10 Spell(ferocious_bite)
		if ComboPoints() > 4
		{
			if not target.DebuffPresent(rip_debuff) or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.3 or target.DebuffRemaining(rip_debuff) <= BaseDuration(rip_debuff) * 0.8 and PersistentMultiplier(rip_debuff) > target.DebuffPersistentMultiplier(rip_debuff) and target.TimeToDie() > 8 Spell(rip)
		}
		if ComboPoints() >3 and ComboPoints < 5
		{
			Spell(rake)
		}
		if not target.DebuffPresent(rake_debuff)or target.DebuffRemaining(rake_debuff) <= BaseDuration(rake_debuff) * 0.3 Spell(rake)
		if target.DebuffPresent(rake_debuff) and target.DebuffPresent(rip_debuff) Spell(bear_form)
		if target.DebuffRemaining(rake_debuff) > { PowerCost(shred) + PowerCost(rake) - Energy() } / EnergyRegenRate() Spell(shred)
	}
	
	if Stance(1) and target.InRange(mangle) and HasFullControl() and target.Present()
	{
		if ( HealthPercent() < 70  and not BuffPresent(frenzied_regeneration_buff))Spell(frenzied_regeneration)
		# AOE for threat!
	
		if Boss()
		{
			GuardianDefaultCdActions()
		}
	
		# Short Cooldowns
		if not target.DebuffPresent(concentrated_flame_burn_debuff) Spell(concentrated_flame_essence)
		GuardianDefaultShortCdActions()
	
		# Default Actions
		GuardianDefaultMainActions()
	}
	# Interrupt

	if InCombat() and target.Present() and not target.IsFriend() and not target.InRange(mangle) and target.InRange(wild_charge) and { TimeInCombat() < 6 or Falling() } Spell(wild_charge)

}
	# Based on SimulationCraft profile "T24_Druid_Guardian".
#    class=druid
#    spec=guardian
#    talents=1000131

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)

AddFunction GuardianInterruptActions
{
 
}

AddFunction GuardianUseHeartEssence
{
 if not target.DebuffPresent(concentrated_flame_burn_debuff) Spell(concentrated_flame_essence)
}

AddFunction GuardianUseItemActions
{
 
}

AddFunction GuardianGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
 {
  if target.InRange(wild_charge) Spell(wild_charge)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.default

AddCheckBox(useMaul L(MAUL))
AddFunction GuardianDefaultMainActions
{
 #call_action_list,name=cooldowns
 GuardianCooldownsMainActions()

 unless GuardianCooldownsMainPostConditions()
 {
   if CheckBoxOn(useMaul) and Rage() >= 40 Spell(maul)
  if (not CheckBoxOn(useMaul) and BuffPresent(ironfur_buff) == 0) or BuffPresent(gory_fur_buff) == 1 or Rage() >= 50 Spell(ironfur)
	
  if not(target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff)) or target.DebuffRefreshable(thrash_bear_debuff) Spell(thrash)
  #maul,if=rage.deficit<10&active_enemies<4
  if RageDeficit() < 10 and enemies(tagged=1) < 4 Spell(maul)
  #maul,if=essence.conflict_and_strife.major&!buff.sharpened_claws.up
  #if AzeriteEssenceIsMajor(conflict_and_strife_essence_id) and not BuffPresent(sharpened_claws_buff) Spell(maul)
  #pulverize,target_if=dot.thrash_bear.stack=dot.thrash_bear.max_stacks
  if target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) Spell(pulverize)
  #moonfire,target_if=dot.moonfire.refreshable&active_enemies<2
  if target.DebuffRefreshable(moonfire) and enemies(tagged=1) < 2 Spell(moonfire)
  #swipe,if=buff.incarnation.down&active_enemies>4
  if BuffExpires(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 4 Spell(swipe_bear)
  #mangle,if=dot.thrash_bear.ticking
  if target.DebuffPresent(thrash_bear_debuff) Spell(mangle)
  #moonfire,target_if=buff.galactic_guardian.up&active_enemies<2
  if BuffPresent(galactic_guardian_buff) and enemies(tagged=1) < 2 Spell(moonfire)
  #maul
  #Spell(maul)
  #swipe
  Spell(swipe_bear)
 }
}

AddFunction GuardianDefaultMainPostConditions
{
 GuardianCooldownsMainPostConditions()
}

AddFunction GuardianDefaultShortCdActions
{
 #auto_attack
 GuardianGetInMeleeRange()
 #call_action_list,name=cooldowns
 GuardianCooldownsShortCdActions()

 unless GuardianCooldownsShortCdPostConditions() or RageDeficit() < 10 and enemies(tagged=1) < 4 and Spell(maul) or AzeriteEssenceIsMajor(conflict_and_strife_essence) and not BuffPresent(sharpened_claws_buff) and Spell(maul)
 {
  #ironfur,if=cost=0|(rage>cost&azerite.layered_mane.enabled&active_enemies>2)
  if PowerCost(ironfur) == 0 or Rage() > PowerCost(ironfur) and HasAzeriteTrait(layered_mane_trait) and enemies(tagged=1) > 2 Spell(ironfur)

  unless target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire) and enemies(tagged=1) < 2 and Spell(moonfire)
  {
   #thrash,if=(buff.incarnation.down&active_enemies>1)|(buff.incarnation.up&active_enemies>4)
   if BuffExpires(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 1 or BuffPresent(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 4 Spell(thrash)

   unless BuffExpires(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 4 and Spell(swipe_bear) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and enemies(tagged=1) < 2 and Spell(moonfire)
   {
    #thrash
    Spell(thrash)
   }
  }
 }
}

AddFunction GuardianDefaultShortCdPostConditions
{
 GuardianCooldownsShortCdPostConditions() or RageDeficit() < 10 and enemies(tagged=1) < 4 and Spell(maul) or AzeriteEssenceIsMajor(conflict_and_strife_essence) and not BuffPresent(sharpened_claws_buff) and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire) and enemies(tagged=1) < 2 and Spell(moonfire) or BuffExpires(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 4 and Spell(swipe_bear) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and enemies(tagged=1) < 2 and Spell(moonfire) or Spell(maul) or Spell(swipe_bear)
}

AddFunction GuardianDefaultCdActions
{
 GuardianInterruptActions()
 #call_action_list,name=cooldowns
 GuardianCooldownsCdActions()
}

AddFunction GuardianDefaultCdPostConditions
{
 GuardianCooldownsCdPostConditions() or RageDeficit() < 10 and enemies(tagged=1) < 4 and Spell(maul) or AzeriteEssenceIsMajor(conflict_and_strife_essence) and not BuffPresent(sharpened_claws_buff) and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == MaxStacks(thrash_bear_debuff) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire) and enemies(tagged=1) < 2 and Spell(moonfire) or BuffExpires(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 4 and Spell(swipe_bear) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and enemies(tagged=1) < 2 and Spell(moonfire) or Spell(maul) or Spell(swipe_bear)
}

### actions.cooldowns

AddFunction GuardianCooldownsMainActions
{
 #blood_fury
 Spell(blood_fury)
}

AddFunction GuardianCooldownsMainPostConditions
{
}

AddFunction GuardianCooldownsShortCdActions
{
 unless Spell(blood_fury)
 {
  #barkskin,if=buff.bear_form.up
  #if BuffPresent(bear_form) Spell(barkskin)
  #lunar_beam,if=buff.bear_form.up
  #if BuffPresent(bear_form) Spell(lunar_beam)
  #bristling_fur,if=buff.bear_form.up
  #if BuffPresent(bear_form) Spell(bristling_fur)
 }
}

AddFunction GuardianCooldownsShortCdPostConditions
{
 Spell(blood_fury)
}

AddFunction GuardianCooldownsCdActions
{
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_focused_resolve usable=1)
 #heart_essence
 GuardianUseHeartEssence()

 unless Spell(blood_fury)
 {
  #berserking
  Spell(berserking)
  #arcane_torrent
  Spell(arcane_torrent_energy)
  #lights_judgment
  Spell(lights_judgment)
  #fireblood
  Spell(fireblood)
  #ancestral_call
  Spell(ancestral_call)

  unless BuffPresent(bear_form) and Spell(lunar_beam)
  {
   #incarnation,if=(dot.moonfire.ticking|active_enemies>1)&dot.thrash_bear.ticking
   #if { target.DebuffPresent(moonfire) or enemies(tagged=1) > 1 } and target.DebuffPresent(thrash_bear_debuff) Spell(incarnation_guardian_of_ursoc)
   #use_item,name=ashvanes_razor_coral,if=debuff.razor_coral_debuff.down|debuff.conductive_ink_debuff.up&target.health.pct<31|target.time_to_die<20
   if target.DebuffExpires(razor_coral_debuff) or target.DebuffPresent(conductive_ink_debuff) and target.HealthPercent() < 31 or target.TimeToDie() < 20 GuardianUseItemActions()
   #use_items
   GuardianUseItemActions()
  }
 }
}

AddFunction GuardianCooldownsCdPostConditions
{
 Spell(blood_fury) or BuffPresent(bear_form) and Spell(lunar_beam)
}

### actions.precombat

AddFunction GuardianPrecombatMainActions
{
 #bear_form
 Spell(bear_form)
}

AddFunction GuardianPrecombatMainPostConditions
{
}

AddFunction GuardianPrecombatShortCdActions
{
}

AddFunction GuardianPrecombatShortCdPostConditions
{
 Spell(bear_form)
}

AddFunction GuardianPrecombatCdActions
{
 #flask
 #food
 #augmentation
 #snapshot_stats
 #memory_of_lucid_dreams
 Spell(memory_of_lucid_dreams_essence)

 unless Spell(bear_form)
 {
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(item_focused_resolve usable=1)
 }
}

AddFunction GuardianPrecombatCdPostConditions
{
 Spell(bear_form)
}

]]
		OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
	end
end