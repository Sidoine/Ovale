local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_hunter"
	local desc = "[5.4.8] Ovale: Beast Mastery, Marksmanship, Survival"
	local code = [[
# Ovale hunter script based on SimulationCraft.

Include(ovale_common)
Include(ovale_hunter_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
AddCheckBox(opt_trap_launcher SpellName(trap_launcher) default)

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

AddFunction AspectOfTheHawk
{
	if Talent(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_iron_hawk) Spell(aspect_of_the_iron_hawk)
	if Talent(aspect_of_the_iron_hawk_talent no) and not Stance(hunter_aspect_of_the_hawk) Spell(aspect_of_the_hawk)
}

AddFunction InterruptActions
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		Spell(silencing_shot)
		Spell(counter_shot)
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_focus)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

AddFunction SummonPet
{
	if pet.Present(no) Texture(ability_hunter_beastcall help=L(summon_pet))
	if pet.IsDead() Spell(revive_pet)
}

###
### Beast Mastery
###
# Based on SimulationCraft profile "Hunter_BM_T16H".
#	class=hunter
#	spec=beast_mastery
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ya!...100

# ActionList: BeastMasteryDefaultActions --> main, shortcd, cd

AddFunction BeastMasteryDefaultActions
{
	#auto_shot
	#serpent_sting,if=!ticking
	if not target.DebuffPresent(serpent_sting_debuff) Spell(serpent_sting)
	#multi_shot,if=active_enemies>5|(active_enemies>1&buff.beast_cleave.down)
	if Enemies() > 5 or Enemies() > 1 and pet.BuffExpires(pet_beast_cleave_buff any=1) Spell(multi_shot)
	#kill_shot
	if target.HealthPercent() < 20 Spell(kill_shot)
	#kill_command
	if pet.Present() and pet.IsIncapacitated(no) and pet.IsFeared(no) and pet.IsStunned(no) Spell(kill_command)
	#glaive_toss,if=enabled
	if Talent(glaive_toss_talent) Spell(glaive_toss)
	#cobra_shot,if=active_enemies>5
	if Enemies() > 5 Spell(cobra_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react|buff.beast_within.up
	if BuffPresent(thrill_of_the_hunt_buff) or BuffPresent(beast_within_buff) Spell(arcane_shot)
	#cobra_shot,if=dot.serpent_sting.remains<6
	if target.DebuffRemaining(serpent_sting_debuff) < 6 Spell(cobra_shot)
	#arcane_shot,if=focus>=61
	if Focus() >= 61 Spell(arcane_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction BeastMasteryDefaultShortCdActions
{
	#explosive_trap,if=active_enemies>1
	if Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and Glyph(glyph_of_explosive_trap no) Spell(explosive_trap)

	unless not target.DebuffPresent(serpent_sting_debuff) and Spell(serpent_sting)
	{
		#dire_beast,if=enabled
		if Talent(dire_beast_talent) Spell(dire_beast)
		#fervor,if=enabled&focus<=65
		if Talent(fervor_talent) and Focus() <= 65 Spell(fervor)
		#bestial_wrath,if=focus>60&!buff.beast_within.up
		if Focus() > 60 and not BuffPresent(beast_within_buff) Spell(bestial_wrath)

		unless Enemies() > 5 or Enemies() > 1 and pet.BuffExpires(pet_beast_cleave_buff any=1) and Spell(multi_shot)
		{
			#barrage,if=enabled&active_enemies>5
			if Talent(barrage_talent) and Enemies() > 5 Spell(barrage)

			unless target.HealthPercent() < 20 and Spell(kill_shot)
				or pet.Present() and pet.IsIncapacitated(no) and pet.IsFeared(no) and pet.IsStunned(no) and Spell(kill_command)
			{
				#a_murder_of_crows,if=enabled&!ticking
				if Talent(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) Spell(a_murder_of_crows)

				unless Talent(glaive_toss_talent) and Spell(glaive_toss)
				{
					#lynx_rush,if=enabled&!dot.lynx_rush.ticking
					if Talent(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) Spell(lynx_rush)
					#barrage,if=enabled
					if Talent(barrage_talent) Spell(barrage)
					#powershot,if=enabled
					if Talent(powershot_talent) Spell(powershot)

					unless Enemies() > 5 and Spell(cobra_shot)
						or { BuffPresent(thrill_of_the_hunt_buff) or BuffPresent(beast_within_buff) } and Spell(arcane_shot)
					{
						#focus_fire,five_stacks=1
						if BuffStacks(frenzy_buff any=1) == 5 Spell(focus_fire)
					}
				}
			}
		}
	}
}

AddFunction BeastMasteryDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#virmens_bite_potion,if=target.time_to_die<=25|buff.stampede.up
	if target.TimeToDie() <= 25 or BuffPresent(stampede_buff) UsePotionAgility()
	#use_item,slot=hands
	UseItemActions()

	unless Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and Glyph(glyph_of_explosive_trap no) and Spell(explosive_trap)
		or not target.DebuffPresent(serpent_sting_debuff) and Spell(serpent_sting)
	{
		#blood_fury
		Spell(blood_fury_ap)

		unless Talent(dire_beast_talent) and Spell(dire_beast)
			or { Enemies() > 5 or Enemies() > 1 and pet.BuffExpires(pet_beast_cleave_buff any=1) } and Spell(multi_shot)
		{
			#rapid_fire,if=!buff.rapid_fire.up
			if not BuffPresent(rapid_fire_buff) Spell(rapid_fire)
			#stampede,if=trinket.stat.agility.up|target.time_to_die<=20|(trinket.stacking_stat.agility.stack>10&trinket.stat.agility.cooldown_remains<=3)
			if BuffPresent(trinket_stat_agility_buff) or target.TimeToDie() <= 20 or BuffStacks(trinket_stacking_stat_agility_buff) > 10 and BuffCooldown(trinket_stat_agility_buff) <= 3 Spell(stampede)
		}
	}
}

# ActionList: BeastMasteryPrecombatActions --> main, shortcd, cd

AddFunction BeastMasteryPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#aspect_of_the_hawk
	AspectOfTheHawk()
	#snapshot_stats
}

AddFunction BeastMasteryPrecombatShortCdActions
{
	unless AspectOfTheHawk()
	{
		#summon_pet
		SummonPet()
	}
}

AddFunction BeastMasteryPrecombatCdActions
{
	unless AspectOfTheHawk()
	{
		#hunters_mark,if=target.time_to_die>=21&!debuff.ranged_vulnerability.up
		if target.TimeToDie() >= 21 and not target.DebuffPresent(ranged_vulnerability_debuff any=1) Spell(hunters_mark)

		unless pet.Present(no) or pet.IsDead()
		{
			#virmens_bite_potion
			UsePotionAgility()
		}
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
# Based on SimulationCraft profile "Hunter_MM_T16H".
#	class=hunter
#	spec=marksmanship
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#YZ!...000

# ActionList: MarksmanshipPrecombatActions --> main, shortcd, cd

AddFunction MarksmanshipPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#aspect_of_the_hawk
	AspectOfTheHawk()
	#snapshot_stats
}

AddFunction MarksmanshipPrecombatShortCdActions
{
	unless AspectOfTheHawk()
	{
		#summon_pet
		SummonPet()
	}
}

AddFunction MarksmanshipPrecombatCdActions
{
	unless AspectOfTheHawk()
	{
		#hunters_mark,if=target.time_to_die>=21&!debuff.ranged_vulnerability.up
		if target.TimeToDie() >= 21 and not target.DebuffPresent(ranged_vulnerability_debuff any=1) Spell(hunters_mark)

		unless pet.Present(no) or pet.IsDead()
		{
			#virmens_bite_potion
			UsePotionAgility()
		}
	}
}

# ActionList: MarksmanshipDefaultActions --> main, shortcd, cd

AddFunction MarksmanshipDefaultActions
{
	#auto_shot
	#run_action_list,name=careful_aim,if=target.health.pct>80
	if target.HealthPercent() > 80 MarksmanshipCarefulAimActions()
	#steady_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<=4
	if BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) <= 4 Spell(steady_shot)
	#glaive_toss,if=enabled
	if Talent(glaive_toss_talent) Spell(glaive_toss)
	#serpent_sting,if=!ticking
	if not target.DebuffPresent(serpent_sting_debuff) Spell(serpent_sting)
	#chimera_shot
	Spell(chimera_shot)
	#steady_shot,if=buff.steady_focus.remains<(action.steady_shot.cast_time+1)&!in_flight
	if BuffRemaining(steady_focus_buff) < CastTime(steady_shot) + 1 and not InFlightToTarget(steady_shot) Spell(steady_shot)
	#kill_shot
	if target.HealthPercent() < 20 Spell(kill_shot)
	#multi_shot,if=active_enemies>=4
	if Enemies() >= 4 Spell(multi_shot)
	#aimed_shot,if=buff.master_marksman_fire.react
	if BuffPresent(master_marksman_fire_buff) Spell(aimed_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react
	if BuffPresent(thrill_of_the_hunt_buff) Spell(arcane_shot)
	#aimed_shot,if=cast_time<1.6
	if CastTime(aimed_shot) < 1.6 Spell(aimed_shot)
	#arcane_shot,if=focus>=60|(focus>=43&(cooldown.chimera_shot.remains>=action.steady_shot.cast_time))&(!buff.rapid_fire.up&!buff.bloodlust.react)
	if Focus() >= 60 or Focus() >= 43 and SpellCooldown(chimera_shot) >= CastTime(steady_shot) and not BuffPresent(rapid_fire_buff) and not BuffPresent(burst_haste_buff any=1) Spell(arcane_shot)
	#steady_shot
	Spell(steady_shot)
}

AddFunction MarksmanshipDefaultShortCdActions
{
	#explosive_trap,if=active_enemies>1
	if Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and Glyph(glyph_of_explosive_trap no) Spell(explosive_trap)
	if Talent(powershot_talent) Spell(powershot)
	#lynx_rush,if=enabled&!dot.lynx_rush.ticking
	if Talent(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) Spell(lynx_rush)
	#fervor,if=enabled&focus<=50
	if Talent(fervor_talent) and Focus() <= 50 Spell(fervor)
	#a_murder_of_crows,if=enabled&!ticking
	if Talent(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) Spell(a_murder_of_crows)
	#dire_beast,if=enabled
	if Talent(dire_beast_talent) Spell(dire_beast)

	unless target.HealthPercent() > 80 and MarksmanshipCarefulAimActions()
		or BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) <= 4 and Spell(steady_shot)
		or Talent(glaive_toss_talent) and Spell(glaive_toss)
	{
		#barrage,if=enabled
		if Talent(barrage_talent) Spell(barrage)
	}
}

AddFunction MarksmanshipDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#virmens_bite_potion,if=target.time_to_die<=25|buff.stampede.up
	if target.TimeToDie() <= 25 or BuffPresent(stampede_buff) UsePotionAgility()

	unless Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and Glyph(glyph_of_explosive_trap no) and Spell(explosive_trap)
	{
		#blood_fury
		Spell(blood_fury_ap)

		unless Talent(powershot_talent) and Spell(powershot)
			or Talent(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) and Spell(lynx_rush)
		{
			#rapid_fire,if=!buff.rapid_fire.up
			if not BuffPresent(rapid_fire_buff) Spell(rapid_fire)
			#stampede,if=trinket.stat.agility.up|target.time_to_die<=20|(trinket.stacking_stat.agility.stack>10&trinket.stat.agility.cooldown_remains<=3)
			if BuffPresent(trinket_stat_agility_buff) or target.TimeToDie() <= 20 or BuffStacks(trinket_stacking_stat_agility_buff) > 10 and BuffCooldown(trinket_stat_agility_buff) <= 3 Spell(stampede)
		}
	}
}

# ActionList: MarksmanshipCarefulAimActions --> main

AddFunction MarksmanshipCarefulAimActions
{
	#serpent_sting,if=!ticking
	if not target.DebuffPresent(serpent_sting_debuff) Spell(serpent_sting)
	#chimera_shot
	Spell(chimera_shot)
	#steady_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<6
	if BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) < 6 Spell(steady_shot)
	#aimed_shot
	Spell(aimed_shot)
	#glaive_toss,if=enabled
	if Talent(glaive_toss_talent) Spell(glaive_toss)
	#steady_shot
	Spell(steady_shot)
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
# Based on SimulationCraft profile "Hunter_SV_T16H".
#	class=hunter
#	spec=survival
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Yb!...200
#
# TODO: Pool focus for Black Arrow and Explosive Shot.

# ActionList: SurvivalDefaultActions --> main, shortcd, cd

AddFunction SurvivalDefaultActions
{
	#auto_shot
	#explosive_shot,if=buff.lock_and_load.react
	if BuffPresent(lock_and_load_buff) Spell(explosive_shot)
	#glaive_toss,if=enabled
	if Talent(glaive_toss_talent) Spell(glaive_toss)
	#serpent_sting,if=!ticking&target.time_to_die>=10
	if not target.DebuffPresent(serpent_sting_debuff) and target.TimeToDie() >= 10 Spell(serpent_sting)
	#explosive_shot,if=cooldown_react
	if not SpellCooldown(explosive_shot) > 0 Spell(explosive_shot)
	#kill_shot
	if target.HealthPercent() < 20 Spell(kill_shot)
	#black_arrow,if=!ticking&target.time_to_die>=8
	if not target.DebuffPresent(black_arrow_debuff) and target.TimeToDie() >= 8 Spell(black_arrow)
	#multi_shot,if=active_enemies>3
	if Enemies() > 3 Spell(multi_shot)
	#multi_shot,if=buff.thrill_of_the_hunt.react&dot.serpent_sting.remains<2
	if BuffPresent(thrill_of_the_hunt_buff) and target.DebuffRemaining(serpent_sting_debuff) < 2 Spell(multi_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react
	if BuffPresent(thrill_of_the_hunt_buff) Spell(arcane_shot)
	#cobra_shot,if=dot.serpent_sting.remains<6
	if target.DebuffRemaining(serpent_sting_debuff) < 6 Spell(cobra_shot)
	#arcane_shot,if=focus>=67&active_enemies<2
	if Focus() >= 67 and Enemies() < 2 Spell(arcane_shot)
	#multi_shot,if=focus>=67&active_enemies>1
	if Focus() >= 67 and Enemies() > 1 Spell(multi_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction SurvivalDefaultShortCdActions
{
	#explosive_trap,if=active_enemies>1
	if Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and Glyph(glyph_of_explosive_trap no) Spell(explosive_trap)
	#fervor,if=enabled&focus<=50
	if Talent(fervor_talent) and Focus() <= 50 Spell(fervor)
	#a_murder_of_crows,if=enabled&!ticking
	if Talent(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) Spell(a_murder_of_crows)
	#lynx_rush,if=enabled&!dot.lynx_rush.ticking
	if Talent(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) Spell(lynx_rush)

	unless BuffPresent(lock_and_load_buff) and Spell(explosive_shot)
		or Talent(glaive_toss_talent) Spell(glaive_toss)
	{
		#powershot,if=enabled
		if Talent(powershot_talent) Spell(powershot)
		#barrage,if=enabled
		if Talent(barrage_talent) Spell(barrage)

		unless not target.DebuffPresent(serpent_sting_debuff) and target.TimeToDie() >= 10 and Spell(serpent_sting)
			or not SpellCooldown(explosive_shot) > 0 and Spell(explosive_shot)
			or target.HealthPercent() < 20 and Spell(kill_shot)
			or not target.DebuffPresent(black_arrow_debuff) and target.TimeToDie() >= 8 and Spell(black_arrow)
			or Enemies() > 3 and Spell(multi_shot)
			or BuffPresent(thrill_of_the_hunt_buff) and target.DebuffRemaining(serpent_sting_debuff) < 2 and Spell(multi_shot)
			or BuffPresent(thrill_of_the_hunt_buff) and Spell(arcane_shot)
		{
			#dire_beast,if=enabled
			if Talent(dire_beast_talent) Spell(dire_beast)
		}
	}
}

AddFunction SurvivalDefaultCdActions
{
	# CHANGE: Add interrupt actions missing from SimulationCraft action list.
	InterruptActions()

	#virmens_bite_potion,if=target.time_to_die<=25|buff.stampede.up
	if target.TimeToDie() <= 25 or BuffPresent(stampede_buff) UsePotionAgility()
	#blood_fury
	Spell(blood_fury_ap)

	unless Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and Glyph(glyph_of_explosive_trap no) and Spell(explosive_trap)
		or Talent(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) and Spell(a_murder_of_crows)
		or Talent(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) and Spell(lynx_rush)
		or BuffPresent(lock_and_load_buff) and Spell(explosive_shot)
		or Talent(glaive_toss_talent) and Spell(glaive_toss)
		or Talent(powershot_talent) and Spell(powershot)
		or Talent(barrage_talent) and Spell(barrage)
		or not target.DebuffPresent(serpent_sting_debuff) and target.TimeToDie() >= 10 and Spell(serpent_sting)
		or not SpellCooldown(explosive_shot) > 0 and Spell(explosive_shot)
		or target.HealthPercent() < 20 and Spell(kill_shot)
		or not target.DebuffPresent(black_arrow_debuff) and target.TimeToDie() >= 8 and Spell(black_arrow)
		or Enemies() > 3 and Spell(multi_shot)
		or BuffPresent(thrill_of_the_hunt_buff) and target.DebuffRemaining(serpent_sting_debuff) < 2 and Spell(multi_shot)
		or BuffPresent(thrill_of_the_hunt_buff) and Spell(arcane_shot)
	{
		#rapid_fire,if=!buff.rapid_fire.up
		if not BuffPresent(rapid_fire_buff) Spell(rapid_fire)

		unless Talent(dire_beast_talent) and Spell(dire_beast)
		{
			#stampede,if=trinket.stat.agility.up|target.time_to_die<=20|(trinket.stacking_stat.agility.stack>10&trinket.stat.agility.cooldown_remains<=3)
			if BuffPresent(trinket_stat_agility_buff) or target.TimeToDie() <= 20 or BuffStacks(trinket_stacking_stat_agility_buff) > 10 and BuffCooldown(trinket_stat_agility_buff) <= 3 Spell(stampede)
		}
	}
}

# ActionList: SurvivalPrecombatActions --> main, shortcd, cd

AddFunction SurvivalPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#aspect_of_the_hawk
	AspectOfTheHawk()
	#snapshot_stats
}

AddFunction SurvivalPrecombatShortCdActions
{
	unless AspectOfTheHawk()
	{
		#summon_pet
		SummonPet()
	}
}

AddFunction SurvivalPrecombatCdActions
{
	unless AspectOfTheHawk()
	{
		#hunters_mark,if=target.time_to_die>=21&!debuff.ranged_vulnerability.up
		if target.TimeToDie() >= 21 and not target.DebuffPresent(ranged_vulnerability_debuff any=1) Spell(hunters_mark)

		unless pet.Present(no) or pet.IsDead()
		{
			#virmens_bite_potion
			UsePotionAgility()
		}
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
