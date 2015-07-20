local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_hunter_sv_t18m"
	local desc = "[6.2] SimulationCraft: Hunter_SV_T18M"
	local code = [[
# Based on SimulationCraft profile "Hunter_SV_T18M".
#	class=hunter
#	spec=survival
#	talents=0001333

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_hunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=survival)
AddCheckBox(opt_potion_agility ItemName(draenic_agility_potion) default specialization=survival)
AddCheckBox(opt_trap_launcher SpellName(trap_launcher) default specialization=survival)

AddFunction SurvivalUsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(draenic_agility_potion usable=1)
}

AddFunction SurvivalUseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction SurvivalInterruptActions
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

AddFunction SurvivalSummonPet
{
	if not Talent(lone_wolf_talent)
	{
		if pet.IsDead()
		{
			if not DebuffPresent(heart_of_the_phoenix_debuff) Spell(heart_of_the_phoenix)
			Spell(revive_pet)
		}
		if not pet.Present() and not pet.IsDead() and not PreviousSpell(revive_pet) Texture(ability_hunter_beastcall help=L(summon_pet))
	}
}

### actions.default

AddFunction SurvivalDefaultMainActions
{
	#call_action_list,name=aoe,if=spell_targets.multi_shot>1
	if Enemies() > 1 SurvivalAoeMainActions()
	#black_arrow,cycle_targets=1,if=remains<gcd*1.5
	if target.DebuffRemaining(black_arrow_debuff) < GCD() * 1.5 Spell(black_arrow)
	#arcane_shot,if=(trinket.proc.any.react&trinket.proc.any.remains<4)|dot.serpent_sting.remains<=3
	if BuffPresent(trinket_proc_any_buff) and BuffRemaining(trinket_proc_any_buff) < 4 or target.DebuffRemaining(serpent_sting_debuff) <= 3 Spell(arcane_shot)
	#explosive_shot
	Spell(explosive_shot)
	#cobra_shot,if=buff.pre_steady_focus.up
	if BuffPresent(pre_steady_focus_buff) Spell(cobra_shot)
	#arcane_shot,if=(buff.thrill_of_the_hunt.react&focus>35)|target.time_to_die<4.5
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 or target.TimeToDie() < 4.5 Spell(arcane_shot)
	#glaive_toss
	Spell(glaive_toss)
	#powershot
	Spell(powershot)
	#barrage
	Spell(barrage)
	#arcane_shot,if=talent.steady_focus.enabled&!talent.focusing_shot.enabled&focus.deficit<action.cobra_shot.cast_regen*2+28
	if Talent(steady_focus_talent) and not Talent(focusing_shot_talent) and FocusDeficit() < FocusCastingRegen(cobra_shot) * 2 + 28 Spell(arcane_shot)
	#cobra_shot,if=talent.steady_focus.enabled&buff.steady_focus.remains<5
	if Talent(steady_focus_talent) and BuffRemaining(steady_focus_buff) < 5 Spell(cobra_shot)
	#focusing_shot,if=talent.steady_focus.enabled&buff.steady_focus.remains<=cast_time&focus.deficit>cast_regen
	if Talent(steady_focus_talent) and BuffRemaining(steady_focus_buff) <= CastTime(focusing_shot) and FocusDeficit() > FocusCastingRegen(focusing_shot) Spell(focusing_shot)
	#arcane_shot,if=focus>=70|talent.focusing_shot.enabled|(talent.steady_focus.enabled&focus>=50)
	if Focus() >= 70 or Talent(focusing_shot_talent) or Talent(steady_focus_talent) and Focus() >= 50 Spell(arcane_shot)
	#focusing_shot
	Spell(focusing_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction SurvivalDefaultShortCdActions
{
	#call_action_list,name=aoe,if=spell_targets.multi_shot>1
	if Enemies() > 1 SurvivalAoeShortCdActions()

	unless Enemies() > 1 and SurvivalAoeShortCdPostConditions()
	{
		#a_murder_of_crows
		Spell(a_murder_of_crows)

		unless target.DebuffRemaining(black_arrow_debuff) < GCD() * 1.5 and Spell(black_arrow) or { BuffPresent(trinket_proc_any_buff) and BuffRemaining(trinket_proc_any_buff) < 4 or target.DebuffRemaining(serpent_sting_debuff) <= 3 } and Spell(arcane_shot) or Spell(explosive_shot) or BuffPresent(pre_steady_focus_buff) and Spell(cobra_shot)
		{
			#dire_beast
			Spell(dire_beast)

			unless { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 or target.TimeToDie() < 4.5 } and Spell(arcane_shot) or Spell(glaive_toss) or Spell(powershot) or Spell(barrage)
			{
				#explosive_trap,if=!trinket.proc.any.react&!trinket.stacking_proc.any.react
				if not BuffPresent(trinket_proc_any_buff) and not BuffPresent(trinket_stacking_proc_any_buff) and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
			}
		}
	}
}

AddFunction SurvivalDefaultCdActions
{
	#auto_shot
	#counter_shot
	SurvivalInterruptActions()
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#use_item,name=maalus_the_blood_drinker
	SurvivalUseItemActions()
	#use_item,name=beating_heart_of_the_mountain
	SurvivalUseItemActions()
	#potion,name=draenic_agility,if=(((cooldown.stampede.remains<1)&(cooldown.a_murder_of_crows.remains<1))&(trinket.stat.any.up|buff.archmages_greater_incandescence_agi.up))|target.time_to_die<=25
	if SpellCooldown(stampede) < 1 and SpellCooldown(a_murder_of_crows) < 1 and { BuffPresent(trinket_stat_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or target.TimeToDie() <= 25 SurvivalUsePotionAgility()
	#call_action_list,name=aoe,if=spell_targets.multi_shot>1
	if Enemies() > 1 SurvivalAoeCdActions()

	unless Enemies() > 1 and SurvivalAoeCdPostConditions() or Spell(a_murder_of_crows)
	{
		#stampede,if=buff.potion.up|(cooldown.potion.remains&(buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up))|target.time_to_die<=45
		if BuffPresent(potion_agility_buff) or ItemCooldown(draenic_agility_potion) > 0 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) } or target.TimeToDie() <= 45 Spell(stampede)
	}
}

### actions.aoe

AddFunction SurvivalAoeMainActions
{
	#explosive_shot,if=buff.lock_and_load.react&(!talent.barrage.enabled|cooldown.barrage.remains>0)
	if BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } Spell(explosive_shot)
	#barrage
	Spell(barrage)
	#black_arrow,cycle_targets=1,if=remains<gcd*1.5
	if target.DebuffRemaining(black_arrow_debuff) < GCD() * 1.5 Spell(black_arrow)
	#explosive_shot,if=spell_targets.multi_shot<5
	if Enemies() < 5 Spell(explosive_shot)
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

AddFunction SurvivalAoeShortCdActions
{
	unless BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } and Spell(explosive_shot) or Spell(barrage) or target.DebuffRemaining(black_arrow_debuff) < GCD() * 1.5 and Spell(black_arrow) or Enemies() < 5 and Spell(explosive_shot)
	{
		#explosive_trap,if=dot.explosive_trap.remains<=5
		if target.DebuffRemaining(explosive_trap_debuff) <= 5 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
		#a_murder_of_crows
		Spell(a_murder_of_crows)
		#dire_beast
		Spell(dire_beast)
	}
}

AddFunction SurvivalAoeShortCdPostConditions
{
	BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } and Spell(explosive_shot) or Spell(barrage) or target.DebuffRemaining(black_arrow_debuff) < GCD() * 1.5 and Spell(black_arrow) or Enemies() < 5 and Spell(explosive_shot) or { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 50 and FocusCastingRegen(multishot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 } and Spell(multishot) or Spell(glaive_toss) or Spell(powershot) or BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 5 and Focus() + 14 + FocusCastingRegen(cobra_shot) < 80 and Spell(cobra_shot) or { Focus() >= 70 or Talent(focusing_shot_talent) } and Spell(multishot) or Spell(focusing_shot) or Spell(cobra_shot)
}

AddFunction SurvivalAoeCdActions
{
	#stampede,if=buff.potion.up|(cooldown.potion.remains&(buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up|buff.archmages_incandescence_agi.up))
	if BuffPresent(potion_agility_buff) or ItemCooldown(draenic_agility_potion) > 0 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) or BuffPresent(archmages_incandescence_agi_buff) } Spell(stampede)
}

AddFunction SurvivalAoeCdPostConditions
{
	BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } and Spell(explosive_shot) or Spell(barrage) or target.DebuffRemaining(black_arrow_debuff) < GCD() * 1.5 and Spell(black_arrow) or Enemies() < 5 and Spell(explosive_shot) or target.DebuffRemaining(explosive_trap_debuff) <= 5 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) and Spell(explosive_trap) or Spell(a_murder_of_crows) or Spell(dire_beast) or { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 50 and FocusCastingRegen(multishot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 } and Spell(multishot) or Spell(glaive_toss) or Spell(powershot) or BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 5 and Focus() + 14 + FocusCastingRegen(cobra_shot) < 80 and Spell(cobra_shot) or { Focus() >= 70 or Talent(focusing_shot_talent) } and Spell(multishot) or Spell(focusing_shot) or Spell(cobra_shot)
}

### actions.precombat

AddFunction SurvivalPrecombatMainActions
{
	#snapshot_stats
	#exotic_munitions,ammo_type=poisoned,if=spell_targets.multi_shot<3
	if Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(poisoned_ammo)
	#exotic_munitions,ammo_type=incendiary,if=spell_targets.multi_shot>=3
	if Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(incendiary_ammo)
	#glaive_toss
	Spell(glaive_toss)
	#explosive_shot
	Spell(explosive_shot)
	#focusing_shot
	Spell(focusing_shot)
}

AddFunction SurvivalPrecombatShortCdActions
{
	#flask,type=greater_draenic_agility_flask
	#food,type=salty_squid_roll
	#summon_pet
	SurvivalSummonPet()
}

AddFunction SurvivalPrecombatShortCdPostConditions
{
	Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo) or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo) or Spell(glaive_toss) or Spell(explosive_shot) or Spell(focusing_shot)
}

AddFunction SurvivalPrecombatCdActions
{
	unless Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo) or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo)
	{
		#potion,name=draenic_agility
		SurvivalUsePotionAgility()
	}
}

AddFunction SurvivalPrecombatCdPostConditions
{
	Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo) or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo) or Spell(glaive_toss) or Spell(explosive_shot) or Spell(focusing_shot)
}

### Survival icons.

AddCheckBox(opt_hunter_survival_aoe L(AOE) default specialization=survival)

AddIcon checkbox=!opt_hunter_survival_aoe enemies=1 help=shortcd specialization=survival
{
	if not InCombat() SurvivalPrecombatShortCdActions()
	unless not InCombat() and SurvivalPrecombatShortCdPostConditions()
	{
		SurvivalDefaultShortCdActions()
	}
}

AddIcon checkbox=opt_hunter_survival_aoe help=shortcd specialization=survival
{
	if not InCombat() SurvivalPrecombatShortCdActions()
	unless not InCombat() and SurvivalPrecombatShortCdPostConditions()
	{
		SurvivalDefaultShortCdActions()
	}
}

AddIcon enemies=1 help=main specialization=survival
{
	if not InCombat() SurvivalPrecombatMainActions()
	SurvivalDefaultMainActions()
}

AddIcon checkbox=opt_hunter_survival_aoe help=aoe specialization=survival
{
	if not InCombat() SurvivalPrecombatMainActions()
	SurvivalDefaultMainActions()
}

AddIcon checkbox=!opt_hunter_survival_aoe enemies=1 help=cd specialization=survival
{
	if not InCombat() SurvivalPrecombatCdActions()
	unless not InCombat() and SurvivalPrecombatCdPostConditions()
	{
		SurvivalDefaultCdActions()
	}
}

AddIcon checkbox=opt_hunter_survival_aoe help=cd specialization=survival
{
	if not InCombat() SurvivalPrecombatCdActions()
	unless not InCombat() and SurvivalPrecombatCdPostConditions()
	{
		SurvivalDefaultCdActions()
	}
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
# draenic_agility_potion
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
# lone_wolf_talent
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
# steady_focus_talent
# thrill_of_the_hunt_buff
# trap_launcher
# war_stomp
]]
	OvaleScripts:RegisterScript("HUNTER", "survival", name, desc, code, "script")
end
