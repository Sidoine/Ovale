local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Hunter_BM_T17M"
	local desc = "[6.0] SimulationCraft: Hunter_BM_T17M"
	local code = [[
# Based on SimulationCraft profile "Hunter_BM_T17M".
#	class=hunter
#	spec=beast_mastery
#	talents=0002133

Include(ovale_common)
Include(ovale_hunter_spells)

AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default)
AddCheckBox(opt_trap_launcher SpellName(trap_launcher) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
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

AddFunction BeastMasterySummonPet
{
	if not pet.Present() Texture(ability_hunter_beastcall help=L(summon_pet))
	if pet.IsDead() Spell(revive_pet)
}

AddFunction BeastMasteryDefaultActions
{
	#auto_shot
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#potion,name=draenic_agility,if=!talent.stampede.enabled&buff.bestial_wrath.up&target.health.pct<=20|target.time_to_die<=20
	if not Talent(stampede_talent) and BuffPresent(bestial_wrath_buff) and target.HealthPercent() <= 20 or target.TimeToDie() <= 20 UsePotionAgility()
	#potion,name=draenic_agility,if=talent.stampede.enabled&cooldown.stampede.remains<1&(buff.bloodlust.up|buff.focus_fire.up)|target.time_to_die<=25
	if Talent(stampede_talent) and SpellCooldown(stampede) < 1 and { BuffPresent(burst_haste_buff any=1) or BuffPresent(focus_fire_buff) } or target.TimeToDie() <= 25 UsePotionAgility()
	#stampede,if=buff.bloodlust.up|buff.focus_fire.up|target.time_to_die<=25
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(focus_fire_buff) or target.TimeToDie() <= 25 Spell(stampede)
	#dire_beast
	Spell(dire_beast)
	#explosive_trap,if=active_enemies>1
	if Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
	#bestial_wrath,if=focus>60&!buff.bestial_wrath.up
	if Focus() > 60 and not BuffPresent(bestial_wrath_buff) Spell(bestial_wrath)
	#barrage,if=active_enemies>1
	if Enemies() > 1 Spell(barrage)
	#multishot,if=active_enemies>5|(active_enemies>1&pet.cat.buff.beast_cleave.down)
	if Enemies() > 5 or Enemies() > 1 and pet.BuffExpires(pet_beast_cleave_buff any=1) Spell(multishot)
	#focus_fire,five_stacks=1
	if BuffStacks(frenzy_buff any=1) == 5 Spell(focus_fire)
	#barrage,if=active_enemies>1
	if Enemies() > 1 Spell(barrage)
	#a_murder_of_crows
	Spell(a_murder_of_crows)
	#kill_shot,if=focus.time_to_max>gcd
	if TimeToMaxFocus() > GCD() Spell(kill_shot)
	#kill_command
	if pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() Spell(kill_command)
	#focusing_shot,if=focus<50
	if Focus() < 50 Spell(focusing_shot)
	#cobra_shot,if=buff.pre_steady_focus.up&(14+cast_regen)<=focus.deficit
	if BuffPresent(pre_steady_focus_buff) and 14 + FocusCastingRegen(cobra_shot) <= FocusDeficit() Spell(cobra_shot)
	#glaive_toss
	Spell(glaive_toss)
	#barrage
	Spell(barrage)
	#powershot,if=focus.time_to_max>cast_time
	if TimeToMaxFocus() > CastTime(powershot) Spell(powershot)
	#cobra_shot,if=active_enemies>5
	if Enemies() > 5 Spell(cobra_shot)
	#arcane_shot,if=(buff.thrill_of_the_hunt.react&focus>35)|buff.bestial_wrath.up
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 or BuffPresent(bestial_wrath_buff) Spell(arcane_shot)
	#arcane_shot,if=focus>=64
	if Focus() >= 64 Spell(arcane_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction BeastMasteryPrecombatActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=blackrock_barbecue
	#summon_pet
	BeastMasterySummonPet()
	#snapshot_stats
	#exotic_munitions,ammo_type=poisoned,if=active_enemies<3
	if Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(poisoned_ammo)
	#exotic_munitions,ammo_type=incendiary,if=active_enemies>=3
	if Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(incendiary_ammo)
	#potion,name=draenic_agility
	UsePotionAgility()
}

AddIcon specialization=beast_mastery help=main enemies=1
{
	if not InCombat() BeastMasteryPrecombatActions()
	BeastMasteryDefaultActions()
}

AddIcon specialization=beast_mastery help=aoe
{
	if not InCombat() BeastMasteryPrecombatActions()
	BeastMasteryDefaultActions()
}

### Required symbols
# a_murder_of_crows
# arcane_shot
# arcane_torrent_focus
# barrage
# berserking
# bestial_wrath
# bestial_wrath_buff
# blood_fury_ap
# cobra_shot
# counter_shot
# dire_beast
# draenic_agility_potion
# exotic_munitions_buff
# explosive_trap
# focus_fire
# focus_fire_buff
# focusing_shot
# frenzy_buff
# glaive_toss
# glyph_of_explosive_trap
# incendiary_ammo
# kill_command
# kill_shot
# multishot
# pet_beast_cleave_buff
# poisoned_ammo
# powershot
# pre_steady_focus_buff
# quaking_palm
# revive_pet
# stampede
# stampede_talent
# thrill_of_the_hunt_buff
# trap_launcher
# war_stomp
]]
	OvaleScripts:RegisterScript("HUNTER", name, desc, code, "reference")
end
