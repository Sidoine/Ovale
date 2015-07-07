local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "mmo_champion_rogue_subtlety_17"
	local desc = "[6.2] MMO-Champion: Rogue_Subtlety_1.7"
	local code = [[
# Based on SimulationCraft profile "Rogue_Subtlety_1.7".
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

### actions.default

AddFunction SubtletyDefaultMainActions
{
	#run_action_list,name=opener_ant,if=time<2&!buff.shadow_dance.up&talent.anticipation.enabled
	if TimeInCombat() < 2 and not BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) SubtletyOpenerAntMainActions()
	#run_action_list,name=opener_mfd,if=time<3.1&talent.marked_for_death.enabled
	if TimeInCombat() < 3.1 and Talent(marked_for_death_talent) SubtletyOpenerMfdMainActions()
	#run_action_list,name=dance_rotation_ant_ref,if=buff.shadow_dance.up&talent.anticipation.enabled&talent.shadow_reflection.enabled
	if BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) SubtletyDanceRotationAntRefMainActions()
	#run_action_list,name=dance_rotation_mfd_ref,if=buff.shadow_dance.up&talent.marked_for_death.enabled&talent.shadow_reflection.enabled
	if BuffPresent(shadow_dance_buff) and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) SubtletyDanceRotationMfdRefMainActions()
	#run_action_list,name=vanish_rotation_ant_ref,if=(buff.vanish.up|buff.subterfuge.up)&talent.anticipation.enabled&talent.shadow_reflection.enabled
	if { BuffPresent(vanish_buff) or BuffPresent(subterfuge_buff) } and Talent(anticipation_talent) and Talent(shadow_reflection_talent) SubtletyVanishRotationAntRefMainActions()
	#run_action_list,name=vanish_rotation_mfd_ref,if=(buff.vanish.up|buff.subterfuge.up)&talent.marked_for_death.enabled&talent.shadow_reflection.enabled
	if { BuffPresent(vanish_buff) or BuffPresent(subterfuge_buff) } and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) SubtletyVanishRotationMfdRefMainActions()
	#run_action_list,name=shadowmeld_rotation,if=buff.shadowmeld.up
	if BuffPresent(shadowmeld_buff) SubtletyShadowmeldRotationMainActions()
	#call_action_list,name=cd_controller_ant,if=talent.anticipation.enabled
	if Talent(anticipation_talent) SubtletyCdControllerAntMainActions()
	#call_action_list,name=cd_controller_mfd,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) SubtletyCdControllerMfdMainActions()
	#run_action_list,name=generators_fw_ant,if=(debuff.find_weakness.up|trinket.proc.any.react|trinket.stacking_proc.any.react|buff.archmages_greater_incandescence_agi.react)&talent.anticipation.enabled
	if { target.DebuffPresent(find_weakness_debuff) or BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } and Talent(anticipation_talent) SubtletyGeneratorsFwAntMainActions()
	#run_action_list,name=generators_fw_mfd,if=(debuff.find_weakness.up|trinket.proc.any.react|trinket.stacking_proc.any.react|buff.archmages_greater_incandescence_agi.react)&talent.marked_for_death.enabled
	if { target.DebuffPresent(find_weakness_debuff) or BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } and Talent(marked_for_death_talent) SubtletyGeneratorsFwMfdMainActions()
	#run_action_list,name=generators_ant,if=talent.anticipation.enabled
	if Talent(anticipation_talent) SubtletyGeneratorsAntMainActions()
	#run_action_list,name=generators_mfd,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) SubtletyGeneratorsMfdMainActions()
}

AddFunction SubtletyDefaultShortCdActions
{
	#run_action_list,name=opener_ant,if=time<2&!buff.shadow_dance.up&talent.anticipation.enabled
	if TimeInCombat() < 2 and not BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) SubtletyOpenerAntShortCdActions()

	unless TimeInCombat() < 2 and not BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) and SubtletyOpenerAntShortCdPostConditions()
	{
		unless TimeInCombat() < 3.1 and Talent(marked_for_death_talent) and SubtletyOpenerMfdShortCdPostConditions()
		{
			#run_action_list,name=dance_rotation_ant_ref,if=buff.shadow_dance.up&talent.anticipation.enabled&talent.shadow_reflection.enabled
			if BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) SubtletyDanceRotationAntRefShortCdActions()

			unless BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) and SubtletyDanceRotationAntRefShortCdPostConditions()
			{
				#run_action_list,name=dance_rotation_mfd_ref,if=buff.shadow_dance.up&talent.marked_for_death.enabled&talent.shadow_reflection.enabled
				if BuffPresent(shadow_dance_buff) and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) SubtletyDanceRotationMfdRefShortCdActions()

				unless BuffPresent(shadow_dance_buff) and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) and SubtletyDanceRotationMfdRefShortCdPostConditions()
				{
					unless { BuffPresent(vanish_buff) or BuffPresent(subterfuge_buff) } and Talent(anticipation_talent) and Talent(shadow_reflection_talent) and SubtletyVanishRotationAntRefShortCdPostConditions()
					{
						unless { BuffPresent(vanish_buff) or BuffPresent(subterfuge_buff) } and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) and SubtletyVanishRotationMfdRefShortCdPostConditions()
						{
							unless BuffPresent(shadowmeld_buff) and SubtletyShadowmeldRotationShortCdPostConditions()
							{
								#call_action_list,name=cd_controller_ant,if=talent.anticipation.enabled
								if Talent(anticipation_talent) SubtletyCdControllerAntShortCdActions()

								unless Talent(anticipation_talent) and SubtletyCdControllerAntShortCdPostConditions()
								{
									#call_action_list,name=cd_controller_mfd,if=talent.marked_for_death.enabled
									if Talent(marked_for_death_talent) SubtletyCdControllerMfdShortCdActions()

									unless Talent(marked_for_death_talent) and SubtletyCdControllerMfdShortCdPostConditions()
									{
										unless { target.DebuffPresent(find_weakness_debuff) or BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } and Talent(anticipation_talent) and SubtletyGeneratorsFwAntShortCdPostConditions()
										{
											#run_action_list,name=generators_fw_mfd,if=(debuff.find_weakness.up|trinket.proc.any.react|trinket.stacking_proc.any.react|buff.archmages_greater_incandescence_agi.react)&talent.marked_for_death.enabled
											if { target.DebuffPresent(find_weakness_debuff) or BuffPresent(trinket_proc_any_buff) or BuffPresent(trinket_stacking_proc_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } and Talent(marked_for_death_talent) SubtletyGeneratorsFwMfdShortCdActions()
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
	#run_action_list,name=opener_ant,if=time<2&!buff.shadow_dance.up&talent.anticipation.enabled
	if TimeInCombat() < 2 and not BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) SubtletyOpenerAntCdActions()

	unless TimeInCombat() < 2 and not BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) and SubtletyOpenerAntCdPostConditions()
	{
		unless TimeInCombat() < 3.1 and Talent(marked_for_death_talent) and SubtletyOpenerMfdCdPostConditions()
		{
			#run_action_list,name=dance_rotation_ant_ref,if=buff.shadow_dance.up&talent.anticipation.enabled&talent.shadow_reflection.enabled
			if BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) SubtletyDanceRotationAntRefCdActions()

			unless BuffPresent(shadow_dance_buff) and Talent(anticipation_talent) and Talent(shadow_reflection_talent) and SubtletyDanceRotationAntRefCdPostConditions()
			{
				#run_action_list,name=dance_rotation_mfd_ref,if=buff.shadow_dance.up&talent.marked_for_death.enabled&talent.shadow_reflection.enabled
				if BuffPresent(shadow_dance_buff) and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) SubtletyDanceRotationMfdRefCdActions()

				unless BuffPresent(shadow_dance_buff) and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) and SubtletyDanceRotationMfdRefCdPostConditions()
				{
					unless { BuffPresent(vanish_buff) or BuffPresent(subterfuge_buff) } and Talent(anticipation_talent) and Talent(shadow_reflection_talent) and SubtletyVanishRotationAntRefCdPostConditions()
					{
						#run_action_list,name=vanish_rotation_mfd_ref,if=(buff.vanish.up|buff.subterfuge.up)&talent.marked_for_death.enabled&talent.shadow_reflection.enabled
						if { BuffPresent(vanish_buff) or BuffPresent(subterfuge_buff) } and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) SubtletyVanishRotationMfdRefCdActions()

						unless { BuffPresent(vanish_buff) or BuffPresent(subterfuge_buff) } and Talent(marked_for_death_talent) and Talent(shadow_reflection_talent) and SubtletyVanishRotationMfdRefCdPostConditions()
						{
							unless BuffPresent(shadowmeld_buff) and SubtletyShadowmeldRotationCdPostConditions()
							{
								#call_action_list,name=cd_controller_ant,if=talent.anticipation.enabled
								if Talent(anticipation_talent) SubtletyCdControllerAntCdActions()

								unless Talent(anticipation_talent) and SubtletyCdControllerAntCdPostConditions()
								{
									#call_action_list,name=cd_controller_mfd,if=talent.marked_for_death.enabled
									if Talent(marked_for_death_talent) SubtletyCdControllerMfdCdActions()
								}
							}
						}
					}
				}
			}
		}
	}
}

### actions.cd_controller_ant

AddFunction SubtletyCdControllerAntMainActions
{
	#call_action_list,name=pool_ant,if=energy+energy.regen*cooldown.shadow_dance.remains<=120
	if Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 120 SubtletyPoolAntMainActions()
	#call_action_list,name=pool_ant,if=(energy<99&cooldown.vanish.up)&!debuff.find_weakness.up
	if Energy() < 99 and not SpellCooldown(vanish) > 0 and not target.DebuffPresent(find_weakness_debuff) SubtletyPoolAntMainActions()
	#call_action_list,name=pool_ant,if=(energy+energy.regen*cooldown.vanish.remains<=79&cooldown.shadow_dance.remains-15>cooldown.vanish.remains)&!debuff.find_weakness.up
	if Energy() + EnergyRegenRate() * SpellCooldown(vanish) <= 79 and SpellCooldown(shadow_dance) - 15 > SpellCooldown(vanish) and not target.DebuffPresent(find_weakness_debuff) SubtletyPoolAntMainActions()
}

AddFunction SubtletyCdControllerAntShortCdActions
{
	#shadow_dance
	Spell(shadow_dance)
	#vanish,if=combo_points+anticipation_charges<=5
	if ComboPoints() + BuffStacks(anticipation_buff) <= 5 Spell(vanish)
	#vanish,if=target.time_to_die<16
	if target.TimeToDie() < 16 Spell(vanish)
}

AddFunction SubtletyCdControllerAntShortCdPostConditions
{
	Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 120 and SubtletyPoolAntShortCdPostConditions() or Energy() < 99 and not SpellCooldown(vanish) > 0 and not target.DebuffPresent(find_weakness_debuff) and SubtletyPoolAntShortCdPostConditions() or Energy() + EnergyRegenRate() * SpellCooldown(vanish) <= 79 and SpellCooldown(shadow_dance) - 15 > SpellCooldown(vanish) and not target.DebuffPresent(find_weakness_debuff) and SubtletyPoolAntShortCdPostConditions()
}

AddFunction SubtletyCdControllerAntCdActions
{
	#shadowmeld,if=energy>60&debuff.find_weakness.down&cooldown.shadow_dance.remains>10&cooldown.vanish.remains>10&combo_points<=3
	if Energy() > 60 and target.DebuffExpires(find_weakness_debuff) and SpellCooldown(shadow_dance) > 10 and SpellCooldown(vanish) > 10 and ComboPoints() <= 3 Spell(shadowmeld)
	#preparation,if=cooldown.vanish.remains|target.time_to_die<17
	if SpellCooldown(vanish) > 0 or target.TimeToDie() < 17 Spell(preparation)
	#call_action_list,name=pool_ant,if=energy+energy.regen*cooldown.shadow_dance.remains<=120
	if Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 120 SubtletyPoolAntCdActions()

	unless Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 120 and SubtletyPoolAntCdPostConditions()
	{
		#call_action_list,name=pool_ant,if=(energy<99&cooldown.vanish.up)&!debuff.find_weakness.up
		if Energy() < 99 and not SpellCooldown(vanish) > 0 and not target.DebuffPresent(find_weakness_debuff) SubtletyPoolAntCdActions()

		unless Energy() < 99 and not SpellCooldown(vanish) > 0 and not target.DebuffPresent(find_weakness_debuff) and SubtletyPoolAntCdPostConditions()
		{
			#call_action_list,name=pool_ant,if=(energy+energy.regen*cooldown.vanish.remains<=79&cooldown.shadow_dance.remains-15>cooldown.vanish.remains)&!debuff.find_weakness.up
			if Energy() + EnergyRegenRate() * SpellCooldown(vanish) <= 79 and SpellCooldown(shadow_dance) - 15 > SpellCooldown(vanish) and not target.DebuffPresent(find_weakness_debuff) SubtletyPoolAntCdActions()
		}
	}
}

AddFunction SubtletyCdControllerAntCdPostConditions
{
	Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 120 and SubtletyPoolAntCdPostConditions() or Energy() < 99 and not SpellCooldown(vanish) > 0 and not target.DebuffPresent(find_weakness_debuff) and SubtletyPoolAntCdPostConditions() or Energy() + EnergyRegenRate() * SpellCooldown(vanish) <= 79 and SpellCooldown(shadow_dance) - 15 > SpellCooldown(vanish) and not target.DebuffPresent(find_weakness_debuff) and SubtletyPoolAntCdPostConditions()
}

### actions.cd_controller_mfd

AddFunction SubtletyCdControllerMfdMainActions
{
	#call_action_list,name=pool_mfd,if=energy+energy.regen*cooldown.shadow_dance.remains<=60
	if Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 60 SubtletyPoolMfdMainActions()
	#call_action_list,name=pool_mfd,if=(energy<99&cooldown.vanish.up)&debuff.find_weakness.remains<5
	if Energy() < 99 and not SpellCooldown(vanish) > 0 and target.DebuffRemaining(find_weakness_debuff) < 5 SubtletyPoolMfdMainActions()
	#call_action_list,name=pool_mfd,if=(energy+energy.regen*cooldown.vanish.remains<=79&cooldown.shadow_dance.remains-15>cooldown.vanish.remains)&debuff.find_weakness.remains<5
	if Energy() + EnergyRegenRate() * SpellCooldown(vanish) <= 79 and SpellCooldown(shadow_dance) - 15 > SpellCooldown(vanish) and target.DebuffRemaining(find_weakness_debuff) < 5 SubtletyPoolMfdMainActions()
}

AddFunction SubtletyCdControllerMfdShortCdActions
{
	#shadow_dance
	Spell(shadow_dance)
	#vanish,if=energy>99&debuff.find_weakness.down&cooldown.shadow_dance.remains>15&((combo_points=1&cooldown.honor_among_thieves.remains<1)|(combo_points=2))
	if Energy() > 99 and target.DebuffExpires(find_weakness_debuff) and SpellCooldown(shadow_dance) > 15 and { ComboPoints() == 1 and BuffRemaining(honor_among_thieves_cooldown_buff) < 1 or ComboPoints() == 2 } Spell(vanish)
	#vanish,if=target.time_to_die<16
	if target.TimeToDie() < 16 Spell(vanish)
}

AddFunction SubtletyCdControllerMfdShortCdPostConditions
{
	Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 60 and SubtletyPoolMfdShortCdPostConditions() or Energy() < 99 and not SpellCooldown(vanish) > 0 and target.DebuffRemaining(find_weakness_debuff) < 5 and SubtletyPoolMfdShortCdPostConditions() or Energy() + EnergyRegenRate() * SpellCooldown(vanish) <= 79 and SpellCooldown(shadow_dance) - 15 > SpellCooldown(vanish) and target.DebuffRemaining(find_weakness_debuff) < 5 and SubtletyPoolMfdShortCdPostConditions()
}

AddFunction SubtletyCdControllerMfdCdActions
{
	#shadowmeld,if=energy>60&debuff.find_weakness.down&cooldown.shadow_dance.remains>10&cooldown.vanish.remains>10&combo_points<=1
	if Energy() > 60 and target.DebuffExpires(find_weakness_debuff) and SpellCooldown(shadow_dance) > 10 and SpellCooldown(vanish) > 10 and ComboPoints() <= 1 Spell(shadowmeld)
	#preparation,if=cooldown.vanish.remains>60|target.time_to_die<17
	if SpellCooldown(vanish) > 60 or target.TimeToDie() < 17 Spell(preparation)
	#call_action_list,name=pool_mfd,if=energy+energy.regen*cooldown.shadow_dance.remains<=60
	if Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 60 SubtletyPoolMfdCdActions()

	unless Energy() + EnergyRegenRate() * SpellCooldown(shadow_dance) <= 60 and SubtletyPoolMfdCdPostConditions()
	{
		#call_action_list,name=pool_mfd,if=(energy<99&cooldown.vanish.up)&debuff.find_weakness.remains<5
		if Energy() < 99 and not SpellCooldown(vanish) > 0 and target.DebuffRemaining(find_weakness_debuff) < 5 SubtletyPoolMfdCdActions()

		unless Energy() < 99 and not SpellCooldown(vanish) > 0 and target.DebuffRemaining(find_weakness_debuff) < 5 and SubtletyPoolMfdCdPostConditions()
		{
			#call_action_list,name=pool_mfd,if=(energy+energy.regen*cooldown.vanish.remains<=79&cooldown.shadow_dance.remains-15>cooldown.vanish.remains)&debuff.find_weakness.remains<5
			if Energy() + EnergyRegenRate() * SpellCooldown(vanish) <= 79 and SpellCooldown(shadow_dance) - 15 > SpellCooldown(vanish) and target.DebuffRemaining(find_weakness_debuff) < 5 SubtletyPoolMfdCdActions()
		}
	}
}

### actions.dance_rotation_ant_ref

AddFunction SubtletyDanceRotationAntRefMainActions
{
	#premeditation,if=(combo_points=3&anticipation_charges=3&cooldown.honor_among_thieves.remains>1)|(combo_points<=3&anticipation_charges+combo_points<=5)
	if { ComboPoints() == 3 and BuffStacks(anticipation_buff) == 3 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 or ComboPoints() <= 3 and BuffStacks(anticipation_buff) + ComboPoints() <= 5 } and ComboPoints() < 5 Spell(premeditation)
	#ambush,if=buff.shadow_dance.remains<=0.1
	if BuffRemaining(shadow_dance_buff) <= 0.1 Spell(ambush)
	#wait,sec=buff.shadow_dance.remains-0.1,if=(buff.shadow_dance.remains<=1)|energy+energy.regen*buff.shadow_dance.remains<=49
	unless { BuffRemaining(shadow_dance_buff) <= 1 or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) <= 49 } and BuffRemaining(shadow_dance_buff) - 0.1 > 0
	{
		#call_action_list,name=energy_neutral_finishers,if=combo_points=5&buff.shadow_dance.remains>1&buff.shadow_dance.remains<=2
		if ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 SubtletyEnergyNeutralFinishersMainActions()
		#call_action_list,name=finishers,if=(combo_points=5&buff.shadow_dance.remains>1&buff.shadow_dance.remains<=2)&((energy+(energy.regen*buff.shadow_dance.remains))>=50)
		if ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 50 SubtletyFinishersMainActions()
		#ambush,if=debuff.find_weakness.down
		if target.DebuffExpires(find_weakness_debuff) Spell(ambush)
		#fan_of_knives,if=(((combo_points+anticipation_charges)<(10-active_enemies))|(((combo_points+anticipation_charges)=(10-active_enemies))&cooldown.Honor_among_Thieves.remains>1))&(buff.shadow_dance.remains>2)&(dot.rupture.remains<12&dot.rupture.remains>8)&((energy+(energy.regen*buff.shadow_dance.remains))>=72)&active_enemies>=4
		if { ComboPoints() + BuffStacks(anticipation_buff) < 10 - Enemies() or ComboPoints() + BuffStacks(anticipation_buff) == 10 - Enemies() and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 } and BuffRemaining(shadow_dance_buff) > 2 and target.DebuffRemaining(rupture_debuff) < 12 and target.DebuffRemaining(rupture_debuff) > 8 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() >= 4 Spell(fan_of_knives)
		#ambush,if=(((combo_points+anticipation_charges)<8)|(((combo_points+anticipation_charges)=8)&cooldown.Honor_among_Thieves.remains>1))&(buff.shadow_dance.remains>2)&(dot.rupture.remains<12&dot.rupture.remains>8)&((energy+(energy.regen*buff.shadow_dance.remains))>=72)&active_enemies=1
		if { ComboPoints() + BuffStacks(anticipation_buff) < 8 or ComboPoints() + BuffStacks(anticipation_buff) == 8 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 } and BuffRemaining(shadow_dance_buff) > 2 and target.DebuffRemaining(rupture_debuff) < 12 and target.DebuffRemaining(rupture_debuff) > 8 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() == 1 Spell(ambush)
		#call_action_list,name=finishers,if=combo_points=5
		if ComboPoints() == 5 SubtletyFinishersMainActions()
		#fan_of_knives,if=((energy+(energy.regen*buff.shadow_dance.remains))>=72)&active_enemies>=5
		if Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() >= 5 Spell(fan_of_knives)
		#ambush,if=((energy+(energy.regen*buff.shadow_dance.remains))>=72)
		if Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 Spell(ambush)
	}
}

AddFunction SubtletyDanceRotationAntRefShortCdActions
{
	#vanish
	Spell(vanish)
}

AddFunction SubtletyDanceRotationAntRefShortCdPostConditions
{
	BuffRemaining(shadow_dance_buff) <= 0.1 and Spell(ambush) or not { { BuffRemaining(shadow_dance_buff) <= 1 or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) <= 49 } and BuffRemaining(shadow_dance_buff) - 0.1 > 0 } and { ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and SubtletyEnergyNeutralFinishersShortCdPostConditions() or ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 50 and SubtletyFinishersShortCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush) or { ComboPoints() + BuffStacks(anticipation_buff) < 10 - Enemies() or ComboPoints() + BuffStacks(anticipation_buff) == 10 - Enemies() and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 } and BuffRemaining(shadow_dance_buff) > 2 and target.DebuffRemaining(rupture_debuff) < 12 and target.DebuffRemaining(rupture_debuff) > 8 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() >= 4 and Spell(fan_of_knives) or { ComboPoints() + BuffStacks(anticipation_buff) < 8 or ComboPoints() + BuffStacks(anticipation_buff) == 8 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 } and BuffRemaining(shadow_dance_buff) > 2 and target.DebuffRemaining(rupture_debuff) < 12 and target.DebuffRemaining(rupture_debuff) > 8 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() == 1 and Spell(ambush) or ComboPoints() == 5 and SubtletyFinishersShortCdPostConditions() or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() >= 5 and Spell(fan_of_knives) or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Spell(ambush) }
}

AddFunction SubtletyDanceRotationAntRefCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|(buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.shadow_dance.up))&(trinket.stat.agi.up|trinket.stat.multistrike.up|buff.archmages_greater_incandescence_agi.up)|((buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.shadow_dance.up))&target.time_to_die<136)
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(shadow_dance_buff) } and { BuffPresent(trinket_stat_agi_buff) or BuffPresent(trinket_stat_multistrike_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(shadow_dance_buff) } and target.TimeToDie() < 136 SubtletyUsePotionAgility()
	#shadow_reflection
	Spell(shadow_reflection)
	#use_item,slot=trinket2
	SubtletyUseItemActions()
	#use_item,slot=finger1
	SubtletyUseItemActions()
	#Arcane_Torrent,if=energy<90
	if Energy() < 90 Spell(arcane_torrent_energy)
}

AddFunction SubtletyDanceRotationAntRefCdPostConditions
{
	BuffRemaining(shadow_dance_buff) <= 0.1 and Spell(ambush) or not { { BuffRemaining(shadow_dance_buff) <= 1 or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) <= 49 } and BuffRemaining(shadow_dance_buff) - 0.1 > 0 } and { ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and SubtletyEnergyNeutralFinishersCdPostConditions() or ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 50 and SubtletyFinishersCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush) or { ComboPoints() + BuffStacks(anticipation_buff) < 10 - Enemies() or ComboPoints() + BuffStacks(anticipation_buff) == 10 - Enemies() and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 } and BuffRemaining(shadow_dance_buff) > 2 and target.DebuffRemaining(rupture_debuff) < 12 and target.DebuffRemaining(rupture_debuff) > 8 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() >= 4 and Spell(fan_of_knives) or { ComboPoints() + BuffStacks(anticipation_buff) < 8 or ComboPoints() + BuffStacks(anticipation_buff) == 8 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 } and BuffRemaining(shadow_dance_buff) > 2 and target.DebuffRemaining(rupture_debuff) < 12 and target.DebuffRemaining(rupture_debuff) > 8 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() == 1 and Spell(ambush) or ComboPoints() == 5 and SubtletyFinishersCdPostConditions() or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Enemies() >= 5 and Spell(fan_of_knives) or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and Spell(ambush) }
}

### actions.dance_rotation_mfd_ref

AddFunction SubtletyDanceRotationMfdRefMainActions
{
	#premeditation,if=(combo_points=3&cooldown.honor_among_thieves.remains>1&debuff.find_weakness.up)|(combo_points=0)|(combo_points=1&cooldown.honor_among_thieves.remains>1)|(debuff.find_weakness.up&combo_points<=3)
	if { ComboPoints() == 3 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and target.DebuffPresent(find_weakness_debuff) or ComboPoints() == 0 or ComboPoints() == 1 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 or target.DebuffPresent(find_weakness_debuff) and ComboPoints() <= 3 } and ComboPoints() < 5 Spell(premeditation)
	#ambush,if=buff.shadow_dance.remains<=0.1
	if BuffRemaining(shadow_dance_buff) <= 0.1 Spell(ambush)
	#wait,sec=buff.shadow_dance.remains-0.1,if=(buff.shadow_dance.remains<=1)|energy+energy.regen*buff.shadow_dance.remains<=49
	unless { BuffRemaining(shadow_dance_buff) <= 1 or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) <= 49 } and BuffRemaining(shadow_dance_buff) - 0.1 > 0
	{
		#call_action_list,name=energy_neutral_finishers,if=combo_points=5&buff.shadow_dance.remains>1&buff.shadow_dance.remains<=2
		if ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 SubtletyEnergyNeutralFinishersMainActions()
		#call_action_list,name=finishers,if=(combo_points=5&buff.shadow_dance.remains>1&buff.shadow_dance.remains<=2)&((energy+(energy.regen*buff.shadow_dance.remains))>=50)
		if ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 50 SubtletyFinishersMainActions()
		#ambush,if=debuff.find_weakness.down
		if target.DebuffExpires(find_weakness_debuff) Spell(ambush)
		#call_action_list,name=finishers,if=combo_points=5
		if ComboPoints() == 5 SubtletyFinishersMainActions()
		#ambush,if=((energy+(energy.regen*buff.shadow_dance.remains))>=72)&!(combo_points=4&cooldown.honor_among_thieves.remains<1)
		if Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and not { ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) < 1 } Spell(ambush)
	}
}

AddFunction SubtletyDanceRotationMfdRefShortCdActions
{
	#vanish
	Spell(vanish)

	unless BuffRemaining(shadow_dance_buff) <= 0.1 and Spell(ambush)
	{
		#wait,sec=buff.shadow_dance.remains-0.1,if=(buff.shadow_dance.remains<=1)|energy+energy.regen*buff.shadow_dance.remains<=49
		unless { BuffRemaining(shadow_dance_buff) <= 1 or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) <= 49 } and BuffRemaining(shadow_dance_buff) - 0.1 > 0
		{
			unless ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and SubtletyEnergyNeutralFinishersShortCdPostConditions()
			{
				unless ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 50 and SubtletyFinishersShortCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush)
				{
					#marked_for_death,if=combo_points=0
					if ComboPoints() == 0 Spell(marked_for_death)
				}
			}
		}
	}
}

AddFunction SubtletyDanceRotationMfdRefShortCdPostConditions
{
	BuffRemaining(shadow_dance_buff) <= 0.1 and Spell(ambush) or not { { BuffRemaining(shadow_dance_buff) <= 1 or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) <= 49 } and BuffRemaining(shadow_dance_buff) - 0.1 > 0 } and { ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and SubtletyEnergyNeutralFinishersShortCdPostConditions() or ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 50 and SubtletyFinishersShortCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush) or ComboPoints() == 5 and SubtletyFinishersShortCdPostConditions() or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and not { ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) < 1 } and Spell(ambush) }
}

AddFunction SubtletyDanceRotationMfdRefCdActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|(buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.shadow_dance.up))&(trinket.stat.agi.up|trinket.stat.multistrike.up|buff.archmages_greater_incandescence_agi.up)|((buff.shadow_reflection.up|(!talent.shadow_reflection.enabled&buff.shadow_dance.up))&target.time_to_die<136)
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(shadow_dance_buff) } and { BuffPresent(trinket_stat_agi_buff) or BuffPresent(trinket_stat_multistrike_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or { BuffPresent(shadow_reflection_buff) or not Talent(shadow_reflection_talent) and BuffPresent(shadow_dance_buff) } and target.TimeToDie() < 136 SubtletyUsePotionAgility()
	#shadow_reflection
	Spell(shadow_reflection)
	#use_item,slot=trinket2
	SubtletyUseItemActions()
	#use_item,slot=finger1
	SubtletyUseItemActions()
	#Arcane_Torrent,if=energy<90
	if Energy() < 90 Spell(arcane_torrent_energy)
}

AddFunction SubtletyDanceRotationMfdRefCdPostConditions
{
	BuffRemaining(shadow_dance_buff) <= 0.1 and Spell(ambush) or not { { BuffRemaining(shadow_dance_buff) <= 1 or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) <= 49 } and BuffRemaining(shadow_dance_buff) - 0.1 > 0 } and { ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and SubtletyEnergyNeutralFinishersCdPostConditions() or ComboPoints() == 5 and BuffRemaining(shadow_dance_buff) > 1 and BuffRemaining(shadow_dance_buff) <= 2 and Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 50 and SubtletyFinishersCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush) or ComboPoints() == 5 and SubtletyFinishersCdPostConditions() or Energy() + EnergyRegenRate() * BuffRemaining(shadow_dance_buff) >= 72 and not { ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) < 1 } and Spell(ambush) }
}

### actions.energy_neutral_finishers

AddFunction SubtletyEnergyNeutralFinishersMainActions
{
	#rupture,cycle_targets=1,if=remains<8
	if target.DebuffRemaining(rupture_debuff) < 8 Spell(rupture)
	#slice_and_dice,if=buff.slice_and_dice.remains<12&(buff.shadow_reflection.remains<8|!talent.shadow_reflection.enabled)
	if BuffRemaining(slice_and_dice_buff) < 12 and { BuffRemaining(shadow_reflection_buff) < 8 or not Talent(shadow_reflection_talent) } Spell(slice_and_dice)
	#slice_and_dice,if=buff.slice_and_dice.remains<2
	if BuffRemaining(slice_and_dice_buff) < 2 Spell(slice_and_dice)
}

AddFunction SubtletyEnergyNeutralFinishersShortCdPostConditions
{
	target.DebuffRemaining(rupture_debuff) < 8 and Spell(rupture) or BuffRemaining(slice_and_dice_buff) < 12 and { BuffRemaining(shadow_reflection_buff) < 8 or not Talent(shadow_reflection_talent) } and Spell(slice_and_dice) or BuffRemaining(slice_and_dice_buff) < 2 and Spell(slice_and_dice)
}

AddFunction SubtletyEnergyNeutralFinishersCdPostConditions
{
	target.DebuffRemaining(rupture_debuff) < 8 and Spell(rupture) or BuffRemaining(slice_and_dice_buff) < 12 and { BuffRemaining(shadow_reflection_buff) < 8 or not Talent(shadow_reflection_talent) } and Spell(slice_and_dice) or BuffRemaining(slice_and_dice_buff) < 2 and Spell(slice_and_dice)
}

### actions.finishers

AddFunction SubtletyFinishersMainActions
{
	#rupture,cycle_targets=1,if=remains<8
	if target.DebuffRemaining(rupture_debuff) < 8 Spell(rupture)
	#rupture,cycle_targets=1,if=(buff.shadow_reflection.remains>8&dot.rupture.remains<12)
	if BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 Spell(rupture)
	#death_from_above,if=dot.rupture.remains>20&buff.slice_and_dice.remains>5&debuff.find_weakness.up
	if target.DebuffRemaining(rupture_debuff) > 20 and BuffRemaining(slice_and_dice_buff) > 5 and target.DebuffPresent(find_weakness_debuff) Spell(death_from_above)
	#eviscerate,if=dot.rupture.remains>20&buff.slice_and_dice.remains>5&(!cooldown.death_from_above.up|!talent.death_from_above.enabled)
	if target.DebuffRemaining(rupture_debuff) > 20 and BuffRemaining(slice_and_dice_buff) > 5 and { not { not SpellCooldown(death_from_above) > 0 } or not Talent(death_from_above_talent) } Spell(eviscerate)
	#slice_and_dice,if=buff.slice_and_dice.remains<12&(buff.shadow_reflection.remains<8|!talent.shadow_reflection.enabled)
	if BuffRemaining(slice_and_dice_buff) < 12 and { BuffRemaining(shadow_reflection_buff) < 8 or not Talent(shadow_reflection_talent) } Spell(slice_and_dice)
	#slice_and_dice,if=buff.slice_and_dice.remains<2
	if BuffRemaining(slice_and_dice_buff) < 2 Spell(slice_and_dice)
	#crimson_tempest,if=(active_enemies>=3&debuff.find_weakness.down)|active_enemies>=4&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() >= 3 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 4 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(crimson_tempest)
	#death_from_above,if=talent.death_from_above.enabled
	if Talent(death_from_above_talent) Spell(death_from_above)
	#eviscerate,if=(!cooldown.death_from_above.up|!talent.death_from_above.enabled)
	if not { not SpellCooldown(death_from_above) > 0 } or not Talent(death_from_above_talent) Spell(eviscerate)
}

AddFunction SubtletyFinishersShortCdPostConditions
{
	target.DebuffRemaining(rupture_debuff) < 8 and Spell(rupture) or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 and Spell(rupture) or target.DebuffRemaining(rupture_debuff) > 20 and BuffRemaining(slice_and_dice_buff) > 5 and target.DebuffPresent(find_weakness_debuff) and Spell(death_from_above) or target.DebuffRemaining(rupture_debuff) > 20 and BuffRemaining(slice_and_dice_buff) > 5 and { not { not SpellCooldown(death_from_above) > 0 } or not Talent(death_from_above_talent) } and Spell(eviscerate) or BuffRemaining(slice_and_dice_buff) < 12 and { BuffRemaining(shadow_reflection_buff) < 8 or not Talent(shadow_reflection_talent) } and Spell(slice_and_dice) or BuffRemaining(slice_and_dice_buff) < 2 and Spell(slice_and_dice) or { Enemies() >= 3 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 4 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or Talent(death_from_above_talent) and Spell(death_from_above) or { not { not SpellCooldown(death_from_above) > 0 } or not Talent(death_from_above_talent) } and Spell(eviscerate)
}

AddFunction SubtletyFinishersCdPostConditions
{
	target.DebuffRemaining(rupture_debuff) < 8 and Spell(rupture) or BuffRemaining(shadow_reflection_buff) > 8 and target.DebuffRemaining(rupture_debuff) < 12 and Spell(rupture) or target.DebuffRemaining(rupture_debuff) > 20 and BuffRemaining(slice_and_dice_buff) > 5 and target.DebuffPresent(find_weakness_debuff) and Spell(death_from_above) or target.DebuffRemaining(rupture_debuff) > 20 and BuffRemaining(slice_and_dice_buff) > 5 and { not { not SpellCooldown(death_from_above) > 0 } or not Talent(death_from_above_talent) } and Spell(eviscerate) or BuffRemaining(slice_and_dice_buff) < 12 and { BuffRemaining(shadow_reflection_buff) < 8 or not Talent(shadow_reflection_talent) } and Spell(slice_and_dice) or BuffRemaining(slice_and_dice_buff) < 2 and Spell(slice_and_dice) or { Enemies() >= 3 and target.DebuffExpires(find_weakness_debuff) or Enemies() >= 4 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } } and Spell(crimson_tempest) or Talent(death_from_above_talent) and Spell(death_from_above) or { not { not SpellCooldown(death_from_above) > 0 } or not Talent(death_from_above_talent) } and Spell(eviscerate)
}

### actions.generators_ant

AddFunction SubtletyGeneratorsAntMainActions
{
	#call_action_list,name=finishers,if=combo_points=5&combo_points+anticipation_charges>=9
	if ComboPoints() == 5 and ComboPoints() + BuffStacks(anticipation_buff) >= 9 SubtletyFinishersMainActions()
	#call_action_list,name=energy_neutral_finishers,if=combo_points=5
	if ComboPoints() == 5 SubtletyEnergyNeutralFinishersMainActions()
	#fan_of_knives,if=active_enemies>2
	if Enemies() > 2 Spell(fan_of_knives)
	#backstab,if=energy>105
	if Energy() > 105 Spell(backstab)
}

### actions.generators_fw_ant

AddFunction SubtletyGeneratorsFwAntMainActions
{
	#backstab,if=((combo_points+anticipation_charges)<8)&(dot.rupture.remains<12&dot.rupture.remains>8)&active_enemies=1
	if ComboPoints() + BuffStacks(anticipation_buff) < 8 and target.DebuffRemaining(rupture_debuff) < 12 and target.DebuffRemaining(rupture_debuff) > 8 and Enemies() == 1 Spell(backstab)
	#backstab,if=((combo_points+anticipation_charges)<9)&(dot.rupture.remains<10&dot.rupture.remains>8)&active_enemies=1
	if ComboPoints() + BuffStacks(anticipation_buff) < 9 and target.DebuffRemaining(rupture_debuff) < 10 and target.DebuffRemaining(rupture_debuff) > 8 and Enemies() == 1 Spell(backstab)
	#call_action_list,name=finishers,if=combo_points=5
	if ComboPoints() == 5 SubtletyFinishersMainActions()
	#fan_of_knives,if=active_enemies>2
	if Enemies() > 2 Spell(fan_of_knives)
	#backstab
	Spell(backstab)
}

AddFunction SubtletyGeneratorsFwAntShortCdPostConditions
{
	ComboPoints() + BuffStacks(anticipation_buff) < 8 and target.DebuffRemaining(rupture_debuff) < 12 and target.DebuffRemaining(rupture_debuff) > 8 and Enemies() == 1 and Spell(backstab) or ComboPoints() + BuffStacks(anticipation_buff) < 9 and target.DebuffRemaining(rupture_debuff) < 10 and target.DebuffRemaining(rupture_debuff) > 8 and Enemies() == 1 and Spell(backstab) or ComboPoints() == 5 and SubtletyFinishersShortCdPostConditions() or Enemies() > 2 and Spell(fan_of_knives) or Spell(backstab)
}

### actions.generators_fw_mfd

AddFunction SubtletyGeneratorsFwMfdMainActions
{
	#call_action_list,name=finishers,if=combo_points=5
	if ComboPoints() == 5 SubtletyFinishersMainActions()
	#backstab,if=!(combo_points=4&(cooldown.honor_among_thieves.remains<1))
	if not { ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) < 1 } Spell(backstab)
}

AddFunction SubtletyGeneratorsFwMfdShortCdActions
{
	unless ComboPoints() == 5 and SubtletyFinishersShortCdPostConditions()
	{
		#marked_for_death,if=combo_points=0
		if ComboPoints() == 0 Spell(marked_for_death)
	}
}

### actions.generators_mfd

AddFunction SubtletyGeneratorsMfdMainActions
{
	#call_action_list,name=finishers,if=combo_points=5
	if ComboPoints() == 5 SubtletyFinishersMainActions()
	#backstab,if=energy>105&!(combo_points=4&cooldown.honor_among_thieves.remains<1)
	if Energy() > 105 and not { ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) < 1 } Spell(backstab)
}

### actions.opener_ant

AddFunction SubtletyOpenerAntMainActions
{
	#rupture,if=time<1
	if TimeInCombat() < 1 Spell(rupture)
}

AddFunction SubtletyOpenerAntShortCdActions
{
	#Vanish,if=time<1
	if TimeInCombat() < 1 Spell(vanish)

	unless TimeInCombat() < 1 and Spell(rupture)
	{
		#shadow_dance
		Spell(shadow_dance)
	}
}

AddFunction SubtletyOpenerAntShortCdPostConditions
{
	TimeInCombat() < 1 and Spell(rupture)
}

AddFunction SubtletyOpenerAntCdActions
{
	#shadow_reflection,if=time<1
	if TimeInCombat() < 1 Spell(shadow_reflection)
}

AddFunction SubtletyOpenerAntCdPostConditions
{
	TimeInCombat() < 1 and Spell(rupture)
}

### actions.opener_mfd

AddFunction SubtletyOpenerMfdMainActions
{
	#premeditation,if=time<1
	if TimeInCombat() < 1 and ComboPoints() < 5 Spell(premeditation)
	#ambush,if=time<1
	if TimeInCombat() < 1 Spell(ambush)
	#rupture,if=time<2
	if TimeInCombat() < 2 Spell(rupture)
	#ambush,if=time<3
	if TimeInCombat() < 3 Spell(ambush)
}

AddFunction SubtletyOpenerMfdShortCdPostConditions
{
	TimeInCombat() < 1 and Spell(ambush) or TimeInCombat() < 2 and Spell(rupture) or TimeInCombat() < 3 and Spell(ambush)
}

AddFunction SubtletyOpenerMfdCdPostConditions
{
	TimeInCombat() < 1 and Spell(ambush) or TimeInCombat() < 2 and Spell(rupture) or TimeInCombat() < 3 and Spell(ambush)
}

### actions.pool_ant

AddFunction SubtletyPoolAntMainActions
{
	#call_action_list,name=finishers,if=combo_points+anticipation_charges>=9&combo_points=5
	if ComboPoints() + BuffStacks(anticipation_buff) >= 9 and ComboPoints() == 5 SubtletyFinishersMainActions()
}

AddFunction SubtletyPoolAntShortCdPostConditions
{
	ComboPoints() + BuffStacks(anticipation_buff) >= 9 and ComboPoints() == 5 and SubtletyFinishersShortCdPostConditions()
}

AddFunction SubtletyPoolAntCdActions
{
	unless ComboPoints() + BuffStacks(anticipation_buff) >= 9 and ComboPoints() == 5 and SubtletyFinishersCdPostConditions()
	{
		#preparation,if=cooldown.vanish.remains>60|target.time_to_die<17&cooldown.shadow_dance.remains>1
		if SpellCooldown(vanish) > 60 or target.TimeToDie() < 17 and SpellCooldown(shadow_dance) > 1 Spell(preparation)
	}
}

AddFunction SubtletyPoolAntCdPostConditions
{
	ComboPoints() + BuffStacks(anticipation_buff) >= 9 and ComboPoints() == 5 and SubtletyFinishersCdPostConditions()
}

### actions.pool_mfd

AddFunction SubtletyPoolMfdMainActions
{
	#call_action_list,name=finishers,if=combo_points=5
	if ComboPoints() == 5 SubtletyFinishersMainActions()
}

AddFunction SubtletyPoolMfdShortCdPostConditions
{
	ComboPoints() == 5 and SubtletyFinishersShortCdPostConditions()
}

AddFunction SubtletyPoolMfdCdActions
{
	unless ComboPoints() == 5 and SubtletyFinishersCdPostConditions()
	{
		#preparation,if=cooldown.vanish.remains>60|target.time_to_die<17&cooldown.shadow_dance.remains>1
		if SpellCooldown(vanish) > 60 or target.TimeToDie() < 17 and SpellCooldown(shadow_dance) > 1 Spell(preparation)
	}
}

AddFunction SubtletyPoolMfdCdPostConditions
{
	ComboPoints() == 5 and SubtletyFinishersCdPostConditions()
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
	#slice_and_dice
	Spell(slice_and_dice)
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
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or Spell(slice_and_dice)
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
	BuffRemaining(lethal_poison_buff) < 1200 and Spell(deadly_poison) or Spell(stealth) or Spell(slice_and_dice)
}

### actions.shadowmeld_rotation

AddFunction SubtletyShadowmeldRotationMainActions
{
	#Premeditation
	if ComboPoints() < 5 Spell(premeditation)
	#Ambush
	Spell(ambush)
}

AddFunction SubtletyShadowmeldRotationShortCdPostConditions
{
	Spell(ambush)
}

AddFunction SubtletyShadowmeldRotationCdPostConditions
{
	Spell(ambush)
}

### actions.vanish_rotation_ant_ref

AddFunction SubtletyVanishRotationAntRefMainActions
{
	#premeditation,if=(combo_points=3&anticipation_charges=3&cooldown.honor_among_thieves.remains>1)|(combo_points<=3&anticipation_charges+combo_points<=5)
	if { ComboPoints() == 3 and BuffStacks(anticipation_buff) == 3 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 or ComboPoints() <= 3 and BuffStacks(anticipation_buff) + ComboPoints() <= 5 } and ComboPoints() < 5 Spell(premeditation)
	#premeditation,if=combo_points<=4&buff.vanish.down&buff.subterfuge.remains<1
	if ComboPoints() <= 4 and BuffExpires(vanish_buff) and BuffRemaining(subterfuge_buff) < 1 and ComboPoints() < 5 Spell(premeditation)
	#ambush,if=buff.subterfuge.remains<=0.1&buff.vanish.down
	if BuffRemaining(subterfuge_buff) <= 0.1 and BuffExpires(vanish_buff) Spell(ambush)
	#wait,sec=buff.subterfuge.remains-0.1,if=(buff.subterfuge.remains<=1&buff.vanish.down)|(energy+energy.regen*buff.subterfuge.remains<=69&buff.vanish.down)
	unless { BuffRemaining(subterfuge_buff) <= 1 and BuffExpires(vanish_buff) or Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) <= 69 and BuffExpires(vanish_buff) } and BuffRemaining(subterfuge_buff) - 0.1 > 0
	{
		#call_action_list,name=energy_neutral_finishers,if=combo_points=5&buff.subterfuge.remains>1&buff.subterfuge.remains<=2&(buff.vanish.remains<2|buff.vanish.down)
		if ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } SubtletyEnergyNeutralFinishersMainActions()
		#call_action_list,name=finishers,if=(combo_points=5&buff.subterfuge.remains>1&buff.subterfuge.remains<=2)&(buff.vanish.remains<2|buff.vanish.down)&((energy+energy.regen*buff.subterfuge.remains)>=70)
		if ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) >= 70 SubtletyFinishersMainActions()
		#ambush,if=debuff.find_weakness.down
		if target.DebuffExpires(find_weakness_debuff) Spell(ambush)
		#call_action_list,name=finishers,if=combo_points=5
		if ComboPoints() == 5 SubtletyFinishersMainActions()
		#ambush,if=((energy+(energy.regen*(buff.vanish.remains+1)))>=112)
		if Energy() + EnergyRegenRate() * { BuffRemaining(vanish_buff) + 1 } >= 112 Spell(ambush)
	}
}

AddFunction SubtletyVanishRotationAntRefShortCdPostConditions
{
	BuffRemaining(subterfuge_buff) <= 0.1 and BuffExpires(vanish_buff) and Spell(ambush) or not { { BuffRemaining(subterfuge_buff) <= 1 and BuffExpires(vanish_buff) or Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) <= 69 and BuffExpires(vanish_buff) } and BuffRemaining(subterfuge_buff) - 0.1 > 0 } and { ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and SubtletyEnergyNeutralFinishersShortCdPostConditions() or ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) >= 70 and SubtletyFinishersShortCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush) or ComboPoints() == 5 and SubtletyFinishersShortCdPostConditions() or Energy() + EnergyRegenRate() * { BuffRemaining(vanish_buff) + 1 } >= 112 and Spell(ambush) }
}

AddFunction SubtletyVanishRotationAntRefCdPostConditions
{
	BuffRemaining(subterfuge_buff) <= 0.1 and BuffExpires(vanish_buff) and Spell(ambush) or not { { BuffRemaining(subterfuge_buff) <= 1 and BuffExpires(vanish_buff) or Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) <= 69 and BuffExpires(vanish_buff) } and BuffRemaining(subterfuge_buff) - 0.1 > 0 } and { ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and SubtletyEnergyNeutralFinishersCdPostConditions() or ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) >= 70 and SubtletyFinishersCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush) or ComboPoints() == 5 and SubtletyFinishersCdPostConditions() or Energy() + EnergyRegenRate() * { BuffRemaining(vanish_buff) + 1 } >= 112 and Spell(ambush) }
}

### actions.vanish_rotation_mfd_ref

AddFunction SubtletyVanishRotationMfdRefMainActions
{
	#premeditation,if=(combo_points=3&cooldown.honor_among_thieves.remains>1&debuff.find_weakness.up)|(combo_points=0)|(combo_points=1&cooldown.honor_among_thieves.remains>1)|(debuff.find_weakness.up&combo_points<=3)
	if { ComboPoints() == 3 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and target.DebuffPresent(find_weakness_debuff) or ComboPoints() == 0 or ComboPoints() == 1 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 or target.DebuffPresent(find_weakness_debuff) and ComboPoints() <= 3 } and ComboPoints() < 5 Spell(premeditation)
	#premeditation,if=combo_points<=4&buff.vanish.down&buff.subterfuge.remains<1
	if ComboPoints() <= 4 and BuffExpires(vanish_buff) and BuffRemaining(subterfuge_buff) < 1 and ComboPoints() < 5 Spell(premeditation)
	#ambush,if=buff.subterfuge.remains<=0.1&buff.vanish.down
	if BuffRemaining(subterfuge_buff) <= 0.1 and BuffExpires(vanish_buff) Spell(ambush)
	#wait,sec=buff.subterfuge.remains-0.1,if=(buff.subterfuge.remains<=1&buff.vanish.down)|(energy+energy.regen*buff.subterfuge.remains<=69&buff.vanish.down)
	unless { BuffRemaining(subterfuge_buff) <= 1 and BuffExpires(vanish_buff) or Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) <= 69 and BuffExpires(vanish_buff) } and BuffRemaining(subterfuge_buff) - 0.1 > 0
	{
		#call_action_list,name=energy_neutral_finishers,if=combo_points=5&buff.subterfuge.remains>1&buff.subterfuge.remains<=2&(buff.vanish.remains<2|buff.vanish.down)
		if ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } SubtletyEnergyNeutralFinishersMainActions()
		#call_action_list,name=finishers,if=(combo_points=5&buff.subterfuge.remains>1&buff.subterfuge.remains<=2)&(buff.vanish.remains<2|buff.vanish.down)&((energy+energy.regen*buff.subterfuge.remains)>=70)
		if ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) >= 70 SubtletyFinishersMainActions()
		#ambush,if=debuff.find_weakness.down
		if target.DebuffExpires(find_weakness_debuff) Spell(ambush)
		#call_action_list,name=finishers,if=combo_points=5
		if ComboPoints() == 5 SubtletyFinishersMainActions()
		#ambush,if=((energy+(energy.regen*(buff.vanish.remains+1)))>=112)&!(combo_points=4&buff.vanish.remains>3)
		if Energy() + EnergyRegenRate() * { BuffRemaining(vanish_buff) + 1 } >= 112 and not { ComboPoints() == 4 and BuffRemaining(vanish_buff) > 3 } Spell(ambush)
	}
}

AddFunction SubtletyVanishRotationMfdRefShortCdPostConditions
{
	BuffRemaining(subterfuge_buff) <= 0.1 and BuffExpires(vanish_buff) and Spell(ambush) or not { { BuffRemaining(subterfuge_buff) <= 1 and BuffExpires(vanish_buff) or Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) <= 69 and BuffExpires(vanish_buff) } and BuffRemaining(subterfuge_buff) - 0.1 > 0 } and { ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and SubtletyEnergyNeutralFinishersShortCdPostConditions() or ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) >= 70 and SubtletyFinishersShortCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush) or ComboPoints() == 5 and SubtletyFinishersShortCdPostConditions() or Energy() + EnergyRegenRate() * { BuffRemaining(vanish_buff) + 1 } >= 112 and not { ComboPoints() == 4 and BuffRemaining(vanish_buff) > 3 } and Spell(ambush) }
}

AddFunction SubtletyVanishRotationMfdRefCdActions
{
	unless BuffRemaining(subterfuge_buff) <= 0.1 and BuffExpires(vanish_buff) and Spell(ambush)
	{
		#wait,sec=buff.subterfuge.remains-0.1,if=(buff.subterfuge.remains<=1&buff.vanish.down)|(energy+energy.regen*buff.subterfuge.remains<=69&buff.vanish.down)
		unless { BuffRemaining(subterfuge_buff) <= 1 and BuffExpires(vanish_buff) or Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) <= 69 and BuffExpires(vanish_buff) } and BuffRemaining(subterfuge_buff) - 0.1 > 0
		{
			unless ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and SubtletyEnergyNeutralFinishersCdPostConditions()
			{
				unless ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) >= 70 and SubtletyFinishersCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush)
				{
					unless ComboPoints() == 5 and SubtletyFinishersCdPostConditions() or Energy() + EnergyRegenRate() * { BuffRemaining(vanish_buff) + 1 } >= 112 and not { ComboPoints() == 4 and BuffRemaining(vanish_buff) > 3 } and Spell(ambush)
					{
						#preparation,if=cooldown.vanish.remains>60|target.time_to_die<17
						if SpellCooldown(vanish) > 60 or target.TimeToDie() < 17 Spell(preparation)
					}
				}
			}
		}
	}
}

AddFunction SubtletyVanishRotationMfdRefCdPostConditions
{
	BuffRemaining(subterfuge_buff) <= 0.1 and BuffExpires(vanish_buff) and Spell(ambush) or not { { BuffRemaining(subterfuge_buff) <= 1 and BuffExpires(vanish_buff) or Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) <= 69 and BuffExpires(vanish_buff) } and BuffRemaining(subterfuge_buff) - 0.1 > 0 } and { ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and SubtletyEnergyNeutralFinishersCdPostConditions() or ComboPoints() == 5 and BuffRemaining(subterfuge_buff) > 1 and BuffRemaining(subterfuge_buff) <= 2 and { BuffRemaining(vanish_buff) < 2 or BuffExpires(vanish_buff) } and Energy() + EnergyRegenRate() * BuffRemaining(subterfuge_buff) >= 70 and SubtletyFinishersCdPostConditions() or target.DebuffExpires(find_weakness_debuff) and Spell(ambush) or ComboPoints() == 5 and SubtletyFinishersCdPostConditions() or Energy() + EnergyRegenRate() * { BuffRemaining(vanish_buff) + 1 } >= 112 and not { ComboPoints() == 4 and BuffRemaining(vanish_buff) > 3 } and Spell(ambush) }
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
# crimson_tempest
# deadly_poison
# death_from_above
# death_from_above_talent
# draenic_agility_potion
# eviscerate
# fan_of_knives
# find_weakness_debuff
# honor_among_thieves_cooldown_buff
# kick
# lethal_poison_buff
# marked_for_death
# marked_for_death_talent
# premeditation
# preparation
# rupture
# rupture_debuff
# shadow_dance
# shadow_dance_buff
# shadow_reflection
# shadow_reflection_buff
# shadow_reflection_talent
# shadowmeld
# shadowmeld_buff
# shadowstep
# slice_and_dice
# slice_and_dice_buff
# stealth
# subterfuge_buff
# vanish
# vanish_buff
]]
	OvaleScripts:RegisterScript("ROGUE", "subtlety", name, desc, code, "script")
end
