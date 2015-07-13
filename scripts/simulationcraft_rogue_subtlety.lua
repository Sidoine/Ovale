local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_rogue_subtlety_t18m"
	local desc = "[6.2] SimulationCraft: Rogue_Subtlety_T18M"
	local code = [[
# Based on SimulationCraft profile "Rogue_Subtlety_T18M".
#	class=rogue
#	spec=subtlety
#	talents=2000032
#	glyphs=energy/hemorrhaging_veins/vanish

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_rogue_spells)

Define(honor_among_thieves_cooldown_buff 51699)
	SpellInfo(honor_among_thieves_cooldown_buff duration=2.2)

AddCheckBox(opt_interrupt L(interrupt) default specialization=subtlety)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=subtlety)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=subtlety)

AddFunction SubtletyUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction SubtletyUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction SubtletyGetInMeleeRange
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(kick)
	{
		Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction SubtletyInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(kick) Spell(kick)
		if not target.Classification(worldboss)
		{
			if target.InRange(cheap_shot) Spell(cheap_shot)
			if target.InRange(deadly_throw) and ComboPoints() == 5 Spell(deadly_throw)
			if target.InRange(kidney_shot) Spell(kidney_shot)
			Spell(arcane_torrent_energy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

### actions.default

AddFunction SubtletyDefaultMainActions
{
	#premeditation,if=combo_points<4
	if ComboPoints() < 4 and ComboPoints() < 5 Spell(premeditation)
	#wait,sec=buff.subterfuge.remains-0.1,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
	unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.1 > 0
	{
		#pool_resource,for_next=1,extra_amount=50
		#shadow_dance,if=energy>=110&buff.stealth.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
		unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
		{
			#pool_resource,for_next=1,extra_amount=50
			#shadowmeld,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<4-talent.anticipation.enabled&buff.stealth.down&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
			unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(stealthed_buff any=1) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(50)
			{
				#pool_resource,for_next=1,extra_amount=50
				#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<4-talent.anticipation.enabled&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
				unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
				{
					#pool_resource,for_next=1,extra_amount=90
					#shadowmeld,if=talent.subterfuge.enabled&energy>=90&combo_points<4-talent.anticipation.enabled&buff.stealth.down&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
					unless Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(stealthed_buff any=1) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(90)
					{
						#pool_resource,for_next=1,extra_amount=90
						#vanish,if=talent.subterfuge.enabled&energy>=100&combo_points<4-talent.anticipation.enabled&buff.shadow_dance.down
						unless Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(shadow_dance_buff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
						{
							#run_action_list,name=finisher,if=combo_points=5&debuff.find_weakness.remains&buff.shadow_reflection.remains
							if ComboPoints() == 5 and target.DebuffPresent(find_weakness_debuff) and BuffPresent(shadow_reflection_buff) SubtletyFinisherMainActions()
							#pool_resource,for_next=1
							#ambush,if=talent.anticipation.enabled&combo_points+anticipation_charges<8&time>2
							if Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 8 and TimeInCombat() > 2 Spell(ambush)
							unless Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 8 and TimeInCombat() > 2 and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
							{
								#run_action_list,name=finisher,if=combo_points=5&(buff.vanish.down|!talent.shadow_focus.enabled)
								if ComboPoints() == 5 and { BuffExpires(vanish_buff) or not Talent(shadow_focus_talent) } SubtletyFinisherMainActions()
								#run_action_list,name=generator,if=combo_points<4|(talent.anticipation.enabled&anticipation_charges<3&debuff.find_weakness.down)
								if ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and target.DebuffExpires(find_weakness_debuff) SubtletyGeneratorMainActions()
							}
						}
					}
				}
			}
		}
	}
}

AddFunction SubtletyDefaultShortCdActions
{
	#vanish,if=set_bonus.tier18_4pc=1&time<1
	if ArmorSetBonus(T18 4) == 1 and TimeInCombat() < 1 Spell(vanish)
	#wait,sec=buff.subterfuge.remains-0.1,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
	unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.1 > 0
	{
		#pool_resource,for_next=1,extra_amount=50
		#shadow_dance,if=energy>=110&buff.stealth.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
		if Energy() >= 110 and BuffExpires(stealthed_buff any=1) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } Spell(shadow_dance)
		unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
		{
			#pool_resource,for_next=1,extra_amount=50
			#shadowmeld,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<4-talent.anticipation.enabled&buff.stealth.down&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
			unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(stealthed_buff any=1) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(50)
			{
				#pool_resource,for_next=1,extra_amount=50
				#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<4-talent.anticipation.enabled&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
				if Talent(shadow_focus_talent) and Energy() >= 45 and Energy() <= 75 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
				unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
				{
					#pool_resource,for_next=1,extra_amount=90
					#shadowmeld,if=talent.subterfuge.enabled&energy>=90&combo_points<4-talent.anticipation.enabled&buff.stealth.down&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
					unless Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(stealthed_buff any=1) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(90)
					{
						#vanish,if=set_bonus.tier18_4pc=1&buff.shadow_reflection.up&combo_points<3
						if ArmorSetBonus(T18 4) == 1 and BuffPresent(shadow_reflection_buff) and ComboPoints() < 3 Spell(vanish)
						#pool_resource,for_next=1,extra_amount=90
						#vanish,if=talent.subterfuge.enabled&energy>=100&combo_points<4-talent.anticipation.enabled&buff.shadow_dance.down
						if Talent(subterfuge_talent) and Energy() >= 100 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(shadow_dance_buff) Spell(vanish)
						unless Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(shadow_dance_buff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
						{
							#marked_for_death,if=combo_points=0
							if ComboPoints() == 0 Spell(marked_for_death)

							unless ComboPoints() == 5 and target.DebuffPresent(find_weakness_debuff) and BuffPresent(shadow_reflection_buff) and SubtletyFinisherShortCdPostConditions()
							{
								#pool_resource,for_next=1
								#ambush,if=talent.anticipation.enabled&combo_points+anticipation_charges<8&time>2
								unless Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 8 and TimeInCombat() > 2 and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
								{
									unless ComboPoints() == 5 and { BuffExpires(vanish_buff) or not Talent(shadow_focus_talent) } and SubtletyFinisherShortCdPostConditions()
									{
										#run_action_list,name=generator,if=combo_points<4|(talent.anticipation.enabled&anticipation_charges<3&debuff.find_weakness.down)
										if ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and target.DebuffExpires(find_weakness_debuff) SubtletyGeneratorShortCdActions()
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

AddFunction SubtletyDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|(buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.shadow_dance.up))&(trinket.stat.agi.react|trinket.stat.multistrike.react|buff.archmages_greater_incandescence_agi.react)|((buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.shadow_dance.up))&target.time_to_die<136)
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(shadow_dance_buff) } and { BuffPresent(trinket_stat_agi_buff) or BuffPresent(trinket_stat_multistrike_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(shadow_dance_buff) } and target.TimeToDie() < 136 SubtletyUsePotionAgility()
	#kick
	SubtletyInterruptActions()
	#shadow_reflection,if=buff.shadow_dance.up|time<2
	if BuffPresent(shadow_dance_buff) or TimeInCombat() < 2 Spell(shadow_reflection)
	#use_item,slot=finger1,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) SubtletyUseItemActions()
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury_ap)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<80&buff.shadow_dance.up
	if Energy() < 80 and BuffPresent(shadow_dance_buff) Spell(arcane_torrent_energy)
	#wait,sec=buff.subterfuge.remains-0.1,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
	unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.1 > 0
	{
		#pool_resource,for_next=1,extra_amount=50
		#shadow_dance,if=energy>=110&buff.stealth.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
		unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
		{
			#pool_resource,for_next=1,extra_amount=50
			#shadowmeld,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<4-talent.anticipation.enabled&buff.stealth.down&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
			if Talent(shadow_focus_talent) and Energy() >= 45 and Energy() <= 75 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(stealthed_buff any=1) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(shadowmeld)
			unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(stealthed_buff any=1) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(50)
			{
				#pool_resource,for_next=1,extra_amount=50
				#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<4-talent.anticipation.enabled&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
				unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
				{
					#pool_resource,for_next=1,extra_amount=90
					#shadowmeld,if=talent.subterfuge.enabled&energy>=90&combo_points<4-talent.anticipation.enabled&buff.stealth.down&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
					if Talent(subterfuge_talent) and Energy() >= 90 and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(stealthed_buff any=1) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(shadowmeld)
					unless Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(stealthed_buff any=1) and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(shadowmeld) and SpellCooldown(shadowmeld) < TimeToEnergy(90)
					{
						#pool_resource,for_next=1,extra_amount=90
						#vanish,if=talent.subterfuge.enabled&energy>=100&combo_points<4-talent.anticipation.enabled&buff.shadow_dance.down
						unless Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() < 4 - TalentPoints(anticipation_talent) and BuffExpires(shadow_dance_buff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
						{
							#run_action_list,name=finisher,if=combo_points=5&debuff.find_weakness.remains&buff.shadow_reflection.remains
							if ComboPoints() == 5 and target.DebuffPresent(find_weakness_debuff) and BuffPresent(shadow_reflection_buff) SubtletyFinisherCdActions()

							unless ComboPoints() == 5 and target.DebuffPresent(find_weakness_debuff) and BuffPresent(shadow_reflection_buff) and SubtletyFinisherCdPostConditions()
							{
								#pool_resource,for_next=1
								#ambush,if=talent.anticipation.enabled&combo_points+anticipation_charges<8&time>2
								unless Talent(anticipation_talent) and ComboPoints() + BuffStacks(anticipation_buff) < 8 and TimeInCombat() > 2 and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
								{
									#run_action_list,name=finisher,if=combo_points=5&(buff.vanish.down|!talent.shadow_focus.enabled)
									if ComboPoints() == 5 and { BuffExpires(vanish_buff) or not Talent(shadow_focus_talent) } SubtletyFinisherCdActions()

									unless ComboPoints() == 5 and { BuffExpires(vanish_buff) or not Talent(shadow_focus_talent) } and SubtletyFinisherCdPostConditions()
									{
										#run_action_list,name=generator,if=combo_points<4|(talent.anticipation.enabled&anticipation_charges<3&debuff.find_weakness.down)
										if ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and target.DebuffExpires(find_weakness_debuff) SubtletyGeneratorCdActions()

										unless { ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and target.DebuffExpires(find_weakness_debuff) } and SubtletyGeneratorCdPostConditions()
										{
											#run_action_list,name=pool
											SubtletyPoolCdActions()
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}

### actions.finisher

AddFunction SubtletyFinisherMainActions
{
	#rupture,cycle_targets=1,if=(!ticking|remains<duration*0.3|(buff.shadow_reflection.remains>8&dot.rupture.remains<12))
	if not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 Spell(rupture)
	#slice_and_dice,if=((buff.slice_and_dice.remains<10.8&debuff.find_weakness.down)|buff.slice_and_dice.remains<6)&buff.slice_and_dice.remains<target.time_to_die
	if { BuffRemaining(slice_and_dice_buff) < 10.8 and target.DebuffExpires(find_weakness_debuff) or BuffRemaining(slice_and_dice_buff) < 6 } and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() Spell(slice_and_dice)
	#death_from_above
	Spell(death_from_above)
	#crimson_tempest,if=(spell_targets.crimson_tempest>=2&debuff.find_weakness.down)|spell_targets.crimson_tempest>=3&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(crimson_tempest)
	#eviscerate,if=(energy.time_to_max<=cooldown.death_from_above.remains+action.death_from_above.execute_time)|!talent.death_from_above.enabled
	if TimeToMaxEnergy() <= SpellCooldown(death_from_above) + ExecuteTime(death_from_above) or not Talent(death_from_above_talent) Spell(eviscerate)
}

AddFunction SubtletyFinisherShortCdPostConditions
{
	{ not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 } and Spell(rupture) or { BuffRemaining(slice_and_dice_buff) < 10.8 and target.DebuffExpires(find_weakness_debuff) or BuffRemaining(slice_and_dice_buff) < 6 } and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and Spell(slice_and_dice) or Spell(death_from_above) or { Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or { TimeToMaxEnergy() <= SpellCooldown(death_from_above) + ExecuteTime(death_from_above) or not Talent(death_from_above_talent) } and Spell(eviscerate)
}

AddFunction SubtletyFinisherCdActions
{
	unless { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 } and Spell(rupture) or { BuffRemaining(slice_and_dice_buff) < 10.8 and target.DebuffExpires(find_weakness_debuff) or BuffRemaining(slice_and_dice_buff) < 6 } and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and Spell(slice_and_dice) or Spell(death_from_above) or { Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or { TimeToMaxEnergy() <= SpellCooldown(death_from_above) + ExecuteTime(death_from_above) or not Talent(death_from_above_talent) } and Spell(eviscerate)
	{
		#call_action_list,name=pool
		SubtletyPoolCdActions()
	}
}

AddFunction SubtletyFinisherCdPostConditions
{
	{ not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 } and Spell(rupture) or { BuffRemaining(slice_and_dice_buff) < 10.8 and target.DebuffExpires(find_weakness_debuff) or BuffRemaining(slice_and_dice_buff) < 6 } and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and Spell(slice_and_dice) or Spell(death_from_above) or { Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or { TimeToMaxEnergy() <= SpellCooldown(death_from_above) + ExecuteTime(death_from_above) or not Talent(death_from_above_talent) } and Spell(eviscerate)
}

### actions.generator

AddFunction SubtletyGeneratorMainActions
{
	#pool_resource,for_next=1
	#ambush
	Spell(ambush)
	unless SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
	{
		#fan_of_knives,if=spell_targets.fan_of_knives>1
		if Enemies() > 1 Spell(fan_of_knives)
		#backstab,if=debuff.find_weakness.up|buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up
		if target.DebuffPresent(find_weakness_debuff) or BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) Spell(backstab)
		#shuriken_toss,if=energy<65&energy.regen<16
		if Energy() < 65 and EnergyRegenRate() < 16 Spell(shuriken_toss)
		#backstab,if=energy.time_to_max<=gcd*2
		if TimeToMaxEnergy() <= GCD() * 2 Spell(backstab)
	}
}

AddFunction SubtletyGeneratorShortCdActions
{
	#pool_resource,for_next=1
	#ambush
	unless SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
	{
		#auto_attack
		SubtletyGetInMeleeRange()
	}
}

AddFunction SubtletyGeneratorCdActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&(energy+set_bonus.tier17_2pc*50+cooldown.shadow_dance.remains*energy.regen<=energy.max|energy+15+cooldown.vanish.remains*energy.regen<=energy.max)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and { Energy() + ArmorSetBonus(T17 2) * 50 + SpellCooldown(shadow_dance) * EnergyRegenRate() <= MaxEnergy() or Energy() + 15 + SpellCooldown(vanish) * EnergyRegenRate() <= MaxEnergy() } SubtletyPoolCdActions()
	#pool_resource,for_next=1
	#ambush
	unless SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
	{
		unless Enemies() > 1 and Spell(fan_of_knives) or { target.DebuffPresent(find_weakness_debuff) or BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) } and Spell(backstab) or Energy() < 65 and EnergyRegenRate() < 16 and Spell(shuriken_toss) or TimeToMaxEnergy() <= GCD() * 2 and Spell(backstab)
		{
			#run_action_list,name=pool
			SubtletyPoolCdActions()
		}
	}
}

AddFunction SubtletyGeneratorCdPostConditions
{
	not { SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush) } and { Enemies() > 1 and Spell(fan_of_knives) or { target.DebuffPresent(find_weakness_debuff) or BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) } and Spell(backstab) or Energy() < 65 and EnergyRegenRate() < 16 and Spell(shuriken_toss) or TimeToMaxEnergy() <= GCD() * 2 and Spell(backstab) }
}

### actions.pool

AddFunction SubtletyPoolCdActions
{
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
}

### actions.precombat

AddFunction SubtletyPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=salty_squid_roll
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#stealth
	Spell(stealth)
	#premeditation,if=!talent.marked_for_death.enabled
	if not Talent(marked_for_death_talent) and ComboPoints() < 5 Spell(premeditation)
	#slice_and_dice,if=buff.slice_and_dice.remains<18
	if BuffRemaining(slice_and_dice_buff) < 18 Spell(slice_and_dice)
	#premeditation
	if ComboPoints() < 5 Spell(premeditation)
}

AddFunction SubtletyPrecombatShortCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth)
	{
		#marked_for_death
		Spell(marked_for_death)
	}
}

AddFunction SubtletyPrecombatShortCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or BuffRemaining(slice_and_dice_buff) < 18 and Spell(slice_and_dice)
}

AddFunction SubtletyPrecombatCdActions
{
	unless BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison)
	{
		#snapshot_stats
		#potion,name=draenic_agility
		SubtletyUsePotionAgility()
	}
}

AddFunction SubtletyPrecombatCdPostConditions
{
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or BuffRemaining(slice_and_dice_buff) < 18 and Spell(slice_and_dice)
}

### Subtlety icons.

AddCheckBox(opt_rogue_subtlety_aoe L(AOE) default specialization=subtlety)

AddIcon checkbox=!opt_rogue_subtlety_aoe enemies=1 help=shortcd specialization=subtlety
{
	if not InCombat() SubtletyPrecombatShortCdActions()
	unless not InCombat() and SubtletyPrecombatShortCdPostConditions()
	{
		SubtletyDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=shortcd specialization=subtlety
{
	if not InCombat() SubtletyPrecombatShortCdActions()
	unless not InCombat() and SubtletyPrecombatShortCdPostConditions()
	{
		SubtletyDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=subtlety
{
	if not InCombat() SubtletyPrecombatMainActions()
	SubtletyDefaultMainActions()
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=aoe specialization=subtlety
{
	if not InCombat() SubtletyPrecombatMainActions()
	SubtletyDefaultMainActions()
}

AddIcon checkbox=!opt_rogue_subtlety_aoe enemies=1 help=cd specialization=subtlety
{
	if not InCombat() SubtletyPrecombatCdActions()
	unless not InCombat() and SubtletyPrecombatCdPostConditions()
	{
		SubtletyDefaultCdActions()
	}
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=cd specialization=subtlety
{
	if not InCombat() SubtletyPrecombatCdActions()
	unless not InCombat() and SubtletyPrecombatCdPostConditions()
	{
		SubtletyDefaultCdActions()
	}
}

### Required symbols
# ambush
# anticipation_buff
# anticipation_talent
# arcane_torrent_energy
# archmages_greater_incandescence_agi_buff
# backstab
# berserking
# blood_fury_ap
# cheap_shot
# crimson_tempest
# deadly_poison
# deadly_throw
# death_from_above
# death_from_above_talent
# draenic_agility_potion
# eviscerate
# fan_of_knives
# find_weakness_debuff
# garrote_debuff
# hemorrhage_debuff
# honor_among_thieves_cooldown_buff
# kick
# kidney_shot
# lethal_poison_buff
# marked_for_death
# marked_for_death_talent
# master_of_subtlety_buff
# premeditation
# preparation
# quaking_palm
# rupture
# rupture_debuff
# shadow_dance
# shadow_dance_buff
# shadow_focus_talent
# shadow_reflection
# shadow_reflection_buff
# shadow_reflection_talent
# shadowmeld
# shadowstep
# shuriken_toss
# slice_and_dice
# slice_and_dice_buff
# stealth
# subterfuge_buff
# subterfuge_talent
# vanish
# vanish_buff
]]
	OvaleScripts:RegisterScript("ROGUE", "subtlety", name, desc, code, "script")
end
