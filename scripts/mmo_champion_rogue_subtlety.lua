local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "mmo_champion_rogue_subtlety_t17m"
	local desc = "[6.0] MMO-Champion: Rogue_Subtlety_T17M"
	local code = [[
# Based on SimulationCraft profile "Rogue_Subtlety_T17M".
#	class=rogue
#	spec=subtlety
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#cb!1000011
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
	#slice_and_dice,if=(buff.slice_and_dice.remains<10.8)&buff.slice_and_dice.remains<target.time_to_die&combo_points>=((target.time_to_die-buff.slice_and_dice.remains)%6)+1
	if BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and ComboPoints() >= { target.TimeToDie() - BuffRemaining(slice_and_dice_buff) } / 6 + 1 Spell(slice_and_dice)
	#premeditation,if=combo_points<=4&!(buff.shadow_dance.up&energy>100&combo_points>1)&!buff.subterfuge.up|(buff.subterfuge.up&debuff.find_weakness.up)
	if { ComboPoints() <= 4 and not { BuffPresent(shadow_dance_buff) and Energy() > 100 and ComboPoints() > 1 } and not BuffPresent(subterfuge_buff) or BuffPresent(subterfuge_buff) and target.DebuffPresent(find_weakness_debuff) } and ComboPoints() < 5 Spell(premeditation)
	#pool_resource,for_next=1
	#garrote,if=!ticking&time<1
	if not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 Spell(garrote)
	unless not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
	{
		#wait,sec=cooldown.honor_among_thieves.remains,if=combo_points=4&time<3&!cooldown.honor_among_thieves.up
		unless ComboPoints() == 4 and TimeInCombat() < 3 and not BuffExpires(honor_among_thieves_cooldown_buff) and BuffRemaining(honor_among_thieves_cooldown_buff) > 0
		{
			#wait,sec=0.01,if=combo_points=4&time<3
			unless ComboPoints() == 4 and TimeInCombat() < 3 and 0.01 > 0
			{
				#wait,sec=buff.subterfuge.remains-0.002,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
				unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.002 > 0
				{
					#pool_resource,for_next=1
					#ambush,if=(combo_points<5|(talent.anticipation.enabled&anticipation_charges<3))&(buff.shadow_dance.up|time>5)&(active_enemies<4|debuff.find_weakness.down)
					if { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } and { BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } and { Enemies() < 4 or target.DebuffExpires(find_weakness_debuff) } Spell(ambush)
					unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } and { BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } and { Enemies() < 4 or target.DebuffExpires(find_weakness_debuff) } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
					{
						#pool_resource,for_next=1,extra_amount=50
						#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))&set_bonus.tier17_2pc
						unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } and ArmorSetBonus(T17 2) } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
						{
							#pool_resource,for_next=1,extra_amount=100
							#shadow_dance,if=energy>=100&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))&!set_bonus.tier17_2pc
							unless { True(pool_energy 100) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } and not ArmorSetBonus(T17 2) } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(100)
							{
								#pool_resource,for_next=1,extra_amount=50
								#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
								unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
								{
									#wait,sec=0.1,if=cooldown.vanish.remains<4&combo_points<5&energy.deficit>10&!cooldown.vanish.up&debuff.find_weakness.remains<cooldown.vanish.remains&cooldown.shadow_dance.remains>cooldown.vanish.remains+10
									unless SpellCooldown(vanish) < 4 and ComboPoints() < 5 and EnergyDeficit() > 10 and not { not SpellCooldown(vanish) > 0 } and target.DebuffRemaining(find_weakness_debuff) < SpellCooldown(vanish) and SpellCooldown(shadow_dance) > SpellCooldown(vanish) + 10 and 0.1 > 0
									{
										#pool_resource,for_next=1,extra_amount=90
										#vanish,if=talent.subterfuge.enabled&energy>=90&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down&cooldown.shadow_dance.remains>15|(buff.shadow_dance.down&target.time_to_die<15)
										unless { Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellCooldown(shadow_dance) > 15 or BuffExpires(shadow_dance_buff) and target.TimeToDie() < 15 } and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
										{
											#pool_resource,if=active_enemies=1,for_next=1,extra_amount=110
											unless Enemies() == 1
											{
												#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
												if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorMainActions()
												#run_action_list,name=finisher,if=combo_points=5
												if ComboPoints() == 5 SubtletyFinisherMainActions()
												#run_action_list,name=generator,if=combo_points<4|(combo_points=4&cooldown.honor_among_thieves.remains>1&energy>70-energy.regen)|talent.anticipation.enabled
												if ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) SubtletyGeneratorMainActions()
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
}

AddFunction SubtletyDefaultShortCdActions
{
	unless BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and ComboPoints() >= { target.TimeToDie() - BuffRemaining(slice_and_dice_buff) } / 6 + 1 and Spell(slice_and_dice)
	{
		#pool_resource,for_next=1
		#garrote,if=!ticking&time<1
		unless not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
		{
			#wait,sec=cooldown.honor_among_thieves.remains,if=combo_points=4&time<3&!cooldown.honor_among_thieves.up
			unless ComboPoints() == 4 and TimeInCombat() < 3 and not BuffExpires(honor_among_thieves_cooldown_buff) and BuffRemaining(honor_among_thieves_cooldown_buff) > 0
			{
				#wait,sec=0.01,if=combo_points=4&time<3
				unless ComboPoints() == 4 and TimeInCombat() < 3 and 0.01 > 0
				{
					#wait,sec=buff.subterfuge.remains-0.002,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
					unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.002 > 0
					{
						#pool_resource,for_next=1
						#ambush,if=(combo_points<5|(talent.anticipation.enabled&anticipation_charges<3))&(buff.shadow_dance.up|time>5)&(active_enemies<4|debuff.find_weakness.down)
						unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } and { BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } and { Enemies() < 4 or target.DebuffExpires(find_weakness_debuff) } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
						{
							#auto_attack
							SubtletyGetInMeleeRange()
							#pool_resource,for_next=1,extra_amount=50
							#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))&set_bonus.tier17_2pc
							if Energy() >= 50 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } and ArmorSetBonus(T17 2) Spell(shadow_dance)
							unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } and ArmorSetBonus(T17 2) } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
							{
								#pool_resource,for_next=1,extra_amount=100
								#shadow_dance,if=energy>=100&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))&!set_bonus.tier17_2pc
								if Energy() >= 100 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } and not ArmorSetBonus(T17 2) Spell(shadow_dance)
								unless { True(pool_energy 100) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } and not ArmorSetBonus(T17 2) } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(100)
								{
									#pool_resource,for_next=1,extra_amount=50
									#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
									if Talent(shadow_focus_talent) and Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
									unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
									{
										#wait,sec=0.1,if=cooldown.vanish.remains<4&combo_points<5&energy.deficit>10&!cooldown.vanish.up&debuff.find_weakness.remains<cooldown.vanish.remains&cooldown.shadow_dance.remains>cooldown.vanish.remains+10
										unless SpellCooldown(vanish) < 4 and ComboPoints() < 5 and EnergyDeficit() > 10 and not { not SpellCooldown(vanish) > 0 } and target.DebuffRemaining(find_weakness_debuff) < SpellCooldown(vanish) and SpellCooldown(shadow_dance) > SpellCooldown(vanish) + 10 and 0.1 > 0
										{
											#pool_resource,for_next=1,extra_amount=90
											#vanish,if=talent.subterfuge.enabled&energy>=90&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down&cooldown.shadow_dance.remains>15|(buff.shadow_dance.down&target.time_to_die<15)
											if Talent(subterfuge_talent) and Energy() >= 90 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellCooldown(shadow_dance) > 15 or BuffExpires(shadow_dance_buff) and target.TimeToDie() < 15 Spell(vanish)
											unless { Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellCooldown(shadow_dance) > 15 or BuffExpires(shadow_dance_buff) and target.TimeToDie() < 15 } and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
											{
												#pool_resource,if=active_enemies=1,for_next=1,extra_amount=110
												unless Enemies() == 1
												{
													#marked_for_death,if=combo_points=0
													if ComboPoints() == 0 Spell(marked_for_death)
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
	}
}

AddFunction SubtletyDefaultCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|buff.shadow_reflection.remains>12&(trinket.stat.agi.react|trinket.stat.multistrike.react|buff.archmages_greater_incandescence_agi.react)
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or BuffRemaining(shadow_reflection_buff) > 12 and { BuffPresent(trinket_stat_agi_buff) or BuffPresent(trinket_stat_multistrike_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } SubtletyUsePotionAgility()
	#kick
	SubtletyInterruptActions()
	#use_item,slot=trinket2,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) SubtletyUseItemActions()
	#shadow_reflection,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(shadow_reflection)
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury_ap)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<60&buff.shadow_dance.up
	if Energy() < 60 and BuffPresent(shadow_dance_buff) Spell(arcane_torrent_energy)

	unless BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and ComboPoints() >= { target.TimeToDie() - BuffRemaining(slice_and_dice_buff) } / 6 + 1 and Spell(slice_and_dice)
	{
		#pool_resource,for_next=1
		#garrote,if=!ticking&time<1
		unless not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
		{
			#wait,sec=cooldown.honor_among_thieves.remains,if=combo_points=4&time<3&!cooldown.honor_among_thieves.up
			unless ComboPoints() == 4 and TimeInCombat() < 3 and not BuffExpires(honor_among_thieves_cooldown_buff) and BuffRemaining(honor_among_thieves_cooldown_buff) > 0
			{
				#wait,sec=0.01,if=combo_points=4&time<3
				unless ComboPoints() == 4 and TimeInCombat() < 3 and 0.01 > 0
				{
					#wait,sec=buff.subterfuge.remains-0.002,if=buff.subterfuge.remains>0.5&buff.subterfuge.remains<1.6&time>6
					unless BuffRemaining(subterfuge_buff) > 0.5 and BuffRemaining(subterfuge_buff) < 1.6 and TimeInCombat() > 6 and BuffRemaining(subterfuge_buff) - 0.002 > 0
					{
						#pool_resource,for_next=1
						#ambush,if=(combo_points<5|(talent.anticipation.enabled&anticipation_charges<3))&(buff.shadow_dance.up|time>5)&(active_enemies<4|debuff.find_weakness.down)
						unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } and { BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } and { Enemies() < 4 or target.DebuffExpires(find_weakness_debuff) } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
						{
							#pool_resource,for_next=1,extra_amount=50
							#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))&set_bonus.tier17_2pc
							unless { True(pool_energy 50) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } and ArmorSetBonus(T17 2) } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
							{
								#pool_resource,for_next=1,extra_amount=100
								#shadow_dance,if=energy>=100&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))&!set_bonus.tier17_2pc
								unless { True(pool_energy 100) and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff any=1) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } and not ArmorSetBonus(T17 2) } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(100)
								{
									#pool_resource,for_next=1,extra_amount=50
									#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
									unless Talent(shadow_focus_talent) and True(pool_energy 50) and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
									{
										#wait,sec=0.1,if=cooldown.vanish.remains<4&combo_points<5&energy.deficit>10&!cooldown.vanish.up&debuff.find_weakness.remains<cooldown.vanish.remains&cooldown.shadow_dance.remains>cooldown.vanish.remains+10
										unless SpellCooldown(vanish) < 4 and ComboPoints() < 5 and EnergyDeficit() > 10 and not { not SpellCooldown(vanish) > 0 } and target.DebuffRemaining(find_weakness_debuff) < SpellCooldown(vanish) and SpellCooldown(shadow_dance) > SpellCooldown(vanish) + 10 and 0.1 > 0
										{
											#pool_resource,for_next=1,extra_amount=90
											#vanish,if=talent.subterfuge.enabled&energy>=90&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down&cooldown.shadow_dance.remains>15|(buff.shadow_dance.down&target.time_to_die<15)
											unless { Talent(subterfuge_talent) and True(pool_energy 90) and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellCooldown(shadow_dance) > 15 or BuffExpires(shadow_dance_buff) and target.TimeToDie() < 15 } and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
											{
												#pool_resource,if=active_enemies=1,for_next=1,extra_amount=110
												unless Enemies() == 1
												{
													#shadowmeld,if=energy>=90&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down&cooldown.shadow_dance.remains>13&active_enemies=1
													if Energy() >= 90 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellCooldown(shadow_dance) > 13 and Enemies() == 1 Spell(shadowmeld)
													#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
													if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorCdActions()

													unless Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } and SubtletyGeneratorCdPostConditions()
													{
														#run_action_list,name=finisher,if=combo_points=5
														if ComboPoints() == 5 SubtletyFinisherCdActions()

														unless ComboPoints() == 5 and SubtletyFinisherCdPostConditions()
														{
															#run_action_list,name=generator,if=combo_points<4|(combo_points=4&cooldown.honor_among_thieves.remains>1&energy>70-energy.regen)|talent.anticipation.enabled
															if ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) SubtletyGeneratorCdActions()

															unless { ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) } and SubtletyGeneratorCdPostConditions()
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
				}
			}
		}
	}
}

### actions.finisher

AddFunction SubtletyFinisherMainActions
{
	#rupture,cycle_targets=1,if=!ticking|remains<duration*0.3|(buff.shadow_reflection.remains>8&dot.rupture.remains<12)&target.time_to_die>=8
	if not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 and target.TimeToDie() >= 8 Spell(rupture)
	#slice_and_dice,if=(buff.slice_and_dice.remains<10.8)&buff.slice_and_dice.remains<target.time_to_die
	if BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() Spell(slice_and_dice)
	#pool_resource,for_next=1
	#death_from_above
	Spell(death_from_above)
	unless SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergyFor(death_from_above)
	{
		#crimson_tempest,if=(active_enemies>=2&debuff.find_weakness.down)|active_enemies>=3&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
		if Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(crimson_tempest)
		#eviscerate
		Spell(eviscerate)
	}
}

AddFunction SubtletyFinisherCdActions
{
	unless { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 and target.TimeToDie() >= 8 } and Spell(rupture) or BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and Spell(slice_and_dice)
	{
		#pool_resource,for_next=1
		#death_from_above
		unless SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergyFor(death_from_above)
		{
			unless { Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or Spell(eviscerate)
			{
				#run_action_list,name=pool
				SubtletyPoolCdActions()
			}
		}
	}
}

AddFunction SubtletyFinisherCdPostConditions
{
	{ not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 and target.TimeToDie() >= 8 } and Spell(rupture) or BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and Spell(slice_and_dice) or not { SpellUsable(death_from_above) and SpellCooldown(death_from_above) < TimeToEnergyFor(death_from_above) } and { { Enemies() >= 2 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or Spell(eviscerate) }
}

### actions.generator

AddFunction SubtletyGeneratorMainActions
{
	#fan_of_knives,if=active_enemies>1
	if Enemies() > 1 Spell(fan_of_knives)
	#hemorrhage,if=(remains<duration*0.3&target.time_to_die>=remains+duration&debuff.find_weakness.down)|!ticking|position_front
	if target.DebuffRemaining(hemorrhage_debuff) < BaseDuration(hemorrhage_debuff) * 0.3 and target.TimeToDie() >= target.DebuffRemaining(hemorrhage_debuff) + BaseDuration(hemorrhage_debuff) and target.DebuffExpires(find_weakness_debuff) or not target.DebuffPresent(hemorrhage_debuff) or False(position_front) Spell(hemorrhage)
	#shuriken_toss,if=energy<65&energy.regen<16
	if Energy() < 65 and EnergyRegenRate() < 16 Spell(shuriken_toss)
	#backstab
	Spell(backstab)
}

AddFunction SubtletyGeneratorCdActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+set_bonus.tier17_2pc*50+cooldown.shadow_dance.remains*energy.regen<=energy.max|energy+15+cooldown.vanish.remains*energy.regen<=energy.max)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + ArmorSetBonus(T17 2) * 50 + SpellCooldown(shadow_dance) * EnergyRegenRate() <= MaxEnergy() or Energy() + 15 + SpellCooldown(vanish) * EnergyRegenRate() <= MaxEnergy() } SubtletyPoolCdActions()

	unless Enemies() > 1 and Spell(fan_of_knives) or { target.DebuffRemaining(hemorrhage_debuff) < BaseDuration(hemorrhage_debuff) * 0.3 and target.TimeToDie() >= target.DebuffRemaining(hemorrhage_debuff) + BaseDuration(hemorrhage_debuff) and target.DebuffExpires(find_weakness_debuff) or not target.DebuffPresent(hemorrhage_debuff) or False(position_front) } and Spell(hemorrhage) or Energy() < 65 and EnergyRegenRate() < 16 and Spell(shuriken_toss) or Spell(backstab)
	{
		#run_action_list,name=pool
		SubtletyPoolCdActions()
	}
}

AddFunction SubtletyGeneratorCdPostConditions
{
	Enemies() > 1 and Spell(fan_of_knives) or { target.DebuffRemaining(hemorrhage_debuff) < BaseDuration(hemorrhage_debuff) * 0.3 and target.TimeToDie() >= target.DebuffRemaining(hemorrhage_debuff) + BaseDuration(hemorrhage_debuff) and target.DebuffExpires(find_weakness_debuff) or not target.DebuffPresent(hemorrhage_debuff) or False(position_front) } and Spell(hemorrhage) or Energy() < 65 and EnergyRegenRate() < 16 and Spell(shuriken_toss) or Spell(backstab)
}

### actions.pool

AddFunction SubtletyPoolCdActions
{
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff any=1) and SpellCooldown(vanish) > 60 Spell(preparation)
}

### actions.precombat

AddFunction SubtletyPrecombatMainActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=calamari_crepes
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#stealth
	Spell(stealth)
	#premeditation
	if ComboPoints() < 5 Spell(premeditation)
	#slice_and_dice,if=buff.slice_and_dice.remains<18
	if BuffRemaining(slice_and_dice_buff) < 18 Spell(slice_and_dice)
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
	unless not InCombat() and SubtletyPrecombatShortCdPostConditions()
	{
		SubtletyDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_rogue_subtlety_aoe help=shortcd specialization=subtlety
{
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
# garrote
# garrote_debuff
# hemorrhage
# hemorrhage_debuff
# honor_among_thieves_cooldown_buff
# kick
# kidney_shot
# marked_for_death
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
# shadowmeld
# shadowstep
# shuriken_toss
# slice_and_dice
# slice_and_dice_buff
# stealth
# subterfuge_buff
# subterfuge_talent
# vanish
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "script")
end
