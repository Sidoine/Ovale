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
	if Stance(1) and target.InRange(mangle) and HasFullControl() and target.Present()
	{
		if ( HealthPercent() < 70  and not BuffPresent(frenzied_regeneration_buff))Spell(frenzied_regeneration)
		# AOE for threat!
		if target.DebuffExpires(thrash_bear_debuff) Spell(thrash_bear)
		Spell(concentrated_flame_essence)
		if Boss()
		{
			GuardianDefaultCdActions()
		}
	
		# Short Cooldowns
		GuardianDefaultShortCdActions()
	
		# Default Actions
		GuardianDefaultMainActions()
	}
	# Interrupt

	if InCombat() and target.Present() and not target.IsFriend() and not target.InRange(mangle) and target.InRange(wild_charge) and { TimeInCombat() < 6 or Falling() } Spell(wild_charge)

}
	
# AddCheckBox(aoe "AoE 3+")
# Based on SimulationCraft profile "T23_Druid_Guardian".
#    class=druid
#    spec=guardian
#    talents=1000131

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_druid_spells)
AddFunction GuardianGetInMeleeRange
{
 if CheckBoxOn(opt_melee_range) and Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred)
 {
  if target.InRange(wild_charge) Spell(wild_charge)
  Texture(misc_arrowlup help=L(not_in_melee_range))
 }
}

### actions.default

AddFunction GuardianDefaultMainActions
{
 #call_action_list,name=cooldowns
 GuardianCooldownsMainActions()

 unless GuardianCooldownsMainPostConditions()
 {
  #maul,if=rage.deficit<10&active_enemies<4
  if InCombat() and BuffExpires(bristling_fur_buff)
	{
		if BuffPresent(ironfur_buff) == 0 or BuffPresent(gory_fur_buff) == 1 or Rage() >= 50 Spell(ironfur)
	}
  #pulverize,target_if=dot.thrash_bear.stack=dot.thrash_bear.max_stacks
  if target.DebuffStacks(thrash_bear_debuff) == SpellData(thrash_bear_debuff max_stacks) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) Spell(pulverize)
  #moonfire,target_if=dot.moonfire.refreshable&active_enemies<2
  if target.DebuffRefreshable(moonfire) and enemies(tagged=1) < 2 Spell(moonfire)
  #swipe_bear,if=buff.incarnation.down&active_enemies>4
  if BuffExpires(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 4 Spell(swipe_bear)
  #mangle,if=dot.thrash_bear.ticking
  if target.DebuffPresent(thrash_bear_debuff) Spell(mangle)
  #moonfire,target_if=buff.galactic_guardian.up&active_enemies<2
  if BuffPresent(galactic_guardian_buff) and enemies(tagged=1) < 2 Spell(moonfire)
  #maul
  
  #moonfire,if=azerite.power_of_the_moon.rank>1&active_enemies=1
  if AzeriteTraitRank(power_of_the_moon_trait) > 1 and enemies(tagged=1) == 1 Spell(moonfire)
  #swipe_bear
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

 unless GuardianCooldownsShortCdPostConditions() or RageDeficit() < 10 and enemies(tagged=1) < 4 and Spell(maul)
 {
  #ironfur,if=cost=0|(rage>cost&azerite.layered_mane.enabled&active_enemies>2)
  if PowerCost(ironfur) == 0 or Rage() > PowerCost(ironfur) and HasAzeriteTrait(layered_mane_trait) and enemies(tagged=1) > 2 Spell(ironfur)

  unless target.DebuffStacks(thrash_bear_debuff) == SpellData(thrash_bear_debuff max_stacks) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and enemies(tagged=1) < 2 and Spell(moonfire)
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
 GuardianCooldownsShortCdPostConditions() or RageDeficit() < 10 and enemies(tagged=1) < 4 and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == SpellData(thrash_bear_debuff max_stacks) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and enemies(tagged=1) < 2 and Spell(moonfire) or BuffExpires(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 4 and Spell(swipe_bear) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and enemies(tagged=1) < 2 and Spell(moonfire) or Spell(maul) or AzeriteTraitRank(power_of_the_moon_trait) > 1 and enemies(tagged=1) == 1 and Spell(moonfire) or Spell(swipe_bear)
}

AddFunction GuardianDefaultCdActions
{
  #call_action_list,name=cooldowns
 GuardianCooldownsCdActions()

 unless GuardianCooldownsCdPostConditions() or RageDeficit() < 10 and enemies(tagged=1) < 4 and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == SpellData(thrash_bear_debuff max_stacks) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and enemies(tagged=1) < 2 and Spell(moonfire)
 {
  #incarnation
  Spell(incarnation_guardian_of_ursoc)
 }
}

AddFunction GuardianDefaultCdPostConditions
{
 GuardianCooldownsCdPostConditions() or RageDeficit() < 10 and enemies(tagged=1) < 4 and Spell(maul) or target.DebuffStacks(thrash_bear_debuff) == SpellData(thrash_bear_debuff max_stacks) and target.DebuffGain(thrash_bear_debuff) <= BaseDuration(thrash_bear_debuff) and Spell(pulverize) or target.DebuffRefreshable(moonfire_debuff) and enemies(tagged=1) < 2 and Spell(moonfire) or BuffExpires(incarnation_guardian_of_ursoc_buff) and enemies(tagged=1) > 4 and Spell(swipe_bear) or target.DebuffPresent(thrash_bear_debuff) and Spell(mangle) or BuffPresent(galactic_guardian_buff) and enemies(tagged=1) < 2 and Spell(moonfire) or Spell(maul) or AzeriteTraitRank(power_of_the_moon_trait) > 1 and enemies(tagged=1) == 1 and Spell(moonfire) or Spell(swipe_bear)
}

### actions.cooldowns

AddFunction GuardianCooldownsMainActions
{
}

AddFunction GuardianCooldownsMainPostConditions
{
}

AddFunction GuardianCooldownsShortCdActions
{
 #barkskin,if=buff.bear_form.up
 
 #lunar_beam,if=buff.bear_form.up
 if DebuffPresent(bear_form) Spell(lunar_beam)
 #bristling_fur,if=buff.bear_form.up
 
}

AddFunction GuardianCooldownsShortCdPostConditions
{
}

AddFunction GuardianCooldownsCdActions
{
 #potion
 if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(bursting_blood usable=1)
 #blood_fury
 Spell(blood_fury)
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

 unless DebuffPresent(bear_form) and Spell(lunar_beam)
 {
  #use_items
  
 }
}

AddFunction GuardianCooldownsCdPostConditions
{
 DebuffPresent(bear_form) and Spell(lunar_beam)
}

### actions.precombat

AddFunction GuardianPrecombatMainActions
{
 #flask
 #food
 #augmentation
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
 unless Spell(bear_form)
 {
  #snapshot_stats
  #potion
  if CheckBoxOn(opt_use_consumables) and target.Classification(worldboss) Item(bursting_blood usable=1)
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