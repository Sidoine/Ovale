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

Include(ovale_common)
Include(ovale_rogue_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
AddCheckBox(opt_tricks_of_the_trade SpellName(tricks_of_the_trade) default)

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

AddFunction AssassinationPrecombatActions
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
	#marked_for_death,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) Spell(marked_for_death)
	#slice_and_dice,if=talent.marked_for_death.enabled
	if Talent(marked_for_death_talent) and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
}

AddFunction AssassinationDefaultActions
{
	#virmens_bite_potion,if=buff.bloodlust.react|target.time_to_die<40
	if BuffPresent(burst_haste_buff any=1) or target.TimeToDie() < 40 UsePotionAgility()
	#auto_attack
	#kick
	InterruptActions()
	#preparation,if=!buff.vanish.up&cooldown.vanish.remains>60
	if not BuffPresent(vanish_buff) and SpellCooldown(vanish) > 60 Spell(preparation)
	#use_item,slot=hands
	UseItemActions()
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#arcane_torrent,if=energy<60
	if Energy() < 60 Spell(arcane_torrent_energy)
	#vanish,if=time>10&!buff.stealth.up&!buff.shadow_blades.up
	if TimeInCombat() > 10 and not BuffPresent(stealthed_buff any=1) and not BuffPresent(shadow_blades_buff) Spell(vanish)
	#mutilate,if=buff.stealth.up
	if BuffPresent(stealthed_buff any=1) Spell(mutilate)
	#shadow_blades,if=buff.bloodlust.react|time>60
	if BuffPresent(burst_haste_buff any=1) or TimeInCombat() > 60 Spell(shadow_blades)
	#slice_and_dice,if=buff.slice_and_dice.remains<2
	if BuffRemaining(slice_and_dice_buff) < 2 and BuffDurationIfApplied(slice_and_dice_buff) > BuffRemaining(slice_and_dice_buff) Spell(slice_and_dice)
	#dispatch,if=dot.rupture.ticks_remain<2&energy>90
	if target.TicksRemaining(rupture_debuff) < 2 and Energy() > 90 and { target.HealthPercent() < 35 or BuffPresent(blindside_buff) } Spell(dispatch)
	#mutilate,if=dot.rupture.ticks_remain<2&energy>90
	if target.TicksRemaining(rupture_debuff) < 2 and Energy() > 90 Spell(mutilate)
	#marked_for_death,if=talent.marked_for_death.enabled&combo_points=0
	if Talent(marked_for_death_talent) and ComboPoints() == 0 Spell(marked_for_death)
	#rupture,if=ticks_remain<2|(combo_points=5&ticks_remain<3)
	if target.TicksRemaining(rupture_debuff) < 2 or ComboPoints() == 5 and target.TicksRemaining(rupture_debuff) < 3 Spell(rupture)
	#fan_of_knives,if=combo_points<5&active_enemies>=4
	if ComboPoints() < 5 and Enemies() >= 4 Spell(fan_of_knives)
	#vendetta
	Spell(vendetta)
	#envenom,if=combo_points>4
	if ComboPoints() > 4 Spell(envenom)
	#envenom,if=combo_points>=2&buff.slice_and_dice.remains<3
	if ComboPoints() >= 2 and BuffRemaining(slice_and_dice_buff) < 3 Spell(envenom)
	#dispatch,if=combo_points<5
	if ComboPoints() < 5 and { target.HealthPercent() < 35 or BuffPresent(blindside_buff) } Spell(dispatch)
	#mutilate
	Spell(mutilate)
	#tricks_of_the_trade
	if CheckBoxOn(opt_tricks_of_the_trade) and Glyph(glyph_of_tricks_of_the_trade no) Spell(tricks_of_the_trade)
}

AddIcon specialization=assassination help=main enemies=1
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultActions()
}

AddIcon specialization=assassination help=aoe
{
	if InCombat(no) AssassinationPrecombatActions()
	AssassinationDefaultActions()
}

### Required symbols
# arcane_torrent_energy
# berserking
# blindside_buff
# blood_fury_ap
# cheap_shot
# deadly_poison
# dispatch
# envenom
# fan_of_knives
# glyph_of_tricks_of_the_trade
# kick
# kidney_shot
# lethal_poison_buff
# marked_for_death
# marked_for_death_talent
# mutilate
# preparation
# quaking_palm
# rupture
# rupture_debuff
# shadow_blades
# shadow_blades_buff
# slice_and_dice
# slice_and_dice_buff
# stealth
# stealth_subterfuge
# subterfuge_talent
# tricks_of_the_trade
# vanish
# vanish_buff
# vendetta
# virmens_bite_potion
]]
	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "reference")
end
