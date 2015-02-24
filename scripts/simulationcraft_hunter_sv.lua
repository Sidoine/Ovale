local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "simulationcraft_hunter_sv_t17m"
	local desc = "[6.1] SimulationCraft: Hunter_SV_T17M"
	local code = [[
# Based on SimulationCraft profile "Hunter_SV_T17M".
#	class=hunter
#	spec=survival
#	talents=0003313

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
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 SurvivalAoeMainActions()
	#black_arrow,if=!ticking
	if not target.DebuffPresent(black_arrow_debuff) Spell(black_arrow)
	#explosive_shot
	Spell(explosive_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react&focus>35&cast_regen<=focus.deficit|dot.serpent_sting.remains<=3|target.time_to_die<4.5
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 and FocusCastingRegen(arcane_shot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 3 or target.TimeToDie() < 4.5 Spell(arcane_shot)
	#cobra_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<5&(14+cast_regen)<=focus.deficit
	if BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 5 and 14 + FocusCastingRegen(cobra_shot) <= FocusDeficit() Spell(cobra_shot)
	#arcane_shot,if=focus>=80|talent.focusing_shot.enabled
	if Focus() >= 80 or Talent(focusing_shot_talent) Spell(arcane_shot)
	#focusing_shot
	Spell(focusing_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction SurvivalDefaultShortCdActions
{
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 SurvivalAoeShortCdActions()

	unless Enemies() > 1 and SurvivalAoeShortCdPostConditions()
	{
		#a_murder_of_crows
		Spell(a_murder_of_crows)

		unless not target.DebuffPresent(black_arrow_debuff) and Spell(black_arrow) or Spell(explosive_shot)
		{
			#dire_beast
			Spell(dire_beast)

			unless { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 and FocusCastingRegen(arcane_shot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 3 or target.TimeToDie() < 4.5 } and Spell(arcane_shot)
			{
				#explosive_trap
				if CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
			}
		}
	}
}

AddFunction SurvivalDefaultCdActions
{
	#auto_shot
	#counter_shot
	SurvivalInterruptActions()
	#use_item,name=beating_heart_of_the_mountain
	SurvivalUseItemActions()
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#potion,name=draenic_agility,if=(((cooldown.stampede.remains<1)&(cooldown.a_murder_of_crows.remains<1))&(trinket.stat.any.up|buff.archmages_greater_incandescence_agi.up))|target.time_to_die<=25
	if SpellCooldown(stampede) < 1 and SpellCooldown(a_murder_of_crows) < 1 and { BuffPresent(trinket_stat_any_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or target.TimeToDie() <= 25 SurvivalUsePotionAgility()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 SurvivalAoeCdActions()

	unless Enemies() > 1 and SurvivalAoeCdPostConditions()
	{
		#stampede,if=buff.potion.up|(cooldown.potion.remains&(buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up))|target.time_to_die<=25
		if BuffPresent(potion_agility_buff) or ItemCooldown(draenic_agility_potion) > 0 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) } or target.TimeToDie() <= 25 Spell(stampede)
	}
}

### actions.aoe

AddFunction SurvivalAoeMainActions
{
	#explosive_shot,if=buff.lock_and_load.react&(!talent.barrage.enabled|cooldown.barrage.remains>0)
	if BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } Spell(explosive_shot)
	#black_arrow,if=!ticking
	if not target.DebuffPresent(black_arrow_debuff) Spell(black_arrow)
	#explosive_shot,if=active_enemies<5
	if Enemies() < 5 Spell(explosive_shot)
	#multishot,if=buff.thrill_of_the_hunt.react&focus>50&cast_regen<=focus.deficit|dot.serpent_sting.remains<=5|target.time_to_die<4.5
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 50 and FocusCastingRegen(multishot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 Spell(multishot)
	#glaive_toss
	Spell(glaive_toss)
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
	unless BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } and Spell(explosive_shot)
	{
		#barrage
		Spell(barrage)

		unless not target.DebuffPresent(black_arrow_debuff) and Spell(black_arrow) or Enemies() < 5 and Spell(explosive_shot)
		{
			#explosive_trap,if=dot.explosive_trap.remains<=5
			if target.DebuffRemaining(explosive_trap_debuff) <= 5 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
			#a_murder_of_crows
			Spell(a_murder_of_crows)
			#dire_beast
			Spell(dire_beast)

			unless { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 50 and FocusCastingRegen(multishot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 } and Spell(multishot) or Spell(glaive_toss)
			{
				#powershot
				Spell(powershot)
			}
		}
	}
}

AddFunction SurvivalAoeShortCdPostConditions
{
	BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } and Spell(explosive_shot) or not target.DebuffPresent(black_arrow_debuff) and Spell(black_arrow) or Enemies() < 5 and Spell(explosive_shot) or { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 50 and FocusCastingRegen(multishot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 } and Spell(multishot) or Spell(glaive_toss) or BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 5 and Focus() + 14 + FocusCastingRegen(cobra_shot) < 80 and Spell(cobra_shot) or { Focus() >= 70 or Talent(focusing_shot_talent) } and Spell(multishot) or Spell(focusing_shot) or Spell(cobra_shot)
}

AddFunction SurvivalAoeCdActions
{
	#stampede,if=buff.potion.up|(cooldown.potion.remains&(buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up|buff.archmages_incandescence_agi.up))
	if BuffPresent(potion_agility_buff) or ItemCooldown(draenic_agility_potion) > 0 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_any_buff) or BuffPresent(archmages_incandescence_agi_buff) } Spell(stampede)
}

AddFunction SurvivalAoeCdPostConditions
{
	BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } and Spell(explosive_shot) or Spell(barrage) or not target.DebuffPresent(black_arrow_debuff) and Spell(black_arrow) or Enemies() < 5 and Spell(explosive_shot) or target.DebuffRemaining(explosive_trap_debuff) <= 5 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) and Spell(explosive_trap) or Spell(a_murder_of_crows) or Spell(dire_beast) or { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 50 and FocusCastingRegen(multishot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 } and Spell(multishot) or Spell(glaive_toss) or Spell(powershot) or BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 5 and Focus() + 14 + FocusCastingRegen(cobra_shot) < 80 and Spell(cobra_shot) or { Focus() >= 70 or Talent(focusing_shot_talent) } and Spell(multishot) or Spell(focusing_shot) or Spell(cobra_shot)
}

### actions.precombat

AddFunction SurvivalPrecombatMainActions
{
	#snapshot_stats
	#exotic_munitions,ammo_type=poisoned,if=active_enemies<3
	if Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(poisoned_ammo)
	#exotic_munitions,ammo_type=incendiary,if=active_enemies>=3
	if Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(incendiary_ammo)
	#glaive_toss
	Spell(glaive_toss)
	#focusing_shot,if=!talent.glaive_toss.enabled
	if not Talent(glaive_toss_talent) Spell(focusing_shot)
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
	Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo) or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo) or Spell(glaive_toss) or not Talent(glaive_toss_talent) and Spell(focusing_shot)
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
	Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo) or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo) or Spell(glaive_toss) or not Talent(glaive_toss_talent) and Spell(focusing_shot)
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
# glaive_toss_talent
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
# thrill_of_the_hunt_buff
# trap_launcher
# war_stomp
]]
	OvaleScripts:RegisterScript("HUNTER", "survival", name, desc, code, "script")
end
