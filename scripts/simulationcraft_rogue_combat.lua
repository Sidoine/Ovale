local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Rogue_Combat_T16M"
	local desc = "[6.0.2] SimulationCraft: Rogue_Combat_T16M"
	local code = [[
# Based on SimulationCraft profile "Rogue_Combat_T16M".
#	class=rogue
#	spec=combat
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#cZ!200002.
#	glyphs=energy/disappearance

Include(ovale_common)
Include(ovale_rogue_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
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

AddFunction CombatPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#apply_poison,lethal=deadly
	if BuffRemaining(lethal_poison_buff) < 1200 Spell(deadly_poison)
	#snapshot_stats
	#potion,name=virmens_bite
	UsePotionAgility()
	#stealth
	if BuffExpires(stealthed_buff any=1) Spell(stealth)
	#marked_for_death
	Spell(marked_for_death)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
}

AddFunction CombatDefaultActions
{
	#potion,name=virmens_bite,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#kick
	InterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#blade_flurry,if=(active_enemies>=2&!buff.blade_flurry.up)|(active_enemies<2&buff.blade_flurry.up)
	if Enemies() >= 2 and not BuffPresent(blade_flurry_buff) or Enemies() < 2 and BuffPresent(blade_flurry_buff) Spell(blade_flurry)
	#shadow_reflection,if=(cooldown.killing_spree.remains<10&combo_points>3)|buff.adrenaline_rush.up
	if SpellCooldown(killing_spree) < 10 and ComboPoints() > 3 or BuffPresent(adrenaline_rush_buff) Spell(shadow_reflection)
	#ambush
	Spell(ambush)
	#vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4)))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<20)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))
	if TimeInCombat() > 10 and { ComboPoints() < 3 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 3 or ComboPoints() < 4 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } and { Talent(shadow_focus_talent) and BuffExpires(adrenaline_rush_buff) and Energy() < 20 or Talent(subterfuge_talent) and Energy() >= 90 or not Talent(shadow_focus_talent) and not Talent(subterfuge_talent) and Energy() >= 60 } Spell(vanish)
	#killing_spree,if=energy<50&(!talent.shadow_reflection.enabled|cooldown.shadow_reflection.remains>30|buff.shadow_reflection.remains>3)
	if Energy() < 50 and { not Talent(shadow_reflection_talent) or SpellCooldown(shadow_reflection) > 30 or BuffRemaining(shadow_reflection_buff) > 3 } Spell(killing_spree)
	#adrenaline_rush,if=energy<35
	if Energy() < 35 Spell(adrenaline_rush)
	#slice_and_dice,if=buff.slice_and_dice.remains<2|(buff.slice_and_dice.remains<15&buff.bandits_guile.stack=11&combo_points>=4)
	if { BuffRemaining(slice_and_dice_buff) < 2 or BuffRemaining(slice_and_dice_buff) < 15 and BuffStacks(bandits_guile_buff) == 11 and ComboPoints() >= 4 } and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
	#marked_for_death,if=combo_points<=1&dot.revealing_strike.ticking&(!talent.shadow_reflection.enabled|buff.shadow_reflection.up|cooldown.shadow_reflection.remains>30)
	if ComboPoints() <= 1 and target.DebuffPresent(revealing_strike_debuff) and { not Talent(shadow_reflection_talent) or BuffPresent(shadow_reflection_buff) or SpellCooldown(shadow_reflection) > 30 } Spell(marked_for_death)
	#call_action_list,name=generator,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<=4&buff.deep_insight.down)
	if ComboPoints() < 5 or Talent(anticipation_talent) and BuffStacks(anticipation_buff) <= 4 and BuffExpires(deep_insight_buff) CombatGeneratorActions()
	#call_action_list,name=finisher,if=combo_points=5&(buff.deep_insight.up|!talent.anticipation.enabled|(talent.anticipation.enabled&anticipation_charges>=4))
	if ComboPoints() == 5 and { BuffPresent(deep_insight_buff) or not Talent(anticipation_talent) or Talent(anticipation_talent) and BuffStacks(anticipation_buff) >= 4 } CombatFinisherActions()
}

AddFunction CombatGeneratorActions
{
	#revealing_strike,if=ticks_remain<2
	if target.TicksRemaining(revealing_strike_debuff) < 2 Spell(revealing_strike)
	#sinister_strike
	Spell(sinister_strike)
}

AddFunction CombatFinisherActions
{
	#crimson_tempest,if=active_enemies>7&dot.crimson_tempest_dot.ticks_remain<=1
	if Enemies() > 7 and target.TicksRemaining(crimson_tempest_dot_debuff) < 2 Spell(crimson_tempest)
	#eviscerate
	Spell(eviscerate)
}

AddIcon specialization=combat help=main enemies=1
{
	if not InCombat() CombatPrecombatActions()
	CombatDefaultActions()
}

AddIcon specialization=combat help=aoe
{
	if not InCombat() CombatPrecombatActions()
	CombatDefaultActions()
}

### Required symbols
# adrenaline_rush
# adrenaline_rush_buff
# ambush
# anticipation_buff
# anticipation_talent
# arcane_torrent_energy
# bandits_guile_buff
# berserking
# blade_flurry
# blade_flurry_buff
# blood_fury_ap
# cheap_shot
# crimson_tempest
# crimson_tempest_dot_debuff
# deadly_poison
# deadly_throw
# deep_insight_buff
# eviscerate
# kick
# kidney_shot
# killing_spree
# lethal_poison_buff
# marked_for_death
# marked_for_death_talent
# preparation
# quaking_palm
# revealing_strike
# revealing_strike_debuff
# shadow_focus_talent
# shadow_reflection
# shadow_reflection_buff
# shadow_reflection_talent
# shadowstep
# sinister_strike
# slice_and_dice
# slice_and_dice_buff
# stealth
# subterfuge_talent
# vanish
# vanish_buff
# virmens_bite_potion
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "reference")
end
