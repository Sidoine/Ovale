local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.4] Ovale: Beast Mastery, Marksmanship, Survival"
	local code = [[
# Ovale hunter script based on SimulationCraft.

Include(ovale_items)
Include(ovale_racials)
Include(ovale_hunter_spells)

AddCheckBox(opt_aoe L(AOE) default)
AddCheckBox(opt_icons_left "Left icons")
AddCheckBox(opt_icons_right "Right icons")
AddCheckBox(opt_proc_on_use_agility_trinket "Proc/On-Use Agility Trinket")

###
### Beast Mastery
###
# Based on SimulationCraft profile "Hunter_BM_T16H".
#	class=hunter
#	spec=beast_mastery
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Ya!...100

AddFunction BeastMasteryDefaultActions
{
	#auto_shot
	#serpent_sting,if=!ticking
	if not target.DebuffPresent(serpent_sting_debuff) Spell(serpent_sting)
	#dire_beast,if=enabled
	if TalentPoints(dire_beast_talent) Spell(dire_beast)
	#fervor,if=enabled&focus<=65
	if TalentPoints(fervor_talent) and Focus() <= 65 Spell(fervor)
	#kill_shot
	Spell(kill_shot usable=1)
	#kill_command
	if pet.Present() Spell(kill_command)
	#glaive_toss,if=enabled
	if TalentPoints(glaive_toss_talent) Spell(glaive_toss)
	#arcane_shot,if=buff.thrill_of_the_hunt.react|buff.beast_within.up
	if BuffPresent(thrill_of_the_hunt_buff) or BuffPresent(beast_within_buff) Spell(arcane_shot)
	#focus_fire,five_stacks=1
	if BuffStacks(frenzy_buff any=1) == 5 Spell(focus_fire)
	#cobra_shot,if=dot.serpent_sting.remains<6
	if target.DebuffRemains(serpent_sting_debuff) < 6 Spell(cobra_shot)
	#arcane_shot,if=focus>=61
	if Focus() >= 61 Spell(arcane_shot)
	#cobra_shot
	Spell(cobra_shot)
	Spell(steady_shot)
}

AddFunction BeastMasteryDefaultAoeActions
{
	#auto_shot
	#explosive_trap,if=active_enemies>1
	if Enemies() > 1 Spell(explosive_trap)
	#serpent_sting,if=!ticking
	if not target.DebuffPresent(serpent_sting_debuff) Spell(serpent_sting)
	#dire_beast,if=enabled
	if TalentPoints(dire_beast_talent) Spell(dire_beast)
	#fervor,if=enabled&focus<=65
	if TalentPoints(fervor_talent) and Focus() <= 65 Spell(fervor)
	#multi_shot,if=active_enemies>5|(active_enemies>1&buff.beast_cleave.down)
	if Enemies() > 5 or { Enemies() > 1 and pet.BuffExpires(beast_cleave_buff any=1) } Spell(multi_shot)
	#kill_shot
	Spell(kill_shot usable=1)
	#kill_command
	if pet.Present() Spell(kill_command)
	#glaive_toss,if=enabled
	if TalentPoints(glaive_toss_talent) Spell(glaive_toss)
	#cobra_shot,if=active_enemies>5
	if Enemies() > 5 Spell(cobra_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react|buff.beast_within.up
	if BuffPresent(thrill_of_the_hunt_buff) or BuffPresent(beast_within_buff) Spell(arcane_shot)
	#focus_fire,five_stacks=1
	if pet.BuffStacks(frenzy_buff any=1) == 5 Spell(focus_fire)
	#cobra_shot,if=dot.serpent_sting.remains<6
	if target.DebuffRemains(serpent_sting_debuff) < 6 Spell(cobra_shot)
	#arcane_shot,if=focus>=61
	if Focus() >= 61 Spell(arcane_shot)
	#cobra_shot
	Spell(cobra_shot)
	Spell(steady_shot)
}

AddFunction BeastMasteryDefaultShortCdActions
{
	unless { not target.DebuffPresent(serpent_sting_debuff) and Spell(serpent_sting) }
		or { TalentPoints(dire_beast_talent) and Spell(dire_beast) }
	{
		#bestial_wrath,if=focus>60&!buff.beast_within.up
		if Focus() > 60 and not BuffPresent(beast_within_buff) Spell(bestial_wrath)
		#barrage,if=enabled&active_enemies>5
		if TalentPoints(barrage_talent) and Enemies() > 5 Spell(barrage)

		unless Spell(kill_shot usable=1)
			or { pet.Present() and Spell(kill_command) }
		{
			#a_murder_of_crows,if=enabled&!ticking
			if TalentPoints(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) Spell(a_murder_of_crows)

			unless { TalentPoints(glaive_toss_talent) and Spell(glaive_toss) }
			{
				#lynx_rush,if=enabled&!dot.lynx_rush.ticking
				if TalentPoints(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) Spell(lynx_rush)
				#barrage,if=enabled
				if TalentPoints(barrage_talent) Spell(barrage)
				#powershot,if=enabled
				if TalentPoints(powershot_talent) Spell(powershot)
			}
		}
	}
}

AddFunction BeastMasteryDefaultCdActions
{
	#virmens_bite_potion,if=target.time_to_die<=25|buff.stampede.up
	if target.TimeToDie() <= 25 or BuffPresent(stampede_buff) UsePotionAgility()
	#use_item,slot=hands
	UseItemActions()

	unless { not target.DebuffPresent(serpent_sting_debuff) and Spell(serpent_sting) }
	{
		#blood_fury
		UseRacialActions()

		unless { TalentPoints(dire_beast_talent) and Spell(dire_beast) }
		{
			#rapid_fire,if=!buff.rapid_fire.up
			if not BuffPresent(rapid_fire_buff) Spell(rapid_fire)
			#stampede,if=trinket.stat.agility.up|target.time_to_die<=20|(trinket.stacking_stat.agility.stack>10&trinket.stat.agility.cooldown_remains<=3)
			if CheckBoxOff(opt_proc_on_use_agility_trinket) or BuffPresent(trinket_stat_agility_buff) or target.TimeToDie() <= 20 or { BuffStacks(trinket_stacking_stat_agility_buff) > 10 and { ItemCooldown(Trinket0Slot) + ItemCooldown(Trinket1Slot) } <= 3 } Spell(stampede)
		}
	}
}

AddFunction BeastMasteryPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#aspect_of_the_hawk
	if TalentPoints(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_iron_hawk) Spell(aspect_of_the_iron_hawk)
	if not TalentPoints(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_hawk) Spell(aspect_of_the_hawk)
}

AddFunction BeastMasteryPrecombatShortCdActions
{
	#summon_pet
	SummonPet()
}

AddFunction BeastMasteryPrecombatCdActions
{
	#hunters_mark,if=target.time_to_die>=21&!debuff.ranged_vulnerability.up
	if target.TimeToDie() >= 21 and not target.DebuffPresent(ranged_vulnerability any=1) Spell(hunters_mark)
	#virmens_bite_potion
	UsePotionAgility()
}

### Beast Mastery icons

AddIcon mastery=beast_mastery size=small checkboxon=opt_icons_left
{
	Spell(misdirection)
}

AddIcon mastery=beast_mastery size=small checkboxon=opt_icons_left
{
	Spell(disengage)
}

AddIcon mastery=beast_mastery help=shortcd
{
	if InCombat(no) BeastMasteryPrecombatShortCdActions()
	SummonPet()
	BeastMasteryDefaultShortCdActions()
}

AddIcon mastery=beast_mastery help=main
{
	if InCombat(no) BeastMasteryPrecombatActions()
	BeastMasteryDefaultActions()
}

AddIcon mastery=beast_mastery help=aoe checkboxon=opt_aoe
{
	if InCombat(no) BeastMasteryPrecombatActions()
	BeastMasteryDefaultAoeActions()
}

AddIcon mastery=beast_mastery help=cd
{
	if InCombat(no) BeastMasteryPrecombatCdActions()
	Interrupt()
	UseRacialInterruptActions()
	BeastMasteryDefaultCdActions()
}

AddIcon mastery=beast_mastery size=small checkboxon=opt_icons_right
{
	Spell(explosive_trap)
}

AddIcon mastery=beast_mastery size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Marksmanship
###
# Based on SimulationCraft profile "Hunter_MM_T16H".
#	class=hunter
#	spec=marksmanship
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#YZ!...000

AddFunction MarksmanshipCarefulAimActions
{
	#serpent_sting,if=!ticking
	if not target.DebuffPresent(serpent_sting_debuff) Spell(serpent_sting)
	#chimera_shot
	Spell(chimera_shot)
	#steady_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<6
	if BuffPresent(pre_steady_focus_buff) and BuffRemains(steady_focus_buff) < 6 Spell(steady_shot)
	#aimed_shot
	Spell(aimed_shot)
	#glaive_toss,if=enabled
	if TalentPoints(glaive_toss_talent) Spell(glaive_toss)
	#steady_shot
	Spell(steady_shot)
}

AddFunction MarksmanshipDefaultActions
{
	#auto_shot
	#fervor,if=enabled&focus<=50
	if TalentPoints(fervor_talent) and Focus() <= 50 Spell(fervor)
	#dire_beast,if=enabled
	if TalentPoints(dire_beast_talent) Spell(dire_beast)
	#run_action_list,name=careful_aim,if=target.health.pct>80
	if target.HealthPercent() > 80 MarksmanshipCarefulAimActions()
	#steady_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<=4
	if BuffPresent(pre_steady_focus_buff) and BuffRemains(steady_focus_buff) <= 4 Spell(steady_shot)
	#glaive_toss,if=enabled
	if TalentPoints(glaive_toss_talent) Spell(glaive_toss)
	#serpent_sting,if=!ticking
	if not target.DebuffPresent(serpent_sting_debuff) Spell(serpent_sting)
	#chimera_shot
	Spell(chimera_shot)
	#steady_shot,if=buff.steady_focus.remains<(action.steady_shot.cast_time+1)&!in_flight
	if BuffRemains(steady_focus_buff) < { CastTime(steady_shot) + 1 } and not InFlightToTarget(steady_shot) Spell(steady_shot)
	#kill_shot
	Spell(kill_shot usable=1)
	#aimed_shot,if=buff.master_marksman_fire.react
	if BuffPresent(master_marksman_fire_buff) Spell(aimed_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react
	if BuffPresent(thrill_of_the_hunt_buff) Spell(arcane_shot)
	#aimed_shot,if=cast_time<1.6
	if CastTime(aimed_shot) < 1.6 Spell(aimed_shot)
	#arcane_shot,if=focus>=60|(focus>=43&(cooldown.chimera_shot.remains>=action.steady_shot.cast_time))&(!buff.rapid_fire.up&!buff.bloodlust.react)
	if Focus() >= 60 or { Focus() >= 43 and { SpellCooldown(chimera_shot) >= CastTime(steady_shot) } } and { not BuffPresent(rapid_fire_buff) and not BuffPresent(burst_haste any=1) } Spell(arcane_shot)
	#steady_shot
	Spell(steady_shot)
}

AddFunction MarksmanshipDefaultAoeActions
{
	#auto_shot
	#explosive_trap,if=active_enemies>1
	if Enemies() > 1 Spell(explosive_trap)
	#fervor,if=enabled&focus<=50
	if TalentPoints(fervor_talent) and Focus() <= 50 Spell(fervor)
	#dire_beast,if=enabled
	if TalentPoints(dire_beast_talent) Spell(dire_beast)
	#run_action_list,name=careful_aim,if=target.health.pct>80
	if target.HealthPercent() > 80 MarksmanshipCarefulAimActions()
	#steady_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<=4
	if BuffPresent(pre_steady_focus_buff) and BuffRemains(steady_focus_buff) <= 4 Spell(steady_shot)
	#glaive_toss,if=enabled
	if TalentPoints(glaive_toss_talent) Spell(glaive_toss)
	#serpent_sting,if=!ticking
	if not target.DebuffPresent(serpent_sting_debuff) Spell(serpent_sting)
	#chimera_shot
	Spell(chimera_shot)
	#steady_shot,if=buff.steady_focus.remains<(action.steady_shot.cast_time+1)&!in_flight
	if BuffRemains(steady_focus_buff) < { CastTime(steady_shot) + 1 } and not InFlightToTarget(steady_shot) Spell(steady_shot)
	#kill_shot
	Spell(kill_shot usable=1)
	#multi_shot,if=active_enemies>=4
	Spell(multi_shot)
	#aimed_shot,if=buff.master_marksman_fire.react
	if BuffPresent(master_marksman_fire_buff) Spell(aimed_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react
	if BuffPresent(thrill_of_the_hunt_buff) Spell(arcane_shot)
	#aimed_shot,if=cast_time<1.6
	if CastTime(aimed_shot) < 1.6 Spell(aimed_shot)
	#arcane_shot,if=focus>=60|(focus>=43&(cooldown.chimera_shot.remains>=action.steady_shot.cast_time))&(!buff.rapid_fire.up&!buff.bloodlust.react)
	if Focus() >= 60 or { Focus() >= 43 and { SpellCooldown(chimera_shot) >= CastTime(steady_shot) } } and { not BuffPresent(rapid_fire_buff) and not BuffPresent(burst_haste any=1) } Spell(arcane_shot)
	#steady_shot
	Spell(steady_shot)
}

AddFunction MarksmanshipDefaultShortCdActions
{
	#powershot,if=enabled
	if TalentPoints(powershot_talent) Spell(powershot)
	#lynx_rush,if=enabled&!dot.lynx_rush.ticking
	if TalentPoints(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) Spell(lynx_rush)
	#a_murder_of_crows,if=enabled&!ticking
	if TalentPoints(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) Spell(a_murder_of_crows)

	unless { TalentPoints(dire_beast_talent) and Spell(dire_beast) }
		or target.HealthPercent() > 80
		or { BuffPresent(pre_steady_focus_buff) and BuffRemains(steady_focus_buff) <= 4 and Spell(steady_shot) }
		or { TalentPoints(glaive_toss_talent) and Spell(glaive_toss) }
	{
		#barrage,if=enabled
		if TalentPoints(barrage_talent) Spell(barrage)
	}
}

AddFunction MarksmanshipDefaultCdActions
{
	#virmens_bite_potion,if=target.time_to_die<=25|buff.stampede.up
	if target.TimeToDie() <= 25 or BuffPresent(stampede_buff) UsePotionAgility()
	#use_item
	UseItemActions()
	#blood_fury
	UseRacialActions()

	unless { TalentPoints(powershot_talent) and Spell(powershot) }
		or { TalentPoints(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) and Spell(lynx_rush) }
	{
		#rapid_fire,if=!buff.rapid_fire.up
		if not BuffPresent(rapid_fire_buff) Spell(rapid_fire)
		#stampede,if=trinket.stat.agility.up|target.time_to_die<=20|(trinket.stacking_stat.agility.stack>10&trinket.stat.agility.cooldown_remains<=3)
		if CheckBoxOff(opt_proc_on_use_agility_trinket) or BuffPresent(trinket_stat_agility_buff) or target.TimeToDie() <= 20 or { BuffStacks(trinket_stacking_stat_agility_buff) > 10 and { ItemCooldown(Trinket0Slot) + ItemCooldown(Trinket1Slot) } <= 3 } Spell(stampede)
	}
}

AddFunction MarksmanshipPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#aspect_of_the_hawk
	if TalentPoints(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_iron_hawk) Spell(aspect_of_the_iron_hawk)
	if not TalentPoints(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_hawk) Spell(aspect_of_the_hawk)
}

AddFunction MarksmanshipPrecombatShortCdActions
{
	#summon_pet
	SummonPet()
}

AddFunction MarksmanshipPrecombatCdActions
{
	#hunters_mark,if=target.time_to_die>=21&!debuff.ranged_vulnerability.up
	if target.TimeToDie() >= 21 and not target.DebuffPresent(ranged_vulnerability any=1) Spell(hunters_mark)
	#virmens_bite_potion
	UsePotionAgility()
}

### Marksmanship icons

AddIcon mastery=marksmanship size=small checkboxon=opt_icons_left
{
	Spell(misdirection)
}

AddIcon mastery=marksmanship size=small checkboxon=opt_icons_left
{
	Spell(disengage)
}

AddIcon mastery=marksmanship help=shortcd
{
	if InCombat(no) MarksmanshipPrecombatShortCdActions()
	SummonPet()
	MarksmanshipDefaultShortCdActions()
}

AddIcon mastery=marksmanship help=main
{
	if InCombat(no) MarksmanshipPrecombatActions()
	MarksmanshipDefaultActions()
}

AddIcon mastery=marksmanship help=aoe checkboxon=opt_aoe
{
	if InCombat(no) MarksmanshipPrecombatActions()
	MarksmanshipDefaultAoeActions()
}

AddIcon mastery=marksmanship help=cd
{
	if InCombat(no) MarksmanshipPrecombatCdActions()
	Interrupt()
	UseRacialInterruptActions()
	MarksmanshipDefaultCdActions()
}

AddIcon mastery=marksmanship size=small checkboxon=opt_icons_right
{
	Spell(explosive_trap)
}

AddIcon mastery=marksmanship size=small checkboxon=opt_icons_right
{
	UseItemActions()
}

###
### Survival
###
# Based on SimulationCraft profile "Hunter_SV_T16H".
#	class=hunter
#	spec=survival
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#Yb!...200

AddFunction SurvivalArcaneShotFocusCondition
{
	# Pool focus for Black Arrow if it is coming off of cooldown.
	# If 2pT16 is not present, then also pool focus for Explosive Shot if it is coming off cooldown.
	#
	{ SpellCooldown(black_arrow) > 0 or Focus() - FocusCost(arcane_shot) >= FocusCost(black_arrow) }
		and { ArmorSetBonus(T16_melee 2) == 1
			or { ArmorSetBonus(T16_melee 2) == 0 and { SpellCooldown(explosive_shot) > 0 or Focus() - FocusCost(arcane_shot) >= FocusCost(explosive_shot) } } }
}

AddFunction SurvivalDefaultActions
{
	#auto_shot
	#fervor,if=enabled&focus<=50
	if TalentPoints(fervor_talent) and Focus() <= 50 Spell(fervor)
	#explosive_shot,if=buff.lock_and_load.react
	if BuffPresent(lock_and_load_buff) Spell(explosive_shot)
	#glaive_toss,if=enabled
	if TalentPoints(glaive_toss_talent) Spell(glaive_toss)
	#serpent_sting,if=!ticking&target.time_to_die>=10
	if not target.DebuffPresent(serpent_sting_debuff) and target.TimeToDie() >= 10 Spell(serpent_sting)
	#explosive_shot,if=cooldown_react
	Spell(explosive_shot)
	#kill_shot
	Spell(kill_shot usable=1)
	#black_arrow,if=!ticking&target.time_to_die>=8
	if not target.DebuffPresent(black_arrow_debuff) and target.TimeToDie() >= 8 Spell(black_arrow)
	#multi_shot,if=buff.thrill_of_the_hunt.react&dot.serpent_sting.remains<2
	if BuffPresent(thrill_of_the_hunt_buff) and target.DebuffRemains(serpent_sting_debuff) < 2 Spell(multi_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react
	if BuffPresent(thrill_of_the_hunt_buff) and SurvivalArcaneShotFocusCondition() Spell(arcane_shot)
	#dire_beast,if=enabled
	if TalentPoints(dire_beast_talent) Spell(dire_beast)
	#cobra_shot,if=dot.serpent_sting.remains<6
	if target.DebuffRemains(serpent_sting_debuff) < 6 Spell(cobra_shot)
	#arcane_shot,if=focus>=67&active_enemies<2
	if Focus() >= 67 Spell(arcane_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction SurvivalDefaultAoeActions
{
	#auto_shot
	#explosive_trap,if=active_enemies>1
	if Enemies() > 1 Spell(explosive_trap)
	#fervor,if=enabled&focus<=50
	if TalentPoints(fervor_talent) and Focus() <= 50 Spell(fervor)
	#explosive_shot,if=buff.lock_and_load.react
	if BuffPresent(lock_and_load_buff) Spell(explosive_shot)
	#glaive_toss,if=enabled
	if TalentPoints(glaive_toss_talent) Spell(glaive_toss)
	#serpent_sting,if=!ticking&target.time_to_die>=10
	if not target.DebuffPresent(serpent_sting_debuff) and target.TimeToDie() >= 10 Spell(serpent_sting)
	#explosive_shot,if=cooldown_react
	Spell(explosive_shot)
	#kill_shot
	Spell(kill_shot usable=1)
	#black_arrow,if=!ticking&target.time_to_die>=8
	if not target.DebuffPresent(black_arrow_debuff) and target.TimeToDie() >= 8 Spell(black_arrow)
	#multi_shot,if=active_enemies>3
	Spell(multi_shot)
	#multi_shot,if=buff.thrill_of_the_hunt.react&dot.serpent_sting.remains<2
	if BuffPresent(thrill_of_the_hunt_buff) and target.DebuffRemains(serpent_sting_debuff) < 2 Spell(multi_shot)
	#arcane_shot,if=buff.thrill_of_the_hunt.react
	if BuffPresent(thrill_of_the_hunt_buff) Spell(arcane_shot)
	#dire_beast,if=enabled
	if TalentPoints(dire_beast_talent) Spell(dire_beast)
	#cobra_shot,if=dot.serpent_sting.remains<6
	if target.DebuffRemains(serpent_sting_debuff) < 6 Spell(cobra_shot)
	#multi_shot,if=focus>=67&active_enemies>1
	if Focus() >= 67 Spell(multi_shot)
	#cobra_shot
	Spell(cobra_shot)
}

AddFunction SurvivalDefaultShortCdActions
{
	#a_murder_of_crows,if=enabled&!ticking
	if TalentPoints(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) Spell(a_murder_of_crows)
	#lynx_rush,if=enabled&!dot.lynx_rush.ticking
	if TalentPoints(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) Spell(lynx_rush)

	unless { BuffPresent(lock_and_load_buff) and Spell(explosive_shot) }
		or { TalentPoints(glaive_toss_talent) and Spell(glaive_toss) }
	{
		#powershot,if=enabled
		if TalentPoints(powershot_talent) Spell(powershot)
		#barrage,if=enabled
		if TalentPoints(barrage_talent) Spell(barrage)
	}
}

AddFunction SurvivalDefaultCdActions
{
	#virmens_bite_potion,if=target.time_to_die<=25|buff.stampede.up
	if target.TimeToDie() <= 25 or BuffPresent(stampede_buff) UsePotionAgility()
	#blood_fury
	UseRacialActions()
	#use_item
	UseItemActions()

	unless { TalentPoints(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) and Spell(a_murder_of_crows) }
		or { TalentPoints(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) and Spell(lynx_rush) }
		or { BuffPresent(lock_and_load_buff) and Spell(explosive_shot) }
		or { TalentPoints(glaive_toss_talent) and Spell(glaive_toss) }
		or { TalentPoints(powershot_talent) and Spell(powershot) }
		or { TalentPoints(barrage_talent) and Spell(barrage) }
		or { not target.DebuffPresent(serpent_sting_debuff) and target.TimeToDie() >= 10 and Spell(serpent_sting) }
		or Spell(explosive_shot)
		or Spell(kill_shot usable=1)
		or { not target.DebuffPresent(black_arrow_debuff) and target.TimeToDie() >= 8 and Spell(black_arrow) }
		or { BuffPresent(thrill_of_the_hunt_buff) and target.DebuffRemains(serpent_sting_debuff) < 2 and Spell(multi_shot) }
		or { BuffPresent(thrill_of_the_hunt_buff) and Spell(arcane_shot) }
	{
		#rapid_fire,if=!buff.rapid_fire.up
		if not BuffPresent(rapid_fire_buff) Spell(rapid_fire)

		unless { TalentPoints(dire_beast_talent) and Spell(dire_beast) }
		{
			#stampede,if=trinket.stat.agility.up|target.time_to_die<=20|(trinket.stacking_stat.agility.stack>10&trinket.stat.agility.cooldown_remains<=3)
			if CheckBoxOff(opt_proc_on_use_agility_trinket) or BuffPresent(trinket_stat_agility_buff) or target.TimeToDie() <= 20 or { BuffStacks(trinket_stacking_stat_agility_buff) > 10 and { ItemCooldown(Trinket0Slot) + ItemCooldown(Trinket1Slot) } <= 3 } Spell(stampede)
		}
	}
}

AddFunction SurvivalPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#aspect_of_the_hawk
	if TalentPoints(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_iron_hawk) Spell(aspect_of_the_iron_hawk)
	if not TalentPoints(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_hawk) Spell(aspect_of_the_hawk)
}

AddFunction SurvivalPrecombatShortCdActions
{
	#summon_pet
	SummonPet()
}

AddFunction SurvivalPrecombatCdActions
{
	#hunters_mark,if=target.time_to_die>=21&!debuff.ranged_vulnerability.up
	if target.TimeToDie() >= 21 and not target.DebuffPresent(ranged_vulnerability any=1) Spell(hunters_mark)
	#virmens_bite_potion
	UsePotionAgility()
}

### Survival icons

AddIcon mastery=survival size=small checkboxon=opt_icons_left
{
	Spell(misdirection)
}

AddIcon mastery=survival size=small checkboxon=opt_icons_left
{
	Spell(disengage)
}

AddIcon mastery=survival help=shortcd
{
	if InCombat(no) SurvivalPrecombatShortCdActions()
	SummonPet()
	SurvivalDefaultShortCdActions()
}

AddIcon mastery=survival help=main
{
	if InCombat(no) SurvivalPrecombatActions()
	SurvivalDefaultActions()
}

AddIcon mastery=survival help=aoe checkboxon=opt_aoe
{
	if InCombat(no) SurvivalPrecombatActions()
	SurvivalDefaultAoeActions()
}

AddIcon mastery=survival help=cd
{
	if InCombat(no) SurvivalPrecombatCdActions()
	Interrupt()
	UseRacialInterruptActions()
	SurvivalDefaultCdActions()
}

AddIcon mastery=survival size=small checkboxon=opt_icons_right
{
	Spell(explosive_trap)
}

AddIcon mastery=survival size=small checkboxon=opt_icons_right
{
	UseItemActions()
}
]]

	OvaleScripts:RegisterScript("HUNTER", name, desc, code)
end
