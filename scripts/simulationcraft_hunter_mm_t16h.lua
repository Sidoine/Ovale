local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "SimulationCraft: Hunter_MM_T16H"
	local desc = "[5.4] SimulationCraft: Hunter_MM_T16H"
	local code = [[
# Based on SimulationCraft profile "Hunter_MM_T16H".
#	class=hunter
#	spec=marksmanship
#	talents=http://us.battle.net/wow/en/tool/talent-calculator#YZ!...000

Include(ovale_common)
Include(ovale_hunter_spells)

AddCheckBox(opt_potion_agility ItemName(virmens_bite_potion) default)
AddCheckBox(opt_trap_launcher SpellName(trap_launcher) default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potion_agility) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction AspectOfTheHawk
{
	if Talent(aspect_of_the_iron_hawk_talent) and not Stance(hunter_aspect_of_the_iron_hawk) Spell(aspect_of_the_iron_hawk)
	if Talent(aspect_of_the_iron_hawk_talent no) and not Stance(hunter_aspect_of_the_hawk) Spell(aspect_of_the_hawk)
}

AddFunction SummonPet
{
	if pet.Present(no) Texture(ability_hunter_beastcall help=L(summon_pet))
	if pet.IsDead() Spell(revive_pet)
}

AddFunction MarksmanshipPrecombatActions
{
	#flask,type=spring_blossoms
	#food,type=sea_mist_rice_noodles
	#aspect_of_the_hawk
	AspectOfTheHawk()
	#hunters_mark,if=target.time_to_die>=21&!debuff.ranged_vulnerability.up
	if target.TimeToDie() >= 21 and not target.DebuffPresent(ranged_vulnerability_debuff any=1) Spell(hunters_mark)
	#summon_pet
	SummonPet()
	#snapshot_stats
	#virmens_bite_potion
	UsePotionAgility()
}

AddFunction MarksmanshipDefaultActions
{
	#virmens_bite_potion,if=target.time_to_die<=25|buff.stampede.up
	if target.TimeToDie() <= 25 or BuffPresent(stampede_buff) UsePotionAgility()
	#auto_shot
	#explosive_trap,if=active_enemies>1
	if Enemies() > 1 and CheckBoxOn(opt_trap_launcher) and Glyph(glyph_of_explosive_trap no) Spell(explosive_trap)
	#blood_fury
	Spell(blood_fury_ap)
	#powershot,if=enabled
	if Talent(powershot_talent) Spell(powershot)
	#lynx_rush,if=enabled&!dot.lynx_rush.ticking
	if Talent(lynx_rush_talent) and not target.DebuffPresent(lynx_rush_debuff) Spell(lynx_rush)
	#fervor,if=enabled&focus<=50
	if Talent(fervor_talent) and Focus() <= 50 Spell(fervor)
	#rapid_fire,if=!buff.rapid_fire.up
	if not BuffPresent(rapid_fire_buff) Spell(rapid_fire)
	#stampede,if=trinket.stat.agility.up|target.time_to_die<=20|(trinket.stacking_stat.agility.stack>10&trinket.stat.agility.cooldown_remains<=3)
	if BuffPresent(trinket_stat_agility_buff) or target.TimeToDie() <= 20 or BuffStacks(trinket_stacking_stat_agility_buff) > 10 and BuffCooldown(trinket_stat_agility_buff) <= 3 Spell(stampede)
	#a_murder_of_crows,if=enabled&!ticking
	if Talent(a_murder_of_crows_talent) and not target.DebuffPresent(a_murder_of_crows_debuff) Spell(a_murder_of_crows)
	#dire_beast,if=enabled
	if Talent(dire_beast_talent) Spell(dire_beast)
	#run_action_list,name=careful_aim,if=target.health.pct>80
	if target.HealthPercent() > 80 MarksmanshipCarefulAimActions()
	#steady_shot,if=buff.pre_steady_focus.up&buff.steady_focus.remains<=4
	if BuffPresent(pre_steady_focus_buff) and BuffRemaining(steady_focus_buff) <= 4 Spell(steady_shot)
	#glaive_toss,if=enabled
	if Talent(glaive_toss_talent) Spell(glaive_toss)
	#barrage,if=enabled
	if Talent(barrage_talent) Spell(barrage)
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

AddIcon specialization=marksmanship help=main enemies=1
{
	if InCombat(no) MarksmanshipPrecombatActions()
	MarksmanshipDefaultActions()
}

AddIcon specialization=marksmanship help=aoe
{
	if InCombat(no) MarksmanshipPrecombatActions()
	MarksmanshipDefaultActions()
}

### Required symbols
# a_murder_of_crows
# a_murder_of_crows_debuff
# a_murder_of_crows_talent
# aimed_shot
# arcane_shot
# aspect_of_the_hawk
# aspect_of_the_iron_hawk
# aspect_of_the_iron_hawk_talent
# barrage
# barrage_talent
# blood_fury_ap
# chimera_shot
# dire_beast
# dire_beast_talent
# explosive_trap
# fervor
# fervor_talent
# glaive_toss
# glaive_toss_talent
# glyph_of_explosive_trap
# hunters_mark
# kill_shot
# lynx_rush
# lynx_rush_debuff
# lynx_rush_talent
# master_marksman_fire_buff
# multi_shot
# powershot
# powershot_talent
# pre_steady_focus_buff
# rapid_fire
# rapid_fire_buff
# revive_pet
# serpent_sting
# serpent_sting_debuff
# stampede
# stampede_buff
# steady_focus_buff
# steady_shot
# thrill_of_the_hunt_buff
# trap_launcher
# trinket_stacking_stat_agility_buff
# trinket_stat_agility_buff
# virmens_bite_potion
]]
	OvaleScripts:RegisterScript("HUNTER", name, desc, code, "reference")
end
