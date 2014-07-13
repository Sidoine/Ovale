local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Rogue_Combat_T16H"
	local desc = "[5.4] SimulationCraft: Rogue_Combat_T16H" 
	local code = [[
# Based on SimulationCraft profile "Rogue_Combat_T16H".
#	class=rogue
#	spec=combat
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#cZ!200002

Include(ovale_common)
Include(ovale_rogue_common)

AddFunction CombatFinisherActions
{
	#rupture,if=ticks_remain<2&target.time_to_die>=26&(active_enemies<2|!buff.blade_flurry.up)
	if target.TicksRemain(rupture_debuff) < 2 and target.TimeToDie() >= 26 and { Enemies() < 2 or not BuffPresent(blade_flurry_buff) } Spell(rupture)
	#crimson_tempest,if=active_enemies>=7&dot.crimson_tempest_dot.ticks_remain<=2
	if Enemies() >= 7 and target.TicksRemain(crimson_tempest_dot_debuff) <= 2 Spell(crimson_tempest)
	#eviscerate
	Spell(eviscerate)
}

AddFunction CombatGeneratorActions
{
	#fan_of_knives,line_cd=5,if=active_enemies>=4
	if Enemies() >= 4 Spell(fan_of_knives)
	#revealing_strike,if=ticks_remain<2
	if target.TicksRemain(revealing_strike_debuff) < 2 Spell(revealing_strike)
	#sinister_strike
	Spell(sinister_strike)
}

AddFunction CombatDefaultActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#auto_attack
	#kick
	if target.IsInterruptible() Spell(kick)
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
	#use_item,slot=hands,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) UseItemActions()
	#blood_fury,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) Spell(blood_fury)
	#berserking,if=time=0|buff.shadow_blades.up
	if TimeInCombat() == 0 or BuffPresent(shadow_blades_buff) Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#blade_flurry,if=(active_enemies>=2&!buff.blade_flurry.up)|(active_enemies<2&buff.blade_flurry.up)
	if { Enemies() >= 2 and not BuffPresent(blade_flurry_buff) } or { Enemies() < 2 and BuffPresent(blade_flurry_buff) } Spell(blade_flurry)
	#ambush
	Spell(ambush usable=1)
	#vanish,if=time>10&(combo_points<3|(talent.anticipation.enabled&anticipation_charges<3)|(buff.shadow_blades.down&(combo_points<4|(talent.anticipation.enabled&anticipation_charges<4))))&((talent.shadow_focus.enabled&buff.adrenaline_rush.down&energy<20)|(talent.subterfuge.enabled&energy>=90)|(!talent.shadow_focus.enabled&!talent.subterfuge.enabled&energy>=60))
	if TimeInCombat() > 10 and { ComboPoints() < 3 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 3 } or { BuffExpires(shadow_blades_buff) and { ComboPoints() < 4 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) < 4 } } } } and { { TalentPoints(shadow_focus_talent) and BuffExpires(adrenaline_rush_buff) and Energy() < 20 } or { TalentPoints(subterfuge_talent) and Energy() >= 90 } or { not TalentPoints(shadow_focus_talent) and not TalentPoints(subterfuge_talent) and Energy() >= 60 } } Spell(vanish)
	#shadow_blades,if=time>5
	if TimeInCombat() > 5 Spell(shadow_blades)
	#killing_spree,if=energy<45
	if Energy() < 45 Spell(killing_spree)
	#adrenaline_rush,if=energy<35|buff.shadow_blades.up
	if Energy() < 35 or BuffPresent(shadow_blades_buff) Spell(adrenaline_rush)
	#slice_and_dice,if=buff.slice_and_dice.remains<2|(buff.slice_and_dice.remains<15&buff.bandits_guile.stack=11&combo_points>=4)
	if BuffRemains(slice_and_dice_buff) < 2 or { BuffRemains(slice_and_dice_buff) < 15 and BuffStacks(bandits_guile_buff) == 11 and ComboPoints() >= 4 } Spell(slice_and_dice)
	#marked_for_death,if=talent.marked_for_death.enabled&(combo_points<=1&dot.revealing_strike.ticking)
	if TalentPoints(marked_for_death_talent) and { ComboPoints() <= 1 and target.DebuffPresent(revealing_strike_debuff) } Spell(marked_for_death)
	#run_action_list,name=generator,if=combo_points<5|(talent.anticipation.enabled&anticipation_charges<=4&!dot.revealing_strike.ticking)
	if ComboPoints() < 5 or { TalentPoints(anticipation_talent) and BuffStacks(anticipation_buff) <= 4 and not target.DebuffPresent(revealing_strike_debuff) } CombatGeneratorActions()
	#run_action_list,name=finisher,if=!talent.anticipation.enabled|buff.deep_insight.up|cooldown.shadow_blades.remains<=11|anticipation_charges>=4|(buff.shadow_blades.up&anticipation_charges>=3)
	if not TalentPoints(anticipation_talent) or BuffPresent(deep_insight_buff) or SpellCooldown(shadow_blades) <= 11 or BuffStacks(anticipation_buff) >= 4 or { BuffPresent(shadow_blades_buff) and BuffStacks(anticipation_buff) >= 3 } CombatFinisherActions()
	#run_action_list,name=generator,if=energy>60|buff.deep_insight.down|buff.deep_insight.remains>5-combo_points
	if Energy() > 60 or BuffExpires(deep_insight_buff) or BuffRemains(deep_insight_buff) > 5 - ComboPoints() CombatGeneratorActions()
}

AddFunction CombatPrecombatActions
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
	#marked_for_death,if=talent.marked_for_death.enabled
	if TalentPoints(marked_for_death_talent) Spell(marked_for_death)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if TalentPoints(marked_for_death_talent) Spell(slice_and_dice)
}

AddIcon specialization=combat help=main
{
	if InCombat(no) CombatPrecombatActions()
	CombatDefaultActions()
}

### Required symbols
# adrenaline_rush
# adrenaline_rush_buff
# ambush
# anticipation_buff
# anticipation_talent
# apply_poison
# arcane_torrent_energy
# bandits_guile_buff
# berserking
# blade_flurry
# blade_flurry_buff
# blood_fury
# crimson_tempest
# crimson_tempest_dot_debuff
# deep_insight_buff
# eviscerate
# fan_of_knives
# kick
# killing_spree
# marked_for_death
# marked_for_death_talent
# preparation
# revealing_strike
# revealing_strike_debuff
# rupture
# rupture_debuff
# shadow_blades
# shadow_blades_buff
# shadow_focus_talent
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
