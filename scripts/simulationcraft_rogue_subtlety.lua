local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Rogue_Subtlety_T17M"
	local desc = "[6.0] SimulationCraft: Rogue_Subtlety_T17M"
	local code = [[
# Based on SimulationCraft profile "Rogue_Subtlety_T17M".
#	class=rogue
#	spec=subtlety
#	talents=3111122
#	glyphs=energy/hemorrhaging_veins

Include(ovale_common)
Include(ovale_rogue_spells)

Define(honor_among_thieves_cooldown_buff 51699)
	SpellInfo(honor_among_thieves_cooldown_buff duration=2.2)

AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction GetInMeleeRange
{
	if not target.InRange(kick)
	{
		Spell(shadowstep)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
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

AddFunction SubtletyDefaultActions
{
	#potion,name=draenic_agility,if=buff.bloodlust.react|target.time_to_die<40|buff.shadow_dance.up&(trinket.proc.agi.react|trinket.proc.multistrike.react|trinket.stacking_proc.agi.react|trinket.stacking_proc.multistrike.react|buff.archmages_greater_incandescence_agi.react)
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 or BuffPresent(shadow_dance_buff) and { BuffPresent(trinket_proc_agi_buff) or BuffPresent(trinket_proc_multistrike_buff) or BuffPresent(trinket_stacking_proc_agi_buff) or BuffPresent(trinket_stacking_proc_multistrike_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } UsePotionAgility()
	#kick
	InterruptActions()
	#use_item,slot=trinket2,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) UseItemActions()
	#shadow_reflection,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(shadow_reflection)
	#blood_fury,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(blood_fury_ap)
	#berserking,if=buff.shadow_dance.up
	if BuffPresent(shadow_dance_buff) Spell(berserking)
	#arcane_torrent,if=energy<60&buff.shadow_dance.up
	if Energy() < 60 and BuffPresent(shadow_dance_buff) Spell(arcane_torrent_energy)
	#slice_and_dice,if=buff.slice_and_dice.remains<10.8&buff.slice_and_dice.remains<target.time_to_die&combo_points=((target.time_to_die-buff.slice_and_dice.remains)%6)+1
	if BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() and ComboPoints() == { target.TimeToDie() - BuffRemaining(slice_and_dice_buff) } / 6 + 1 Spell(slice_and_dice)
	#premeditation,if=combo_points<=4&!(buff.shadow_dance.up&energy>100&combo_points>1)&!buff.subterfuge.up|(buff.subterfuge.up&debuff.find_weakness.up)
	if ComboPoints() <= 4 and not { BuffPresent(shadow_dance_buff) and Energy() > 100 and ComboPoints() > 1 } and not BuffPresent(subterfuge_buff) or BuffPresent(subterfuge_buff) and target.DebuffPresent(find_weakness_debuff) Spell(premeditation)
	#pool_resource,for_next=1
	#garrote,if=!ticking&time<1
	if not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 Spell(garrote)
	unless not target.DebuffPresent(garrote_debuff) and TimeInCombat() < 1 and SpellUsable(garrote) and SpellCooldown(garrote) < TimeToEnergyFor(garrote)
	{
		#wait,sec=1,if=buff.subterfuge.remains>1.1&buff.subterfuge.remains<1.3&time>6
		unless BuffRemaining(subterfuge_buff) > 1.1 and BuffRemaining(subterfuge_buff) < 1.3 and TimeInCombat() > 6 and 1
		{
			#pool_resource,for_next=1
			#ambush,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<3)&(time<1.2|buff.shadow_dance.up|time>5)
			if ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and { TimeInCombat() < 1.2 or BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } Spell(ambush)
			unless { ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 and { TimeInCombat() < 1.2 or BuffPresent(shadow_dance_buff) or TimeInCombat() > 5 } } and SpellUsable(ambush) and SpellCooldown(ambush) < TimeToEnergyFor(ambush)
			{
				#pool_resource,for_next=1,extra_amount=50
				#shadow_dance,if=energy>=50&buff.stealth.down&buff.vanish.down&debuff.find_weakness.down|(buff.bloodlust.up&(dot.hemorrhage.ticking|dot.garrote.ticking|dot.rupture.ticking))
				if Energy() >= 50 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } Spell(shadow_dance)
				#Remove any 'Energy() >= 50' condition from the following statement.
				unless { Energy() >= 50 and BuffExpires(stealthed_buff any=1) and BuffExpires(vanish_buff) and target.DebuffExpires(find_weakness_debuff) or BuffPresent(burst_haste_buff any=1) and { target.DebuffPresent(hemorrhage_debuff) or target.DebuffPresent(garrote_debuff) or target.DebuffPresent(rupture_debuff) } } and SpellUsable(shadow_dance) and SpellCooldown(shadow_dance) < TimeToEnergy(50)
				{
					#pool_resource,for_next=1,extra_amount=50
					#vanish,if=talent.shadow_focus.enabled&energy>=45&energy<=75&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
					if Talent(shadow_focus_talent) and Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
					#Remove any 'Energy() >= 50' condition from the following statement.
					unless Talent(shadow_focus_talent) and Energy() >= 45 and Energy() <= 75 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(50)
					{
						#pool_resource,for_next=1,extra_amount=90
						#vanish,if=talent.subterfuge.enabled&energy>=90&combo_points<=3&buff.shadow_dance.down&buff.master_of_subtlety.down&debuff.find_weakness.down
						if Talent(subterfuge_talent) and Energy() >= 90 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) Spell(vanish)
						#Remove any 'Energy() >= 90' condition from the following statement.
						unless Talent(subterfuge_talent) and Energy() >= 90 and ComboPoints() <= 3 and BuffExpires(shadow_dance_buff) and BuffExpires(master_of_subtlety_buff) and target.DebuffExpires(find_weakness_debuff) and SpellUsable(vanish) and SpellCooldown(vanish) < TimeToEnergy(90)
						{
							#marked_for_death,if=combo_points=0
							if ComboPoints() == 0 Spell(marked_for_death)
							#run_action_list,name=generator,if=talent.anticipation.enabled&anticipation_charges<4&buff.slice_and_dice.up&dot.rupture.remains>2&(buff.slice_and_dice.remains<6|dot.rupture.remains<4)
							if Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 and BuffPresent(slice_and_dice_buff) and target.DebuffRemaining(rupture_debuff) > 2 and { BuffRemaining(slice_and_dice_buff) < 6 or target.DebuffRemaining(rupture_debuff) < 4 } SubtletyGeneratorActions()
							#run_action_list,name=finisher,if=combo_points=5
							if ComboPoints() == 5 SubtletyFinisherActions()
							#run_action_list,name=generator,if=combo_points<4|(combo_points=4&cooldown.honor_among_thieves.remains>1&energy>70-energy.regen)|talent.anticipation.enabled
							if ComboPoints() < 4 or ComboPoints() == 4 and BuffRemaining(honor_among_thieves_cooldown_buff) > 1 and Energy() > 70 - EnergyRegenRate() or Talent(anticipation_talent) SubtletyGeneratorActions()
							#run_action_list,name=pool
							SubtletyPoolActions()
						}
					}
				}
			}
		}
	}
}

AddFunction SubtletyFinisherActions
{
	#rupture,cycle_targets=1,if=(!ticking|remains<duration*0.3)&active_enemies<=3&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if { not target.DebuffPresent(rupture_debuff) or target.DebuffRemaining(rupture_debuff) < BaseDuration(rupture_debuff) * 0.3 } and Enemies() <= 3 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(rupture)
	#slice_and_dice,if=buff.slice_and_dice.remains<10.8&buff.slice_and_dice.remains<target.time_to_die
	if BuffRemaining(slice_and_dice_buff) < 10.8 and BuffRemaining(slice_and_dice_buff) < target.TimeToDie() Spell(slice_and_dice)
	#death_from_above
	Spell(death_from_above)
	#crimson_tempest,if=(active_enemies>=3&dot.crimson_tempest_dot.ticks_remain<=2&combo_points=5)|active_enemies>=5&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() >= 3 and target.TicksRemaining(crimson_tempest_dot_debuff) < 3 and ComboPoints() == 5 or Enemies() >= 5 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(crimson_tempest)
	#eviscerate,if=active_enemies<4|(active_enemies>3&dot.crimson_tempest_dot.ticks_remain>=2)&(cooldown.death_from_above.remains>0|!talent.death_from_above.enabled)
	if Enemies() < 4 or Enemies() > 3 and target.TicksRemaining(crimson_tempest_dot_debuff) >= 2 and { SpellCooldown(death_from_above) > 0 or not Talent(death_from_above_talent) } Spell(eviscerate)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyGeneratorActions
{
	#run_action_list,name=pool,if=buff.master_of_subtlety.down&buff.shadow_dance.down&debuff.find_weakness.down&(energy+cooldown.shadow_dance.remains*energy.regen<80|energy+cooldown.vanish.remains*energy.regen<60)
	if BuffExpires(master_of_subtlety_buff) and BuffExpires(shadow_dance_buff) and target.DebuffExpires(find_weakness_debuff) and { Energy() + SpellCooldown(shadow_dance) * EnergyRegenRate() < 80 or Energy() + SpellCooldown(vanish) * EnergyRegenRate() < 60 } SubtletyPoolActions()
	#fan_of_knives,if=active_enemies>1
	if Enemies() > 1 Spell(fan_of_knives)
	#shuriken_toss,if=energy<65&energy.regen<16
	if Energy() < 65 and EnergyRegenRate() < 16 Spell(shuriken_toss)
	#backstab
	Spell(backstab)
	#hemorrhage,if=position_front
	if False(position_front) Spell(hemorrhage)
	#run_action_list,name=pool
	SubtletyPoolActions()
}

AddFunction SubtletyPoolActions
{
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
}

AddFunction SubtletyPrecombatActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=calamari_crepes
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#potion,name=draenic_agility
	UsePotionAgility()
	#stealth
	if BuffExpires(stealthed_buff any=1) Spell(stealth)
	#premeditation
	Spell(premeditation)
	#slice_and_dice
	Spell(slice_and_dice)
	#honor_among_thieves,cooldown=2.2,cooldown_stddev=0.1
}

AddIcon specialization=subtlety help=main enemies=1
{
	if not InCombat() SubtletyPrecombatActions()
	SubtletyDefaultActions()
}

AddIcon specialization=subtlety help=aoe
{
	if not InCombat() SubtletyPrecombatActions()
	SubtletyDefaultActions()
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
# crimson_tempest_dot_debuff
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
# lethal_poison_buff
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
# shadowstep
# shuriken_toss
# slice_and_dice
# slice_and_dice_buff
# stealth
# subterfuge_buff
# subterfuge_talent
# trinket_proc_agi_buff
# trinket_stacking_proc_agi_buff
# vanish
# vanish_buff
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "reference")
end
