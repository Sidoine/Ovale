local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4.7] Ovale: Assassination, Combat, Subtlety"
	local code = [[
# Ovale rogue script based on SimulationCraft.

Include(ovale_common)
Include(ovale_rogue_common)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")

###
### Assassination
###
# Based on SimulationCraft profile "Rogue_Assassination_T16H".
#	class=rogue
#	spec=assassination
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ca!200002
#	glyphs=vendetta

AddFunction AssassinationDefaultActions
{
	#auto_attack
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#mutilate,if=buff.stealth.up
	if Stealthed() Spell(mutilate)
	#slice_and_dice,if=buff.slice_and_dice.remains<2
	if BuffRemains(slice_and_dice_buff) < 2 Spell(slice_and_dice)
	#dispatch,if=dot.rupture.ticks_remain<2&energy>90
	if target.TicksRemain(rupture_debuff) < 2 and Energy() > 90 Spell(dispatch usable=1)
	#mutilate,if=dot.rupture.ticks_remain<2&energy>90
	if target.TicksRemain(rupture_debuff) < 2 and Energy() > 90 Spell(mutilate)
	#marked_for_death,if=talent.marked_for_death.enabled&combo_points=0
	if TalentPoints(marked_for_death_talent) and ComboPoints() == 0 Spell(marked_for_death)
	#rupture,if=ticks_remain<2|(combo_points=5&ticks_remain<3)
	if target.TicksRemain(rupture_debuff) < 2 or { ComboPoints() == 5 and target.TicksRemain(rupture_debuff) < 3 } Spell(rupture)
	#envenom,if=combo_points>4
	if ComboPoints() > 4 Spell(envenom)
	#envenom,if=combo_points>=2&buff.slice_and_dice.remains<3
	if ComboPoints() >= 2 and BuffRemains(slice_and_dice_buff) < 3 Spell(envenom)
	#dispatch,if=combo_points<5
	if ComboPoints() < 5 Spell(dispatch usable=1)
	#mutilate
	Spell(mutilate)
	#tricks_of_the_trade
	TricksOfTheTrade()
}

AddFunction AssassinationDefaultAoeActions
{
	#auto_attack
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#mutilate,if=buff.stealth.up
	if Stealthed() Spell(mutilate)
	#slice_and_dice,if=buff.slice_and_dice.remains<2
	if BuffRemains(slice_and_dice_buff) < 2 Spell(slice_and_dice)
	#dispatch,if=dot.rupture.ticks_remain<2&energy>90
	if target.TicksRemain(rupture_debuff) < 2 and Energy() > 90 Spell(dispatch usable=1)
	#mutilate,if=dot.rupture.ticks_remain<2&energy>90
	if target.TicksRemain(rupture_debuff) < 2 and Energy() > 90 Spell(mutilate)
	#marked_for_death,if=talent.marked_for_death.enabled&combo_points=0
	if TalentPoints(marked_for_death_talent) and ComboPoints() == 0 Spell(marked_for_death)
	#rupture,if=ticks_remain<2|(combo_points=5&ticks_remain<3)
	if target.TicksRemain(rupture_debuff) < 2 or { ComboPoints() == 5 and target.TicksRemain(rupture_debuff) < 3 } Spell(rupture)
	#fan_of_knives,if=combo_points<5&active_enemies>=4
	if ComboPoints() < 5 Spell(fan_of_knives)
	#envenom,if=combo_points>4
	if ComboPoints() > 4 Spell(envenom)
	#envenom,if=combo_points>=2&buff.slice_and_dice.remains<3
	if ComboPoints() >= 2 and BuffRemains(slice_and_dice_buff) < 3 Spell(envenom)
}

AddFunction AssassinationDefaultShortCdActions
{
	#vanish,if=time>10&!buff.stealth.up&!buff.shadow_blades.up
	if TimeInCombat() > 10 and not Stealthed() and not BuffPresent(shadow_blades_buff) Spell(vanish)
}

AddFunction AssassinationDefaultCdActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	Interrupt()
	UseRacialInterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
	#use_item,slot=hands
	UseItemActions()
	#blood_fury
	Spell(blood_fury)
	#berserking
	Spell(berserking)

	unless { Energy() < 60 and Spell(arcane_torrent_energy) }
		or { TimeInCombat() > 10 and not Stealthed() and not BuffPresent(shadow_blades_buff) and Spell(vanish) }
		or { Stealthed() and Spell(mutilate) }
		or { BuffRemains(slice_and_dice_buff) < 2 and Spell(slice_and_dice) }
		or { target.TicksRemain(rupture_debuff) < 2 and Energy() > 90 and Spell(dispatch usable=1) }
		or { target.TicksRemain(rupture_debuff) < 2 and Energy() > 90 and Spell(mutilate) }
		or { TalentPoints(marked_for_death_talent) and ComboPoints() == 0 and Spell(marked_for_death) }
		or { target.TicksRemain(rupture_debuff) < 2 or { ComboPoints() == 5 and target.TicksRemain(rupture_debuff) < 3 } and Spell(rupture) }
	{
		#vendetta
		Spell(vendetta)
	}
}

AddFunction AssassinationPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#apply_poison,lethal=deadly
	ApplyPoisons()
	#snapshot_stats
	#slice_and_dice,if=talent.marked_for_death.enabled
	if TalentPoints(marked_for_death_talent) Spell(slice_and_dice)
}

AddFunction AssassinationPrecombatShortCdActions
{
	#stealth
	if not IsStealthed() Spell(stealth)
	#marked_for_death,if=talent.marked_for_death.enabled
	if TalentPoints(marked_for_death_talent) Spell(marked_for_death)
}

AddFunction AssassinationPrecombatCdActions
{
	#virmens_bite_potion
	if Stealthed(no) UsePotionAgility()
}

### Assassination icons.
AddIcon mastery=assassination size=small checkboxon=opt_icons_left
{
	Spell(tricks_of_the_trade)
}

AddIcon mastery=assassination size=small checkboxon=opt_icons_left
{
	Spell(redirect)
}

AddIcon mastery=assassination help=shortcd
{
	if InCombat(no) AssassinationPrecombatShortCdActions()
	AssassinationDefaultShortCdActions()
}

AddIcon mastery=assassination help=main
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultActions()
}

AddIcon mastery=assassination help=aoe checkboxon=opt_aoe
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultAoeActions()
}

AddIcon mastery=assassination help=cd
{
	if InCombat(no) AssassinationPrecombatCdActions()
	AssassinationDefaultCdActions()
}

AddIcon mastery=assassination size=small checkboxon=opt_icons_right
{
	Spell(feint)
	UseRacialSurvivalActions()
}

AddIcon mastery=assassination size=small checkboxon=opt_icons_right
{
	Spell(cloak_of_shadows)
}

###
### Combat
###
# Based on SimulationCraft profile "Rogue_Combat_T16H".
#	class=rogue
#	spec=combat
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#cZ!200002

AddFunction CombatFinisherActions
{
	#rupture,if=ticks_remain<2&target.time_to_die>=26&(active_enemies<2|!buff.blade_flurry.up)
	if target.TicksRemain(rupture_debuff) < 2 and target.TimeToDie() >= 26 Spell(rupture)
	#eviscerate
	Spell(eviscerate)
}

AddFunction CombatFinisherAoeActions
{
	#crimson_tempest,if=active_enemies>=7&dot.crimson_tempest_dot.ticks_remain<=2
	if Enemies() >= 7 and target.TicksRemain(crimson_tempest_dot_debuff) <= 2 Spell(crimson_tempest)
	#eviscerate
	Spell(eviscerate)
}

AddFunction CombatGeneratorActions
{
	#revealing_strike,if=ticks_remain<2
	if target.TicksRemain(revealing_strike_debuff) < 2 Spell(revealing_strike)
	#sinister_strike
	Spell(sinister_strike)
}

AddFunction CombatGeneratorAoeActions
{
	#fan_of_knives,line_cd=5,if=active_enemies>=4
	# XXX line_cd?
	Spell(fan_of_knives)
	#revealing_strike,if=ticks_remain<2
	if target.TicksRemain(revealing_strike_debuff) < 2 Spell(revealing_strike)
	#sinister_strike
	Spell(sinister_strike)
}

AddFunction CombatDefaultActions
{
	#auto_attack
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#ambush
	Spell(ambush usable=1)
	#slice_and_dice,if=buff.slice_and_dice.remains<2|(buff.slice_and_dice.remains<15&buff.bandits_guile.stack=11&combo_points>=4)
	if BuffRemains(slice_and_dice_buff) < 2 or { BuffRemains(slice_and_dice_buff) < 15 and BuffStacks(bandits_guile_buff) == 11 and ComboPoints() >= 4 } Spell(slice_and_dice)
	#marked_for_death,if=talent.marked_for_death.enabled&(combo_points<=1&dot.revealing_strike.ticking)
	if TalentPoints(marked_for_death_talent) and { ComboPoints() <= 1 and target.DebuffPresent(revealing_strike_debuff) } Spell(marked_for_death)
	#run_action_list,name=generator,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<=4&!dot.revealing_strike.ticking)
	if ComboPoints() < 5 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) <= 4 and not target.DebuffPresent(revealing_strike_debuff) } CombatGeneratorActions()
	#run_action_list,name=finisher,if=!talent.anticipation.enabled|buff.deep_insight.up|cooldown.shadow_blades.remains<=11|anticipation_charges>=4|(buff.shadow_blades.up&anticipation_charges>=3)
	# XXX possible bug in SimC action list in missing combo_points==5
	if ComboPoints() == 5 and { not TalentPoints(anticipation_talent) or BuffPresent(deep_insight_buff) or SpellCooldown(shadow_blades) <= 11 or BuffStacks(anticipation_buff) >= 4 or { BuffPresent(shadow_blades_buff) and BuffStacks(anticipation_buff) >= 3 } } CombatFinisherActions()
	#run_action_list,name=generator,if=energy>60|buff.deep_insight.down|buff.deep_insight.remains>5-combo_points
	if Energy() > 60 or BuffExpires(deep_insight_buff) or BuffRemains(deep_insight_buff) > 5 - ComboPoints() CombatGeneratorActions()
	TricksOfTheTrade()
}

AddFunction CombatDefaultAoeActions
{
	#auto_attack
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#blade_flurry,if=(active_enemies>=2&!buff.blade_flurry.up)|(active_enemies<2&buff.blade_flurry.up)
	if not BuffPresent(blade_flurry_buff) Spell(blade_flurry)
	#ambush
	Spell(ambush usable=1)
	#slice_and_dice,if=buff.slice_and_dice.remains<2|(buff.slice_and_dice.remains<15&buff.bandits_guile.stack=11&combo_points>=4)
	if BuffRemains(slice_and_dice_buff) < 2 or { BuffRemains(slice_and_dice_buff) < 15 and BuffStacks(bandits_guile_buff) == 11 and ComboPoints() >= 4 } Spell(slice_and_dice)
	#marked_for_death,if=talent.marked_for_death.enabled&(combo_points<=1&dot.revealing_strike.ticking)
	if TalentPoints(marked_for_death_talent) and { ComboPoints() <= 1 and target.DebuffPresent(revealing_strike_debuff) } Spell(marked_for_death)
	#run_action_list,name=generator,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<=4&!dot.revealing_strike.ticking)
	if ComboPoints() < 5 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) <= 4 and not target.DebuffPresent(revealing_strike_debuff) } CombatGeneratorAoeActions()
	#run_action_list,name=finisher,if=!talent.anticipation.enabled|buff.deep_insight.up|cooldown.shadow_blades.remains<=11|anticipation_charges>=4|(buff.shadow_blades.up&anticipation_charges>=3)
	if ComboPoints() == 5 and { not TalentPoints(anticipation_talent) or BuffPresent(deep_insight_buff) or SpellCooldown(shadow_blades) <= 11 or BuffStacks(anticipation_buff) >= 4 or { BuffPresent(shadow_blades_buff) and BuffStacks(anticipation_buff) >= 3 } } CombatFinisherAoeActions()
	#run_action_list,name=generator,if=energy>60|buff.deep_insight.down|buff.deep_insight.remains>5-combo_points
	if Energy() > 60 or BuffExpires(deep_insight_buff) or BuffRemains(deep_insight_buff) > 5 - ComboPoints() CombatGeneratorAoeActions()
	TricksOfTheTrade()
}

AddFunction CombatDefaultShortCdActions
{
	#vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(buff.shadow_blades.down&(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4))))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<20)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))
	if TimeInCombat() > 10 and { ComboPoints() < 3 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } or { BuffExpires(shadow_blades_buff) and { ComboPoints() < 4 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } } } } and { { TalentPoints(shadow_focus_talent) and BuffExpires(adrenaline_rush_buff) and Energy() < 20 } or { TalentPoints(subterfuge_talent) and Energy() >= 90 } or { not TalentPoints(shadow_focus_talent) and not TalentPoints(subterfuge_talent) and Energy() >= 60 } } Spell(vanish)
	#killing_spree,if=energy<45
	if Energy() < 45 Spell(killing_spree)
}

AddFunction CombatDefaultCdActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	Interrupt()
	UseRacialInterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
	#use_item,slot=hands,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) UseItemActions()
	#blood_fury,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) Spell(blood_fury)
	#berserking,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) Spell(berserking)

	unless { Energy() < 60 and Spell(arcane_torrent_energy) }
		or Spell(ambush usable=1)
		or { TimeInCombat() > 10 and { ComboPoints() < 3 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } or { BuffExpires(shadow_blades_buff) and { ComboPoints() < 4 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } } } } and { { TalentPoints(shadow_focus_talent) and BuffExpires(adrenaline_rush_buff) and Energy() < 20 } or { TalentPoints(subterfuge_talent) and Energy() >= 90 } or { not TalentPoints(shadow_focus_talent) and not TalentPoints(subterfuge_talent) and Energy() >= 60 } } and Spell(vanish) }
	{
		#shadow_blades,if=time>5
		if TimeInCombat() > 5 Spell(shadow_blades)

		unless { Energy() < 45 and Spell(killing_spree) }
		{
			#adrenaline_rush,if=energy<35|buff.shadow_blades.up
			if Energy() < 35 or BuffPresent(shadow_blades_buff) Spell(adrenaline_rush)
		}
	}
}

AddFunction CombatPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#apply_poison,lethal=deadly
	ApplyPoisons()
	#snapshot_stats
	#slice_and_dice,if=talent.marked_for_death.enabled
	if TalentPoints(marked_for_death_talent) Spell(slice_and_dice)
}

AddFunction CombatPrecombatShortCdActions
{
	#stealth
	if not IsStealthed() Spell(stealth)
	#marked_for_death,if=talent.marked_for_death.enabled
	if TalentPoints(marked_for_death_talent) Spell(marked_for_death)
}

AddFunction CombatPrecombatCdActions
{
	#virmens_bite_potion
	if Stealthed(no) UsePotionAgility()
}

AddFunction CombatPrecombatCdActions
{
	#virmens_bite_potion
	UsePotionAgility()
}

### Combat icons.
AddIcon mastery=combat size=small checkboxon=opt_icons_left
{
	Spell(tricks_of_the_trade)
}

AddIcon mastery=combat size=small checkboxon=opt_icons_left
{
	if BuffPresent(blade_flurry_buff) Texture(ability_warrior_punishingblow help=BladeFlurryIsActive)
	Spell(redirect)
}

AddIcon mastery=combat help=shortcd
{
	if InCombat(no) CombatPrecombatShortCdActions()
	CombatDefaultShortCdActions()
}

AddIcon mastery=combat help=main
{
	if InCombat(no) CombatPrecombatActions()
	CombatDefaultActions()
}

AddIcon mastery=combat help=aoe checkboxon=opt_aoe
{
	if InCombat(no) CombatPrecombatActions()
	CombatDefaultAoeActions()
}

AddIcon mastery=combat help=cd
{
	if InCombat(no) CombatPrecombatCdActions()
	CombatDefaultCdActions()
}

AddIcon mastery=combat size=small checkboxon=opt_icons_right
{
	Spell(feint)
	UseRacialSurvivalActions()
}

AddIcon mastery=combat size=small checkboxon=opt_icons_right
{
	Spell(cloak_of_shadows)
}

###
### Subtlety
###
# Based on SimulationCraft profile "Rogue_Subtlety_T16H".
#	class=rogue
#	spec=subtlety
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#cb!200002

AddFunction SubtletyPoolActions
{
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
}

AddFunction SubtletyPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#apply_poison,lethal=deadly
	ApplyPoisons()
	#snapshot_stats
	#premeditation
	Spell(premeditation)
	#slice_and_dice
	Spell(slice_and_dice)
}

AddFunction SubtletyPrecombatShortCdActions
{
	#stealth
	if not IsStealthed() Spell(stealth)
}

AddFunction SubtletyPrecombatCdActions
{
	#virmens_bite_potion
	if Stealthed(no) UsePotionAgility()
}

AddFunction SubtletyGeneratorActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegen() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegen() < 60 } SubtletyPoolActions()
	#hemorrhage,if=remains<3|position_front
	if target.DebuffRemains(hemorrhage_debuff) < 3 or False(position_front) Spell(hemorrhage)
	#shuriken_toss,if=talent.shuriken_toss.enabled&(energy<65&energy.regen<16)
	if TalentPoints(shuriken_toss_talent) and { Energy() < 65 and EnergyRegen() < 16 } Spell(shuriken_toss)
	#backstab
	Spell(backstab usable=1)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyGeneratorAoeActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegen() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegen() < 60 } SubtletyPoolActions()
	#fan_of_knives,if=active_enemies>=4
	Spell(fan_of_knives)
}

AddFunction SubtletyFinisherActions
{
	#slice_and_dice,if=buff.slice_and_dice.remains<4
	if BuffRemains(slice_and_dice_buff) < 4 Spell(slice_and_dice)
	#rupture,if=ticks_remain<2&active_enemies<3
	if target.TicksRemain(rupture_debuff) < 2 Spell(rupture)
	#eviscerate,if=active_enemies<4|(active_enemies>3&dot.crimson_tempest_dot.ticks_remain>=2)
	Spell(eviscerate)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyFinisherAoeActions
{
	#slice_and_dice,if=buff.slice_and_dice.remains<4
	if BuffRemains(slice_and_dice_buff) < 4 Spell(slice_and_dice)
	#rupture,if=ticks_remain<2&active_enemies<3
	if target.TicksRemain(rupture_debuff) < 2 and Enemies() < 3 Spell(rupture)
	#crimson_tempest,if=(active_enemies>1&dot.crimson_tempest_dot.ticks_remain<=2&combo_points=5)|active_enemies>=5
	if { Enemies() > 1 and target.TicksRemain(crimson_tempest_dot_debuff) <= 2 and ComboPoints() == 5 } or Enemies() >= 5 Spell(crimson_tempest)
	#eviscerate,if=active_enemies<4|(active_enemies>3&dot.crimson_tempest_dot.ticks_remain>=2)
	if Enemies() < 4 or { Enemies() > 3 and target.TicksRemain(crimson_tempest_dot_debuff) >= 2 } Spell(eviscerate)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyDefaultActions
{
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#premeditation,if=combo_points<=4
	if ComboPoints() <= 4 Spell(premeditation usable=1)
	#pool_resource,for_next=1
	#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
	if ComboPoints() < 5 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } or { BuffPresent(sleight_of_hand_buff) and BuffRemains(sleight_of_hand_buff) <= GCD() } wait Spell(ambush usable=1)
	#marked_for_death,if=talent.marked_for_death.enabled&combo_points=0
	if TalentPoints(marked_for_death_talent) and ComboPoints() == 0 Spell(marked_for_death)
	#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
	if TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemains(rupture_debuff) > 2 and { BuffRemains(slice_and_dice_buff) < 6 or target.DebuffRemains(rupture_debuff) < 4 } SubtletyGeneratorActions()
	#run_action_list,name=finisher,if=combo_points=5
	if ComboPoints() == 5 SubtletyFinisherActions()
	#run_action_list,name=generator,if=combo_points<4|energy>80|talent.anticipation.enabled
	if ComboPoints() < 4 or Energy() > 80 or TalentPoints(anticipation_talent) SubtletyGeneratorActions()
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyDefaultAoeActions
{
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#premeditation,if=combo_points<=4
	if ComboPoints() <= 4 Spell(premeditation usable=1)
	#pool_resource,for_next=1
	#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
	if ComboPoints() < 5 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } or { BuffPresent(sleight_of_hand_buff) and BuffRemains(sleight_of_hand_buff) <= GCD() } wait Spell(ambush usable=1)
	#marked_for_death,if=talent.marked_for_death.enabled&combo_points=0
	if TalentPoints(marked_for_death_talent) and ComboPoints() == 0 Spell(marked_for_death)
	#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
	if TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemains(rupture_debuff) > 2 and { BuffRemains(slice_and_dice_buff) < 6 or target.DebuffRemains(rupture_debuff) < 4 } SubtletyGeneratorAoeActions()
	#run_action_list,name=finisher,if=combo_points=5
	if ComboPoints() == 5 SubtletyFinisherAoeActions()
	#run_action_list,name=generator,if=combo_points<4|energy>80|talent.anticipation.enabled
	if ComboPoints() < 4 or Energy() > 80 or TalentPoints(anticipation_talent) SubtletyGeneratorAoeActions()
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyDefaultShortCdActions
{
	unless { Energy() < 60 and Spell(arcane_torrent_energy) }
		or { ComboPoints() <= 4 and Spell(premeditation usable=1) }
		or { { ComboPoints() < 5 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } or { BuffPresent(sleight_of_hand_buff) and BuffRemains(sleight_of_hand_buff) <= GCD() } } and Spell(ambush usable=1) }
	{
		#pool_resource,for_next=1,extra_amount=75
		#shadow_dance,if=energy>=75&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down
		if Spell(shadow_dance) and Stealthed(no) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) wait if Energy() >= 75 Spell(shadow_dance)
		#pool_resource,for_next=1,extra_amount=45
		#vanish,if=energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
		if Spell(vanish) and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) wait if Energy() >= 45 Spell(vanish)
	}
}

AddFunction SubtletyDefaultCdActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	Interrupt()
	UseRacialInterruptActions()
	#use_item,slot=hands,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) UseItemActions()
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)

	unless { Energy() < 60 and Spell(arcane_torrent_energy) }
	{
		#shadow_blades
		Spell(shadow_blades)
	}
}

### Subtlety icons.
AddIcon mastery=subtlety size=small checkboxon=opt_icons_left
{
	Spell(tricks_of_the_trade)
}

AddIcon mastery=subtlety size=small checkboxon=opt_icons_left
{
	Spell(redirect)
}

AddIcon mastery=subtlety help=shortcd
{
	if InCombat(no) SubtletyPrecombatShortCdActions()
	SubtletyDefaultShortCdActions()
}

AddIcon mastery=subtlety help=main
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

AddIcon mastery=subtlety help=aoe checkboxon=opt_aoe
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultAoeActions()
}

AddIcon mastery=subtlety help=cd
{
	if InCombat(no) SubtletyPrecombatCdActions()
	SubtletyDefaultCdActions()
}

AddIcon mastery=subtlety size=small checkboxon=opt_icons_right
{
	Spell(feint)
	UseRacialSurvivalActions()
}

AddIcon mastery=subtlety size=small checkboxon=opt_icons_right
{
	Spell(cloak_of_shadows)
}
]]

	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "script")
end
