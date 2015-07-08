local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_hunter_bm_t18m"
	local desc = "[6.2] SimulationCraft: Hunter_BM_T18M"
	local code = [[
# Based on SimulationCraft profile "Hunter_BM_T18M".
#	class=hunter
#	spec=beast_mastery
#	talents=0002333

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=beast_mastery)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=beast_mastery)
AddCheckBox(opt_trap_launcher SpellName(trap_launcher) default specialization=beast_mastery)

AddFunction BeastMasteryUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction BeastMasteryUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction BeastMasteryInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
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
	if pet.IsDead()
	{
		if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
		Spell(revive_pet)
	}
	if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
}

### actions.default

AddFunction BeastMasteryDefaultMainActions
{
	#multishot,if=spell_targets.multi_shot>1&pet.cat.buff.beast_cleave.remains<0.5
	if Enemies() > 1 and pet.BuffRemaining(pet_beast_cleave_buff) < 0.5 Spell(multishot)
	#multishot,if=spell_targets.multi_shot>5
	if Enemies() > 5 Spell(multishot)
	#kill_command
	if pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() Spell(kill_command)
	#kill_shot,if=focus.time_to_max>gcd
	if TimeToMaxFocus() > GCD() Spell(kill_shot)
	#focusing_shot,if=focus<50
	if Focus() < 50 Spell(focusing_shot)
	#cobra_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<7&(14+cast_regen)<focus.deficit
	if BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 7 and 14 + FocusCastingRegen(cobra_shot) < FocusDeficit() Spell(cobra_shot)
	#cobra_shot,if=talent.steady_focus.enabled&buff.steady_focus.remains<4&focus<50
	if Talent(steady_focus_talent) and BuffRemaining(steady_focus_buff) < 4 and Focus() < 50 Spell(cobra_shot)
	#glaive_toss
	Spell(glaive_toss)
	#cobra_shot,if=spell_targets.multi_shot>5
	if Enemies() > 5 Spell(cobra_shot)
	#arcane_shot,if=(buff.thrill_of_the_hunt.react&focus>35)|buff.bestial_wrath.up
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 or BuffPresent(bestial_wrath_buff) Spell(arcane_shot)
	#arcane_shot,if=focus>=75
	if Focus() >= 75 Spell(arcane_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction BeastMasteryDefaultShortCdActions
{
	#dire_beast
	Spell(dire_beast)
	#focus_fire,if=buff.focus_fire.down&((cooldown.bestial_wrath.remains<1&buff.bestial_wrath.down)|(talent.stampede.enabled&buff.stampede.remains)|pet.cat.buff.frenzy.remains<1)
	if BuffExpires(focus_fire_buff) and { SpellCooldown(bestial_wrath) < 1 and BuffExpires(bestial_wrath_buff) or Talent(stampede_talent) and TimeSincePreviousSpell(stampede) < 40 or pet.BuffRemaining(pet_frenzy_buff) < 1 } Spell(focus_fire)
	#bestial_wrath,if=focus>30&!buff.bestial_wrath.up
	if Focus() > 30 and not BuffPresent(bestial_wrath_buff) Spell(bestial_wrath)

	unless Enemies() > 1 and pet.BuffRemaining(pet_beast_cleave_buff) < 0.5 and Spell(multishot)
	{
		#focus_fire,min_frenzy=5
		if BuffStacks(frenzy_buff) >= 5 Spell(focus_fire)
		#barrage,if=spell_targets.barrage>1
		if Enemies() > 1 Spell(barrage)
		#explosive_trap,if=spell_targets.explosive_trap_tick>5
		if Enemies() > 5 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)

		unless Enemies() > 5 and Spell(multishot) or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command)
		{
			#a_murder_of_crows
			Spell(a_murder_of_crows)

			unless TimeToMaxFocus() > GCD() and Spell(kill_shot) or Focus() < 50 and Spell(focusing_shot) or BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 7 and 14 + FocusCastingRegen(cobra_shot) < FocusDeficit() and Spell(cobra_shot)
			{
				#explosive_trap,if=spell_targets.explosive_trap_tick>1
				if Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)

				unless Talent(steady_focus_talent) and BuffRemaining(steady_focus_buff) < 4 and Focus() < 50 and Spell(cobra_shot) or Spell(glaive_toss)
				{
					#barrage
					Spell(barrage)
					#powershot,if=focus.time_to_max>cast_time
					if TimeToMaxFocus() > CastTime(powershot) Spell(powershot)
				}
			}
		}
	}
}

AddFunction BeastMasteryDefaultCdActions
{
	#auto_shot
	#counter_shot
	BeastMasteryInterruptActions()
	#use_item,name=maalus_the_blood_drinker
	BeastMasteryUseItemActions()
	#use_item,name=mirror_of_the_blademaster
	BeastMasteryUseItemActions()
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#potion,name=draenic_agility,if=!talent.stampede.enabled&buff.bestial_wrath.up&target.health.pct<=20|target.time_to_die<=20
	if not Talent(stampede_talent) and BuffPresent(bestial_wrath_buff) and target.HealthPercent() <= 20 or target.TimeToDie() <= 20 BeastMasteryUsePotionAgility()
	#potion,name=draenic_agility,if=talent.stampede.enabled&cooldown.stampede.remains<1&(buff.bloodlust.up|buff.focus_fire.up)|target.time_to_die<=25
	if Talent(stampede_talent) and SpellCooldown(stampede) < 1 and { BuffPresent(burst_haste_buff any=1) or BuffPresent(focus_fire_buff) } or target.TimeToDie() <= 25 BeastMasteryUsePotionAgility()
	#stampede,if=buff.bloodlust.up|buff.focus_fire.up|target.time_to_die<=25
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(focus_fire_buff) or target.TimeToDie() <= 25 Spell(stampede)
}

### actions.precombat

AddFunction BeastMasteryPrecombatMainActions
{
	#snapshot_stats
	#exotic_munitions,ammo_type=poisoned,if=spell_targets.multi_shot<3
	if Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(poisoned_ammo)
	#exotic_munitions,ammo_type=incendiary,if=spell_targets.multi_shot>=3
	if Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(incendiary_ammo)
	#glaive_toss
	Spell(glaive_toss)
	#focusing_shot
	Spell(focusing_shot)
}

AddFunction BeastMasteryPrecombatShortCdActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=sleeper_sushi
	#summon_pet
	BeastMasterySummonPet()
}

AddFunction BeastMasteryPrecombatShortCdPostConditions
{
	Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo) or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo) or Spell(glaive_toss) or Spell(focusing_shot)
}

AddFunction BeastMasteryPrecombatCdActions
{
	unless Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo) or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo)
	{
		#potion,name=draenic_agility
		BeastMasteryUsePotionAgility()
	}
}

AddFunction BeastMasteryPrecombatCdPostConditions
{
	Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo) or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo) or Spell(glaive_toss) or Spell(focusing_shot)
}

### BeastMastery icons.

AddCheckBox(opt_hunter_beast_mastery_aoe L(AOE) default specialization=beast_mastery)

AddIcon checkbox=!opt_hunter_beast_mastery_aoe enemies=1 help=shortcd specialization=beast_mastery
{
	if not InCombat() BeastMasteryPrecombatShortCdActions()
	unless not InCombat() and BeastMasteryPrecombatShortCdPostConditions()
	{
		BeastMasteryDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=shortcd specialization=beast_mastery
{
	if not InCombat() BeastMasteryPrecombatShortCdActions()
	unless not InCombat() and BeastMasteryPrecombatShortCdPostConditions()
	{
		BeastMasteryDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=beast_mastery
{
	if not InCombat() BeastMasteryPrecombatMainActions()
	BeastMasteryDefaultMainActions()
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=aoe specialization=beast_mastery
{
	if not InCombat() BeastMasteryPrecombatMainActions()
	BeastMasteryDefaultMainActions()
}

AddIcon checkbox=!opt_hunter_beast_mastery_aoe enemies=1 help=cd specialization=beast_mastery
{
	if not InCombat() BeastMasteryPrecombatCdActions()
	unless not InCombat() and BeastMasteryPrecombatCdPostConditions()
	{
		BeastMasteryDefaultCdActions()
	}
}

AddIcon checkbox=opt_hunter_beast_mastery_aoe help=cd specialization=beast_mastery
{
	if not InCombat() BeastMasteryPrecombatCdActions()
	unless not InCombat() and BeastMasteryPrecombatCdPostConditions()
	{
		BeastMasteryDefaultCdActions()
	}
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
# pet_frenzy_buff
# poisoned_ammo
# powershot
# pre_steady_focus_buff
# quaking_palm
# revive_pet
# stampede
# stampede_talent
# steady_focus_buff
# steady_focus_talent
# thrill_of_the_hunt_buff
# trap_launcher
# war_stomp
]]
	OvaleScripts:RegisterScript("HUNTER", "beast_mastery", name, desc, code, "script")
end
