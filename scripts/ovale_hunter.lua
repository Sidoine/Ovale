local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_hunter"
	local desc = "[6.0.2] Ovale: Beast Mastery, Marksmanship, Survival"
	local code = [[
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

###
### Beast Mastery
###
# Based on SimulationCraft profile "Hunter_BM_T16M".
#	class=hunter
#	spec=beast_mastery
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ya!...122.

# ActionList: BeastMasteryDefaultActions --> main, shortcd, cd

AddFunction BeastMasteryDefaultActions
{
	#auto_shot
	#multishot,if=active_enemies>5|(active_enemies>1&pet.cat.buff.beast_cleave.down)
	if Enemies() > 5 or Enemies() > 1 and pet.BuffExpires(pet_beast_cleave_buff any=1) Spell(multishot)
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
	#cobra_shot,if=active_enemies>5
	if Enemies() > 5 Spell(cobra_shot)
	#arcane_shot,if=(buff.thrill_of_the_hunt.react&focus>35)|buff.bestial_wrath.up
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 or BuffPresent(bestial_wrath_buff) Spell(arcane_shot)
	#arcane_shot,if=focus>=64
	if Focus() >= 64 Spell(arcane_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction BeastMasteryDefaultShortCdActions
{
	#dire_beast
	Spell(dire_beast)
	#explosive_trap,if=active_enemies>2
	if Enemies() > 2 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
	#bestial_wrath,if=focus>60&!buff.bestial_wrath.up
	if Focus() > 60 and not BuffPresent(bestial_wrath_buff) Spell(bestial_wrath)
	#barrage,if=active_enemies>2
	if Enemies() > 2 Spell(barrage)

	unless Enemies() > 5 or Enemies() > 1 and pet.BuffExpires(pet_beast_cleave_buff any=1) and Spell(multishot)
	{
		#barrage,if=active_enemies>1
		if Enemies() > 1 Spell(barrage)
		#a_murder_of_crows
		Spell(a_murder_of_crows)

		unless TimeToMaxFocus() > GCD() and Spell(kill_shot)
			or pet.Present() and not pet.IsIncapacitated() and not pet.IsFeared() and not pet.IsStunned() and Spell(kill_command)
			or Focus() < 50 and Spell(focusing_shot)
			or BuffPresent(pre_steady_focus_buff) and 14 + FocusCastingRegen(cobra_shot) <= FocusDeficit() and Spell(cobra_shot)
			or Spell(glaive_toss)
		{
			#barrage
			Spell(barrage)
			#powershot,if=focus.time_to_max>cast_time
			if TimeToMaxFocus() > CastTime(powershot) Spell(powershot)

			unless Enemies() > 5 and Spell(cobra_shot)
				or { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 or BuffPresent(bestial_wrath_buff) } and Spell(arcane_shot)
			{
				#focus_fire,five_stacks=1
				if BuffStacks(frenzy_buff any=1) == 5 Spell(focus_fire)
			}
		}
	}
}

AddFunction BeastMasteryDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#potion,name=virmens_bite,if=!talent.stampede.enabled&buff.bestial_wrath.up|target.time_to_die<=20
	if not Talent(stampede_talent) and BuffPresent(bestial_wrath_buff) or target.TimeToDie() <= 20 UsePotionAgility()
	#potion,name=virmens_bite,if=talent.stampede.enabled&cooldown.stampede.remains<1&(buff.bloodlust.up|buff.focus_fire.up)|target.time_to_die<=20
	if Talent(stampede_talent) and SpellCooldown(stampede) < 1 and { BuffPresent(burst_haste_buff any=1) or BuffPresent(focus_fire_buff) } or target.TimeToDie() <= 20 UsePotionAgility()
	#stampede,if=buff.bloodlust.up|buff.focus_fire.up|target.time_to_die<=20
	if BuffPresent(burst_haste_buff any=1) or BuffPresent(focus_fire_buff) or target.TimeToDie() <= 20 Spell(stampede)
}

# ActionList: BeastMasteryPrecombatActions --> main, shortcd, cd

AddFunction BeastMasteryPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#snapshot_stats
	#exotic_munitions,ammo_type=poisoned,if=active_enemies<3
	if Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(poisoned_ammo)
	#exotic_munitions,ammo_type=incendiary,if=active_enemies>=3
	if Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(incendiary_ammo)
}

AddFunction BeastMasteryPrecombatShortCdActions
{
	#summon_pet
	SummonPet()
}

AddFunction BeastMasteryPrecombatCdActions
{
	unless not pet.Present() or pet.IsDead()
		or Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo)
		or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo)
	{
		#potion,name=virmens_bite
		UsePotionAgility()
	}
}

### Beast Mastery icons
AddCheckBox(opt_hunter_best_mastery "Show Beast Mastery icons" specialization=beast_mastery default)
AddCheckBox(opt_hunter_best_mastery_aoe L(AOE) specialization=beast_mastery default)

AddIcon specialization=beast_mastery help=shortcd enemies=1 checkbox=opt_hunter_best_mastery checkbox=!opt_hunter_best_mastery_aoe
{
	if InCombat(no) BeastMasteryPrecombatShortCdActions()
	BeastMasteryDefaultShortCdActions()
}

AddIcon specialization=beast_mastery help=shortcd checkbox=opt_hunter_best_mastery checkbox=opt_hunter_best_mastery_aoe
{
	if InCombat(no) BeastMasteryPrecombatShortCdActions()
	BeastMasteryDefaultShortCdActions()
}

AddIcon specialization=beast_mastery help=main enemies=1 checkbox=opt_hunter_best_mastery
{
	if InCombat(no) BeastMasteryPrecombatActions()
	BeastMasteryDefaultActions()
}

AddIcon specialization=beast_mastery help=aoe checkbox=opt_hunter_best_mastery checkbox=opt_hunter_best_mastery_aoe
{
	if InCombat(no) BeastMasteryPrecombatActions()
	BeastMasteryDefaultActions()
}

AddIcon specialization=beast_mastery help=cd enemies=1 checkbox=opt_hunter_best_mastery checkbox=!opt_hunter_best_mastery_aoe
{
	if InCombat(no) BeastMasteryPrecombatCdActions()
	BeastMasteryDefaultCdActions()
}

AddIcon specialization=beast_mastery help=cd checkbox=opt_hunter_best_mastery checkbox=opt_hunter_best_mastery_aoe
{
	if InCombat(no) BeastMasteryPrecombatCdActions()
	BeastMasteryDefaultCdActions()
}

###
### Marksmanship
###
# Based on SimulationCraft profile "Hunter_MM_T16M".
#	class=hunter
#	spec=marksmanship
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#YZ!...022.

# ActionList: MarksmanshipDefaultActions --> main, shortcd, cd

AddFunction MarksmanshipDefaultActions
{
	#auto_shot
	#kill_shot,if=cast_regen+action.aimed_shot.cast_regen<focus.deficit
	if FocusCastingRegen(kill_shot) + FocusCastingRegen(aimed_shot) < FocusDeficit() Spell(kill_shot)
	#chimaera_shot
	Spell(chimaera_shot)
	#run_action_list,name=careful_aim,if=buff.careful_aim.up
	if HealthPercent() > 80 or BuffPresent(rapid_fire_buff) MarksmanshipCarefulAimActions()
	#glaive_toss
	Spell(glaive_toss)
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

AddFunction MarksmanshipDefaultShortCdActions
{
	unless FocusCastingRegen(kill_shot) + FocusCastingRegen(aimed_shot) < FocusDeficit() and Spell(kill_shot)
		or Spell(chimaera_shot)
	{
		#run_action_list,name=careful_aim,if=buff.careful_aim.up
		if HealthPercent() > 80 or BuffPresent(rapid_fire_buff) MarksmanshipCarefulAimShortCdActions()
		#explosive_trap,if=active_enemies>2
		if Enemies() > 2 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
		#a_murder_of_crows
		Spell(a_murder_of_crows)
		#dire_beast,if=cast_regen+action.aimed_shot.cast_regen<focus.deficit
		if FocusCastingRegen(dire_beast) + FocusCastingRegen(aimed_shot) < FocusDeficit() Spell(dire_beast)

		unless Spell(glaive_toss)
		{
			#powershot,if=cast_regen<focus.deficit
			if FocusCastingRegen(powershot) < FocusDeficit() Spell(powershot)
			#barrage
			Spell(barrage)
		}
	}
}

AddFunction MarksmanshipDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#potion,name=virmens_bite,if=((buff.rapid_fire.up|buff.bloodlust.up)&(!talent.stampede.enabled|cooldown.stampede.remains<1))|target.time_to_die<=20
	if { BuffPresent(rapid_fire_buff) or BuffPresent(burst_haste_buff any=1) } and { not Talent(stampede_talent) or SpellCooldown(stampede) < 1 } or target.TimeToDie() <= 20 UsePotionAgility()

	unless FocusCastingRegen(kill_shot) + FocusCastingRegen(aimed_shot) < FocusDeficit() and Spell(kill_shot)
		or Spell(chimaera_shot)
	{
		#rapid_fire
		Spell(rapid_fire)
		#stampede,if=buff.rapid_fire.up|buff.bloodlust.up|target.time_to_die<=20
		if BuffPresent(rapid_fire_buff) or BuffPresent(burst_haste_buff any=1) or target.TimeToDie() <= 20 Spell(stampede)
		#run_action_list,name=careful_aim,if=buff.careful_aim.up
		if HealthPercent() > 80 or BuffPresent(rapid_fire_buff) MarksmanshipCarefulAimCdActions()
	}
}

# ActionList: MarksmanshipCarefulAimActions --> main, shortcd, cd

AddFunction MarksmanshipCarefulAimActions
{
	#glaive_toss,if=active_enemies>4
	if Enemies() > 4 Spell(glaive_toss)
	#aimed_shot
	Spell(aimed_shot)
	#focusing_shot,if=50+cast_regen<focus.deficit
	if 50 + FocusCastingRegen(focusing_shot_marksmanship) < FocusDeficit() Spell(focusing_shot_marksmanship)
	#steady_shot
	Spell(steady_shot)
}

AddFunction MarksmanshipCarefulAimShortCdActions
{
	unless Enemies() > 4 and Spell(glaive_toss)
	{
		#powershot,if=active_enemies>1&cast_regen<focus.deficit
		if Enemies() > 1 and FocusCastingRegen(powershot) < FocusDeficit() Spell(powershot)
		#barrage,if=active_enemies>1
		if Enemies() > 1 Spell(barrage)
	}
}

AddFunction MarksmanshipCarefulAimCdActions {}

# ActionList: MarksmanshipPrecombatActions --> main, shortcd, cd

AddFunction MarksmanshipPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#snapshot_stats
	#exotic_munitions,ammo_type=poisoned,if=active_enemies<3
	if Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(poisoned_ammo)
	#exotic_munitions,ammo_type=incendiary,if=active_enemies>=3
	if Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(incendiary_ammo)
	#aimed_shot
	Spell(aimed_shot)
}

AddFunction MarksmanshipPrecombatShortCdActions
{
	#summon_pet
	SummonPet()
}

AddFunction MarksmanshipPrecombatCdActions
{
	unless not pet.Present() or pet.IsDead()
		or Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo)
		or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo)
	{
		#potion,name=virmens_bite
		UsePotionAgility()
	}
}

### Marksmanship icons
AddCheckBox(opt_hunter_marksmanship "Show Marksmanship icons" specialization=marksmanship default)
AddCheckBox(opt_hunter_marksmanship_aoe L(AOE) specialization=marksmanship default)

AddIcon specialization=marksmanship help=shortcd enemies=1 checkbox=opt_hunter_marksmanship checkbox=!opt_hunter_marksmanship_aoe
{
	if InCombat(no) MarksmanshipPrecombatShortCdActions()
	MarksmanshipDefaultShortCdActions()
}

AddIcon specialization=marksmanship help=shortcd checkbox=opt_hunter_marksmanship checkbox=opt_hunter_marksmanship_aoe
{
	if InCombat(no) MarksmanshipPrecombatShortCdActions()
	MarksmanshipDefaultShortCdActions()
}

AddIcon specialization=marksmanship help=main enemies=1 checkbox=opt_hunter_marksmanship
{
	if InCombat(no) MarksmanshipPrecombatActions()
	MarksmanshipDefaultActions()
}

AddIcon specialization=marksmanship help=aoe checkbox=opt_hunter_marksmanship checkbox=opt_hunter_marksmanship_aoe
{
	if InCombat(no) MarksmanshipPrecombatActions()
	MarksmanshipDefaultActions()
}

AddIcon specialization=marksmanship help=cd enemies=1 checkbox=opt_hunter_marksmanship checkbox=!opt_hunter_marksmanship_aoe
{
	if InCombat(no) MarksmanshipPrecombatCdActions()
	MarksmanshipDefaultCdActions()
}

AddIcon specialization=marksmanship help=cd checkbox=opt_hunter_marksmanship checkbox=opt_hunter_marksmanship_aoe
{
	if InCombat(no) MarksmanshipPrecombatCdActions()
	MarksmanshipDefaultCdActions()
}

###
### Survival
###
# Based on SimulationCraft profile "Hunter_SV_T16M".
#	class=hunter
#	spec=survival
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Yb!...222.

# ActionList: SurvivalDefaultActions --> main, shortcd, cd

AddFunction SurvivalDefaultActions
{
	#auto_shot
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 SurvivalAoeActions()
	#explosive_shot
	Spell(explosive_shot)
	#black_arrow,if=!ticking
	if not target.DebuffPresent(black_arrow_debuff) Spell(black_arrow)
	#arcane_shot,if=buff.thrill_of_the_hunt.react&focus>35&cast_regen<=focus.deficit|dot.serpent_sting.remains<=5|target.time_to_die<4.5
	if BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 and FocusCastingRegen(arcane_shot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 Spell(arcane_shot)
	#glaive_toss
	Spell(glaive_toss)
	#cobra_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<5&(14+cast_regen)<=focus.deficit<80
	if BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 5 and 14 + FocusCastingRegen(cobra_shot) <= FocusDeficit() < 80 Spell(cobra_shot)
	#arcane_shot,if=focus>=70|talent.focusing_shot.enabled
	if Focus() >= 70 or Talent(focusing_shot_talent) Spell(arcane_shot)
	#focusing_shot
	Spell(focusing_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction SurvivalDefaultShortCdActions
{
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 SurvivalAoeShortCdActions()

	unless Spell(explosive_shot)
		or not target.DebuffPresent(black_arrow_debuff) and Spell(black_arrow)
	{
		#a_murder_of_crows
		Spell(a_murder_of_crows)
		#dire_beast
		Spell(dire_beast)

		unless { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 35 and FocusCastingRegen(arcane_shot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 } and Spell(arcane_shot)
			or Spell(glaive_toss)
		{
			#powershot
			Spell(powershot)
			#barrage
			Spell(barrage)
		}
	}
}

AddFunction SurvivalDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()
	#auto_shot
	#arcane_torrent,if=focus.deficit>=30
	if FocusDeficit() >= 30 Spell(arcane_torrent_focus)
	#blood_fury
	Spell(blood_fury_ap)
	#berserking
	Spell(berserking)
	#potion,name=virmens_bite,if=(((cooldown.stampede.remains<1|!talent.stampede.enabled)&(!talent.a_murder_of_crows.enabled|cooldown.a_murder_of_crows.remains<1))&(trinket.stat.any.up|buff.archmages_greater_incandescence_agi.up))|target.time_to_die<=20
	if { SpellCooldown(stampede) < 1 or not Talent(stampede_talent) } and { not Talent(a_murder_of_crows_talent) or SpellCooldown(a_murder_of_crows) < 1 } and { BuffPresent(trinket_stat_agility_buff) or BuffPresent(archmages_greater_incandescence_agi_buff) } or target.TimeToDie() <= 20 UsePotionAgility()
	#call_action_list,name=aoe,if=active_enemies>1
	if Enemies() > 1 SurvivalAoeCdActions()
	#stampede,if=buff.potion.up|(cooldown.potion.remains&(buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up))
	if BuffPresent(potion_agility_buff) or ItemCooldown(virmens_bite_potion) > 0 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_agility_buff) } Spell(stampede)
}

# ActionList: SurvivalAoeActions --> main, shortcd, cd

AddFunction SurvivalAoeActions
{
	# CHANGE: Barrage talent check missing.
	#explosive_shot,if=buff.lock_and_load.react&cooldown.barrage.remains>0
	#if BuffPresent(lock_and_load_buff) and SpellCooldown(barrage) > 0 Spell(explosive_shot)
	if BuffPresent(lock_and_load_buff) and { not Talent(barrage_talent) or SpellCooldown(barrage) > 0 } Spell(explosive_shot)
	#explosive_shot,if=active_enemies<5
	if Enemies() < 5 Spell(explosive_shot)
	#black_arrow,if=!ticking
	if not target.DebuffPresent(black_arrow_debuff) Spell(black_arrow)
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

		unless Enemies() < 5 and Spell(explosive_shot)
			or not target.DebuffPresent(black_arrow_debuff) and Spell(black_arrow)
		{
			#explosive_trap,if=dot.explosive_trap.remains<=5
			if target.DebuffRemaining(explosive_trap_debuff) <= 5 and CheckBoxOn(opt_trap_launcher) and not Glyph(glyph_of_explosive_trap) Spell(explosive_trap)
			#a_murder_of_crows
			Spell(a_murder_of_crows)
			#dire_beast
			Spell(dire_beast)

			unless { BuffPresent(thrill_of_the_hunt_buff) and Focus() > 50 and FocusCastingRegen(multishot) <= FocusDeficit() or target.DebuffRemaining(serpent_sting_debuff) <= 5 or target.TimeToDie() < 4.5 } and Spell(multishot)
				or Spell(glaive_toss)
			{
				#powershot
				Spell(powershot)
			}
		}
	}
}

AddFunction SurvivalAoeCdActions
{
	#stampede,if=buff.potion.up|(cooldown.potion.remains&(buff.archmages_greater_incandescence_agi.up|trinket.stat.any.up|buff.archmages_incandescence_agi.up))
	if BuffPresent(potion_agility_buff) or ItemCooldown(virmens_bite_potion) > 0 and { BuffPresent(archmages_greater_incandescence_agi_buff) or BuffPresent(trinket_stat_agility_buff) or BuffPresent(archmages_incandescence_agi_buff) } Spell(stampede)
}

# ActionList: SurvivalPrecombatActions --> main, shortcd, cd

AddFunction SurvivalPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#snapshot_stats
	#exotic_munitions,ammo_type=poisoned,if=active_enemies<3
	if Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(poisoned_ammo)
	#exotic_munitions,ammo_type=incendiary,if=active_enemies>=3
	if Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 Spell(incendiary_ammo)
}

AddFunction SurvivalPrecombatShortCdActions
{
	#summon_pet
	SummonPet()
}

AddFunction SurvivalPrecombatCdActions
{
	unless not pet.Present() or pet.IsDead()
		or Enemies() < 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(poisoned_ammo)
		or Enemies() >= 3 and BuffRemaining(exotic_munitions_buff) < 1200 and Spell(incendiary_ammo)
	{
		#potion,name=virmens_bite
		UsePotionAgility()
	}
}

### Survival icons
AddCheckBox(opt_hunter_survival "Show Survival icons" specialization=survival default)
AddCheckBox(opt_hunter_survival_aoe L(AOE) specialization=survival default)

AddIcon specialization=survival help=shortcd enemies=1 checkbox=opt_hunter_survival checkbox=!opt_hunter_survival_aoe
{
	if InCombat(no) SurvivalPrecombatShortCdActions()
	SurvivalDefaultShortCdActions()
}

AddIcon specialization=survival help=shortcd checkbox=opt_hunter_survival checkbox=opt_hunter_survival_aoe
{
	if InCombat(no) SurvivalPrecombatShortCdActions()
	SurvivalDefaultShortCdActions()
}

AddIcon specialization=survival help=main enemies=1 checkbox=opt_hunter_survival
{
	if InCombat(no) SurvivalPrecombatActions()
	SurvivalDefaultActions()
}

AddIcon specialization=survival help=aoe checkbox=opt_hunter_survival checkbox=opt_hunter_survival_aoe
{
	if InCombat(no) SurvivalPrecombatActions()
	SurvivalDefaultActions()
}

AddIcon specialization=survival help=cd enemies=1 checkbox=opt_hunter_survival checkbox=!opt_hunter_survival_aoe
{
	if InCombat(no) SurvivalPrecombatCdActions()
	SurvivalDefaultCdActions()
}

AddIcon specialization=survival help=cd checkbox=opt_hunter_survival checkbox=opt_hunter_survival_aoe
{
	if InCombat(no) SurvivalPrecombatCdActions()
	SurvivalDefaultCdActions()
}
]]

	OvaleScripts:RegisterScript("HUNTER", name, desc, code, "include")
	-- Register as the default Ovale script.
	OvaleScripts:RegisterScript("HUNTER", "Ovale", desc, code, "script")
end
