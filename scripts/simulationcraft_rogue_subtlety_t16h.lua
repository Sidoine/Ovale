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
Include(ovale_rogue_common)

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
	#virmens_bite_potion
	UsePotionAgility()
	#stealth
	if not IsStealthed() Spell(stealth)
	#premeditation
	Spell(premeditation usable=1)
	#slice_and_dice
	Spell(slice_and_dice)
}

AddFunction SubtletyGeneratorActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegen() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegen() < 60 } SubtletyPoolActions()
	#fan_of_knives,if=active_enemies>=4
	if Enemies() >= 4 Spell(fan_of_knives)
	#hemorrhage,if=remains<3|position_front
	if target.DebuffRemains(hemorrhage_debuff) < 3 or False(position_front) Spell(hemorrhage)
	#shuriken_toss,if=talent.shuriken_toss.enabled&(energy<65&energy.regen<16)
	if TalentPoints(shuriken_toss_talent) and { Energy() < 65 and EnergyRegen() < 16 } Spell(shuriken_toss)
	#backstab
	Spell(backstab usable=1)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyFinisherActions
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
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#auto_attack
	#kick
	if target.IsInterruptible() Spell(kick)
	#use_item,slot=hands,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) UseItemActions()
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#shadow_blades
	Spell(shadow_blades)
	#premeditation,if=combo_points<=4
	if ComboPoints() <= 4 Spell(premeditation usable=1)
	#pool_resource,for_next=1
	#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)|(buff.sleight_of_hand.up&buff.sleight_of_hand.remains<=gcd)
	if ComboPoints() < 5 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } or { BuffPresent(sleight_of_hand_buff) and BuffRemains(sleight_of_hand_buff) <= GCD() } wait Spell(ambush usable=1)
	#pool_resource,for_next=1,extra_amount=75
	#shadow_dance,if=energy>=75&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down
	if Energy() >= 75 and Stealthed(no) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) wait Spell(shadow_dance)
	#pool_resource,for_next=1,extra_amount=45
	#vanish,if=energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
	if Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) wait Spell(vanish)
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

AddIcon mastery=subtlety help=main
{
	if InCombat(no) SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

### Required symbols
# ambush
# anticipation_buff
# anticipation_talent
# apply_poison
# arcane_torrent_energy
# backstab
# berserking
# blood_fury
# crimson_tempest
# crimson_tempest_dot_debuff
# eviscerate
# fan_of_knives
# find_weakness_debuff
# hemorrhage
# hemorrhage_debuff
# kick
# marked_for_death
# marked_for_death_talent
# master_of_subtlety_buff
# premeditation
# preparation
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
# vanish
# vanish_buff
# virmens_bite_potion
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "reference")
end
