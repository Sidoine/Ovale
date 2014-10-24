local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Hunter_MM_T16M"
	local desc = "[6.0.2] SimulationCraft: Hunter_MM_T16M"
	local code = [[
# Based on SimulationCraft profile "Hunter_MM_T16M".
#	class=hunter
#	spec=marksmanship
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#YZ!...022.

Include(ovale_common)
Include(ovale_hunter_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
AddCheckBox(opt_trap_launcher SpellName(trap_launcher) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		Spell(counter_shot)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_focus)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

AddFunction SummonPet
{
	if not pet.Present() Texture(ability_hunter_beastcall help=L(summon_pet))
	if pet.IsDead() Spell(revive_pet)
}

AddFunction MarksmanshipDefaultActions
{
	#auto_shot
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#potion,name=virmens_bite,if=((buff.rapid_fire.up|buff.bloodlust.up)&(!talent.stampede.enabled|cooldown.stampede.remains<1))|target.time_to_die<=20
	if { BuffPresent(rapid_fire_buff) or BuffPresent(burst_haste_buff any=1) } and { not Talent(stampede_talent) or SpellCooldown(stampede) < 1 } or target.TimeToDie() <= 20 UsePotionAgility()
	#kill_shot,if=cast_regen+action.aimed_shot.cast_regen<focus.deficit
	if FocusCastingRegen(kill_shot) + FocusCastingRegen(aimed_shot) < FocusDeficit() Spell(kill_shot)
	#chimaera_shot
	Spell(chimaera_shot)
	#rapid_fire
	Spell(rapid_fire)
	#stampede,if=buff.rapid_fire.up|buff.bloodlust.up|target.time_to_die<=20
	if BuffPresent(rapid_fire_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 20 Spell(stampede)
	#call_action_list,name=careful_aim,if=buff.careful_aim.up
	if HealthPercent() > 80 or BuffPresent(rapid_fire_buff) MarksmanshipCarefulAimActions()
	#explosive_trap,if=active_enemies>2
	if Enemies() > 2 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
	#a_murder_of_crows
	Spell(a_murder_of_crows)
	#dire_beast,if=cast_regen+action.aimed_shot.cast_regen<focus.deficit
	if FocusCastingRegen(dire_beast) + FocusCastingRegen(aimed_shot) < FocusDeficit() Spell(dire_beast)
	#glaive_toss
	Spell(glaive_toss)
	#powershot,if=cast_regen<focus.deficit
	if FocusCastingRegen(powershot) < FocusDeficit() Spell(powershot)
	#barrage
	Spell(barrage)
	#steady_shot,if=focus.deficit*cast_time%(14+cast_regen)>cooldown.rapid_fire.remains
	if FocusDeficit() * CastTime(steady_shot) / { 14 + FocusCastingRegen(steady_shot) } > SpellCooldown(rapid_fire) Spell(steady_shot)
	#focusing_shot,if=focus.deficit*cast_time%(50+cast_regen)>cooldown.rapid_fire.remains&focus<100
	if FocusDeficit() * CastTime(focusing_shot_marksmanship) / { 50 + FocusCastingRegen(focusing_shot_marksmanship) } > SpellCooldown(rapid_fire) and Focus() < 100 Spell(focusing_shot_marksmanship)
	#steady_shot,if=buff.pre_steady_focus.up&(14+cast_regen+action.aimed_shot.cast_regen)<=focus.deficit
	if BuffPresent(pre_steady_focus_buff) and 14 + FocusCastingRegen(steady_shot) + FocusCastingRegen(aimed_shot) <= FocusDeficit() Spell(steady_shot)
	#aimed_shot,if=talent.focusing_shot.enabled
	if Talent(focusing_shot_talent) Spell(aimed_shot)
	#aimed_shot,if=focus+cast_regen>=85
	if Focus() + FocusCastingRegen(aimed_shot) >= 85 Spell(aimed_shot)
	#aimed_shot,if=buff.thrill_of_the_hunt.react&focus+cast_regen>=65
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() + FocusCastingRegen(aimed_shot) >= 65 Spell(aimed_shot)
	#focusing_shot,if=50+cast_regen-10<focus.deficit
	if 50 + FocusCastingRegen(focusing_shot_marksmanship) - 10 < FocusDeficit() Spell(focusing_shot_marksmanship)
	#steady_shot
	Spell(steady_shot)
}

AddFunction MarksmanshipCarefulAimActions
{
	#glaive_toss,if=active_enemies>4
	if Enemies() > 4 Spell(glaive_toss)
	#powershot,if=active_enemies>1&cast_regen<focus.deficit
	if Enemies() > 1 and FocusCastingRegen(powershot) < FocusDeficit() Spell(powershot)
	#barrage,if=active_enemies>1
	if Enemies() > 1 Spell(barrage)
	#aimed_shot
	Spell(aimed_shot)
	#focusing_shot,if=50+cast_regen<focus.deficit
	if 50 + FocusCastingRegen(focusing_shot_marksmanship) < FocusDeficit() Spell(focusing_shot_marksmanship)
	#steady_shot
	Spell(steady_shot)
}

AddFunction MarksmanshipPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#summon_pet
	SummonPet()
	#snapshot_stats
	#exotic_munitions,ammo_type=poisoned,if=active_enemies<3
	if Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(poisoned_ammo)
	#exotic_munitions,ammo_type=incendiary,if=active_enemies>=3
	if Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(incendiary_ammo)
	#potion,name=virmens_bite
	UsePotionAgility()
	#aimed_shot
	Spell(aimed_shot)
}

AddIcon specialization=marksmanship help=main enemies=1
{
	if not InCombat() MarksmanshipPrecombatActions()
	MarksmanshipDefaultActions()
}

AddIcon specialization=marksmanship help=aoe
{
	if not InCombat() MarksmanshipPrecombatActions()
	MarksmanshipDefaultActions()
}

### Required symbols
# a_murder_of_crows
# aimed_shot
# arcane_torrent_focus
# barrage
# berserking
# blood_fury_ap
# chimaera_shot
# counter_shot
# dire_beast
# exotic_munitions_buff
# explosive_trap
# focusing_shot_marksmanship
# focusing_shot_talent
# glaive_toss
# glyph_of_explosive_trap
# incendiary_ammo
# kill_shot
# poisoned_ammo
# powershot
# pre_steady_focus_buff
# quaking_palm
# rapid_fire
# rapid_fire_buff
# revive_pet
# stampede
# stampede_talent
# steady_shot
# thrill_of_the_hunt_buff
# trap_launcher
# virmens_bite_potion
# war_stomp
]]
	OvaleScripts:RegisterScript("HUNTER", name, desc, code, "reference")
end
