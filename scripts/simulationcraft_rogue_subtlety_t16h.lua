local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Rogue_Subtlety_T16H"
	local desc = "[5.4] SimulationCraft: Rogue_Subtlety_T16H"
	local code = [[
# Based on SimulationCraft profile "Rogue_Subtlety_T16H".
#	class=rogue
#	spec=subtlety
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#cb!200002

Include(ovale_common)
Include(ovale_rogue_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(kick) Spell(kick)
		if target.Classification(worldboss no)
		{
			if target.InRange(kidney_shot) Spell(kidney_shot)
			if target.InRange(cheap_shot) and BuffPresent(stealthed_buff any=1) Spell(cheap_shot)
			Spell(arcane_torrent_energy)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

AddFunction Stealth
{
	if Talent(subterfuge_talent) Spell(stealth_subterfuge)
	if Talent(subterfuge_talent no) Spell(stealth)
}

AddFunction SubtletyPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#virmens_bite_potion
	UsePotionAgility()
	#stealth
	if BuffExpires(stealthed_buff any=1) Stealth()
	#premeditation
	if BuffPresent(stealthed_buff any=1) Spell(premeditation)
	#slice_and_dice
	if BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
}

AddFunction SubtletyPoolActions
{
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
}

AddFunction SubtletyDefaultActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#auto_attack
	#kick
	InterruptActions()
	#use_item,slot=hands,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) UseItemActions()
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury_ap)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#shadow_blades
	Spell(shadow_blades)
	#premeditation,if=combo_points<=4
	if ComboPoints() <= 4 and BuffPresent(stealthed_buff any=1) Spell(premeditation)
	#pool_resource,for_next=1
	#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
	if { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and { BuffPresent(stealthed_buff any=1) or BuffPresent(sleight_of_hand_buff) } Spell(ambush)
	unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or BuffPresent(sleight_of_hand_buff) and BuffRemaining(sleight_of_hand_buff) <= GCD() } and { BuffPresent(stealthed_buff any=1) or BuffPresent(sleight_of_hand_buff) } and not SpellCooldown(ambush) > 0
	{
		#pool_resource,for_next=1,extra_amount=75
		#shadow_dance,if=energy>=75&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down
		if Energy() >= 75 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) Spell(shadow_dance)
		#Remove any 'extra_amount=75' condition from the following statement.
		unless Energy() >= 75 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) and not SpellCooldown(shadow_dance) > 0
		{
			#pool_resource,for_next=1,extra_amount=45
			#vanish,if=energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
			if Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
			#Remove any 'extra_amount=45' condition from the following statement.
			unless Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and not SpellCooldown(vanish) > 0
			{
				#marked_for_death,if=talent.marked_for_death.enabled&combo_points=0
				if Talent(marked_for_death_talent) and ComboPoints() == 0 Spell(marked_for_death)
				#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
				if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorActions()
				#run_action_list,name=finisher,if=combo_points=5
				if ComboPoints() == 5 SubtletyFinisherActions()
				#run_action_list,name=generator,if=combo_points<4|energy>80|talent.anticipation.enabled
				if ComboPoints() < 4 or Energy() > 80 or Talent(anticipation_talent) SubtletyGeneratorActions()
				#run_action_list,name=pool
				SubtletyPoolActions()
			}
		}
	}
}

AddFunction SubtletyGeneratorActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegen() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegen() < 60 } SubtletyPoolActions()
	#fan_of_knives,if=active_enemies>=4
	if Enemies() >= 4 Spell(fan_of_knives)
	#hemorrhage,if=remains<3|position_front
	if target.DebuffRemaining(hemorrhage_debuff) < 3 or False(position_front) Spell(hemorrhage)
	#shuriken_toss,if=talent.shuriken_toss.enabled&(energy<65&energy.regen<16)
	if Talent(shuriken_toss_talent) and Energy() < 65 and EnergyRegen() < 16 Spell(shuriken_toss)
	#backstab
	Spell(backstab)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyFinisherActions
{
	#slice_and_dice,if=buff.slice_and_dice.remains<4
	if BuffRemaining(slice_and_dice_buff) < 4 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
	#rupture,if=ticks_remain<2&active_enemies<3
	if target.TicksRemaining(rupture_debuff) < 2 and Enemies() < 3 Spell(rupture)
	#crimson_tempest,if=(active_enemies>1&dot.crimson_tempest_dot.ticks_remain<=2&combo_points=5)|active_enemies>=5
	if Enemies() > 1 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 Spell(crimson_tempest)
	#eviscerate,if=active_enemies<4|(active_enemies>3&dot.crimson_tempest_dot.ticks_remain>=2)
	if Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 Spell(eviscerate)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddIcon specialization=subtlety help=main enemies=1
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

AddIcon specialization=subtlety help=aoe
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

### Required symbols
# ambush
# anticipation_buff
# anticipation_talent
# arcane_torrent_energy
# backstab
# berserking
# blood_fury_ap
# cheap_shot
# crimson_tempest
# crimson_tempest_dot_debuff
# deadly_poison
# eviscerate
# fan_of_knives
# find_weakness_debuff
# hemorrhage
# hemorrhage_debuff
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
# shadow_blades
# shadow_dance
# shadow_dance_buff
# shuriken_toss
# shuriken_toss_talent
# sleight_of_hand_buff
# slice_and_dice
# slice_and_dice_buff
# stealth
# stealth_subterfuge
# subterfuge_talent
# vanish
# vanish_buff
# virmens_bite_potion
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "reference")
end
