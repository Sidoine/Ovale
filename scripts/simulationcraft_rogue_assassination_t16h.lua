local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Rogue_Assassination_T16H"
	local desc = "[5.4] SimulationCraft: Rogue_Assassination_T16H" 
	local code = [[
# Based on SimulationCraft profile "Rogue_Assassination_T16H".
#	class=rogue
#	spec=assassination
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#ca!200002
#	glyphs=vendetta

Include(ovale_items)
Include(ovale_racials)
Include(ovale_rogue_spells)

AddFunction AssassinationDefaultActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#auto_attack
	#kick
	if target.IsInterruptible() Spell(kick)
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
	#use_item,slot=hands
	UseItemActions()
	#blood_fury
	Spell(blood_fury)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#vanish,if=time>10&!buff.stealth.up&!buff.shadow_blades.up
	if TimeInCombat() > 10 and not Stealthed() and not BuffPresent(shadow_blades_buff) Spell(vanish)
	#mutilate,if=buff.stealth.up
	if Stealthed() Spell(mutilate)
	#shadow_blades,if=buff.bloodlust.react|time>60
	if BuffPresent(burst_haste any=1) or TimeInCombat() > 60 Spell(shadow_blades)
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
	if ComboPoints() < 5 and Enemies() >= 4 Spell(fan_of_knives)
	#vendetta
	Spell(vendetta)
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

AddFunction AssassinationPrecombatActions
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

AddIcon mastery=assassination help=main
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultActions()
}

### Required symbols
# apply_poison
# arcane_torrent_energy
# berserking
# blood_fury
# dispatch
# envenom
# fan_of_knives
# kick
# marked_for_death
# marked_for_death_talent
# mutilate
# preparation
# rupture
# rupture_debuff
# shadow_blades
# shadow_blades_buff
# slice_and_dice
# slice_and_dice_buff
# stealth
# tricks_of_the_trade
# vanish
# vanish_buff
# vendetta
# virmens_bite_potion
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "reference")
end