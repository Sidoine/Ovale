local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Hunter_SV_T16M"
	local desc = "[6.0] SimulationCraft: Hunter_SV_T16M"
	local code = [[
# Based on SimulationCraft profile "Hunter_SV_T16M".
#	class=hunter
#	spec=survival
#	talents=0003330

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

AddFunction SurvivalDefaultActions
{
	#auto_shot
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#potion,name=virmens_bite,if=(((cooldown.stampede.remains<1)&(cooldown.a_murder_of_crows.remains<1))&(trinket.stat.any.up|buff.archmages_greater_incandescence_agi.up))|target.time_to_die<=20
	if SpellCooldown(stampede) < 1 and SpellCooldown(a_murder_of_crows) < 1 and { BuffPresent(trinket_stat_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or target.TimeToDie() <= 20 UsePotionAgility()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 SurvivalAoeActions()
	#stampede,if=buff.potion.up|(cooldown.potion.remains&(buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up))
	if BuffPresent(potion_agility_buff) or ItemCooldown(virmens_bite_potion) > 0 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) } Spell(stampede)
	#explosive_shot
	Spell(explosive_shot)
	#black_arrow,if=!ticking
	if not target.DebuffPresent(black_arrow_debuff) Spell(black_arrow)
	#a_murder_of_crows
	Spell(a_murder_of_crows)
	#dire_beast
	Spell(dire_beast)
	#arcane_shot,if=buff.thrill_of_the_hunt.react&focus>35&cast_regen<=focus.deficit|dot.serpent_sting.remains<=5|target.time_to_die<4.5
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 and FocusCastingRegen(arcane_shot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 Spell(arcane_shot)
	#glaive_toss
	Spell(glaive_toss)
	#powershot
	Spell(powershot)
	#barrage
	Spell(barrage)
	#cobra_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<5&(14+cast_regen)<=focus.deficit<80
	if BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 5 and 14 + FocusCastingRegen(cobra_shot) <= FocusDeficit() < 80 Spell(cobra_shot)
	#arcane_shot,if=focus>=70|talent.focusing_shot.enabled
	if Focus() >= 70 or Talent(focusing_shot_talent) Spell(arcane_shot)
	#focusing_shot
	Spell(focusing_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction SurvivalAoeActions
{
	#stampede,if=buff.potion.up|(cooldown.potion.remains&(buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up|buff.archmages_incandescence_agi.up))
	if BuffPresent(potion_agility_buff) or ItemCooldown(virmens_bite_potion) > 0 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) or BuffPresent(archmages_incandescence_agi_buff) } Spell(stampede)
	#explosive_shot,if=buff.lock_and_load.react&(!talent.barrage.enabled|cooldown.barrage.remains>0)
	if BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } Spell(explosive_shot)
	#barrage
	Spell(barrage)
	#explosive_shot,if=active_enemies<5
	if Enemies() < 5 Spell(explosive_shot)
	#black_arrow,if=!ticking
	if not target.DebuffPresent(black_arrow_debuff) Spell(black_arrow)
	#explosive_trap,if=dot.explosive_trap.remains<=5
	if target.DebuffRemaining(explosive_trap_debuff) <= 5 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
	#a_murder_of_crows
	Spell(a_murder_of_crows)
	#dire_beast
	Spell(dire_beast)
	#multishot,if=buff.thrill_of_the_hunt.react&focus>50&cast_regen<=focus.deficit|dot.serpent_sting.remains<=5|target.time_to_die<4.5
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 50 and FocusCastingRegen(multishot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 Spell(multishot)
	#glaive_toss
	Spell(glaive_toss)
	#powershot
	Spell(powershot)
	#cobra_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<5&focus+14+cast_regen<80
	if BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 5 and Focus() + 14 + FocusCastingRegen(cobra_shot) < 80 Spell(cobra_shot)
	#multishot,if=focus>=70|talent.focusing_shot.enabled
	if Focus() >= 70 or Talent(focusing_shot_talent) Spell(multishot)
	#focusing_shot
	Spell(focusing_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction SurvivalPrecombatActions
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
}

AddIcon specialization=survival help=main enemies=1
{
	if not InCombat() SurvivalPrecombatActions()
	SurvivalDefaultActions()
}

AddIcon specialization=survival help=aoe
{
	if not InCombat() SurvivalPrecombatActions()
	SurvivalDefaultActions()
}

### Required symbols
# a_murder_of_crows
# arcane_shot
# arcane_torrent_focus
# archmages_greater_incandescence_agi_buff
# archmages_incandescence_agi_buff
# barrage
# barrage_talent
# berserking
# black_arrow
# black_arrow_debuff
# blood_fury_ap
# cobra_shot
# counter_shot
# dire_beast
# exotic_munitions_buff
# explosive_shot
# explosive_trap
# explosive_trap_debuff
# focusing_shot
# focusing_shot_talent
# glaive_toss
# glyph_of_explosive_trap
# incendiary_ammo
# lock_and_load_buff
# multishot
# poisoned_ammo
# potion_agility_buff
# powershot
# pre_steady_focus_buff
# quaking_palm
# revive_pet
# serpent_sting_debuff
# stampede
# steady_focus_buff
# thrill_of_the_hunt_buff
# trap_launcher
# virmens_bite_potion
# war_stomp
]]
	OvaleScripts:RegisterScript("HUNTER", name, desc, code, "reference")
end
