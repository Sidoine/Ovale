Ovale.defaut["HUNTER"] = [[Define(a_murder_of_crows 131900)
Define(aimed_shot 19434)
  SpellInfo(aimed_shot focus=50 )
Define(arcane_shot 3044)
  SpellInfo(arcane_shot focus=20 )
Define(aspect_of_the_fox 82661)
  SpellInfo(aspect_of_the_fox cd=1 )
  SpellAddBuff(aspect_of_the_fox aspect_of_the_fox=1)
Define(aspect_of_the_hawk 13165)
  SpellInfo(aspect_of_the_hawk cd=1 )
  SpellAddBuff(aspect_of_the_hawk aspect_of_the_hawk=1)
Define(barrage 120360)
  SpellInfo(barrage duration=3 focus=30 cd=30 )
Define(beast_within 34692)
Define(bestial_wrath 19574)
  SpellInfo(bestial_wrath duration=10 cd=60 )
  SpellAddBuff(bestial_wrath bestial_wrath=1)
Define(black_arrow 3674)
  SpellInfo(black_arrow duration=20 focus=35 tick=2 cd=30 )
  SpellAddTargetDebuff(black_arrow black_arrow=1)
Define(blink_strike 130392)
  SpellInfo(blink_strike cd=20 )
Define(blood_fury 20572)
  SpellInfo(blood_fury duration=15 cd=120 )
  SpellAddBuff(blood_fury blood_fury=1)
Define(call_pet_1 883)
Define(chimera_shot 53209)
  SpellInfo(chimera_shot focus=45 cd=9 )
Define(cobra_shot 77767)
  SpellInfo(cobra_shot focus=-14 )
Define(dire_beast 120679)
  SpellInfo(dire_beast duration=15 cd=30 )
Define(explosive_shot 53301)
  SpellInfo(explosive_shot duration=2 focus=25 tick=1 cd=6 )
  SpellAddTargetDebuff(explosive_shot explosive_shot=1)
Define(explosive_trap 13812)
  SpellInfo(explosive_trap duration=20 )
  SpellAddTargetDebuff(explosive_trap explosive_trap=1)
Define(fervor 82726)
  SpellInfo(fervor duration=10 focus=-50 cd=30 )
  SpellAddBuff(fervor fervor=1)
Define(focus_fire 82692)
  SpellInfo(focus_fire duration=20 )
  SpellAddBuff(focus_fire focus_fire=1)
Define(glaive_toss 120761)
  SpellInfo(glaive_toss duration=3 )
  SpellAddBuff(glaive_toss glaive_toss=1)
Define(hunters_mark 1130)
  SpellInfo(hunters_mark duration=300 )
  SpellAddTargetDebuff(hunters_mark hunters_mark=1)
Define(kill_command 34026)
  SpellInfo(kill_command focus=40 cd=6 )
  SpellAddBuff(kill_command kill_command=1)
Define(kill_shot 53351)
  SpellInfo(kill_shot cd=10 )
Define(lock_and_load 56343)
Define(lynx_rush 120697)
  SpellInfo(lynx_rush duration=4 cd=90 )
Define(master_marksman_fire 82926)
  SpellInfo(master_marksman_fire duration=10 )
  SpellAddBuff(master_marksman_fire master_marksman_fire=1)
Define(multi_shot 2643)
  SpellInfo(multi_shot focus=40 )
Define(pet_frenzy 19615)
  SpellInfo(pet_frenzy duration=30 )
  SpellAddBuff(pet_frenzy pet_frenzy=1)
Define(powershot 109259)
  SpellInfo(powershot focus=20 cd=60 )
Define(rapid_fire 3045)
  SpellInfo(rapid_fire duration=15 cd=180 )
  SpellAddBuff(rapid_fire rapid_fire=1)
Define(readiness 23989)
  SpellInfo(readiness cd=300 )
Define(serpent_sting 1978)
  SpellInfo(serpent_sting focus=25 )
  SpellAddTargetDebuff(serpent_sting serpent_sting_aura=1)
Define(serpent_sting_aura 118253)
  SpellInfo(serpent_sting_aura duration=15 tick=3 )
  SpellAddTargetDebuff(serpent_sting_aura serpent_sting_aura=1)
Define(stampede 57386)
  SpellInfo(stampede duration=30 cd=15 )
  SpellAddBuff(stampede stampede=1)
Define(steady_focus 53224)
Define(steady_shot 56641)
  SpellInfo(steady_shot focus=-14 )
Define(thrill_of_the_hunt 34720)
  SpellInfo(thrill_of_the_hunt duration=15 )
  SpellAddBuff(thrill_of_the_hunt thrill_of_the_hunt=1)
Define(trueshot_aura 19506)
  SpellAddBuff(trueshot_aura trueshot_aura=1)
AddIcon mastery=1 help=main
{
	if not InCombat() 
	{
		if target.DeadIn() >=21 and not target.DebuffPresent(ranged_vulnerability any=1) Spell(hunters_mark)
		Spell(call_pet_1)
	}
	if BuffStacks(pet_frenzy any=1)>4 Spell(focus_fire)
	if not target.DebuffPresent(serpent_sting_aura) Spell(serpent_sting)
	if SpellUsable(fervor) and not target.DebuffPresent(fervor) and Focus() <=65 Spell(fervor)
	if Enemies() >5 Spell(cobra_shot)
	if target.HealthPercent(less 20) Spell(kill_shot)
	Spell(kill_command)
	if SpellUsable(dire_beast) and Focus() <=90 Spell(dire_beast)
	if SpellUsable(barrage) Spell(barrage)
	if SpellUsable(powershot) Spell(powershot)
	if SpellUsable(blink_strike) Spell(blink_strike)
	if BuffPresent(thrill_of_the_hunt) Spell(arcane_shot)
	if not target.DebuffPresent(focus_fire) and not BuffPresent(beast_within) if BuffStacks(pet_frenzy any=1)>4 Spell(focus_fire)
	if target.DebuffRemains(serpent_sting_aura) <6 Spell(cobra_shot)
	if Focus() >=61 or BuffPresent(beast_within) Spell(arcane_shot)
	Spell(cobra_shot)
}
AddIcon mastery=1 help=offgcd
{
	if not InCombat() 
	{
		Spell(trueshot_aura)
	}
	unless Stance(1) Spell(aspect_of_the_hawk)
	unless Stance(2) Spell(aspect_of_the_fox)
	if Focus() >60 and not BuffPresent(beast_within) Spell(bestial_wrath)
	Spell(stampede)
	if SpellUsable(a_murder_of_crows) and not target.DebuffPresent(a_murder_of_crows) Spell(a_murder_of_crows)
	if SpellUsable(glaive_toss) Spell(glaive_toss)
}
AddIcon mastery=1 help=aoe
{
	Spell(explosive_trap)
	Spell(multi_shot)
}
AddIcon mastery=1 help=cd
{
	Spell(blood_fury)
	if not BuffPresent(rapid_fire) Spell(rapid_fire)
	if SpellUsable(lynx_rush) and not target.DebuffPresent(lynx_rush) Spell(lynx_rush)
	if BuffPresent(rapid_fire) Spell(readiness)
}
AddIcon mastery=2 help=main
{
	if not InCombat() 
	{
		if target.DeadIn() >=21 and not target.DebuffPresent(ranged_vulnerability any=1) Spell(hunters_mark)
		Spell(call_pet_1)
	}
	if SpellUsable(powershot) Spell(powershot)
	if SpellUsable(barrage) Spell(barrage)
	if SpellUsable(blink_strike) Spell(blink_strike)
	if Enemies() >5 Spell(steady_shot)
	if not target.DebuffPresent(serpent_sting_aura) and target.HealthPercent() <=90 Spell(serpent_sting)
	if target.HealthPercent() <=90 Spell(chimera_shot)
	if SpellUsable(dire_beast) Spell(dire_beast)
	if PreviousSpell(steady_shot) and BuffRemains(steady_focus) <3 Spell(steady_shot)
	if target.HealthPercent(less 20) Spell(kill_shot)
	if BuffPresent(master_marksman_fire) Spell(aimed_shot)
	if BuffPresent(thrill_of_the_hunt) Spell(arcane_shot)
	if target.HealthPercent() >90 or BuffPresent(rapid_fire) or BuffPresent(bloodlust) Spell(aimed_shot)
	if {Focus() >=66 or SpellCooldown(chimera_shot) >=5 } and {target.HealthPercent() <90 and not BuffPresent(rapid_fire) and not BuffPresent(bloodlust) } Spell(arcane_shot)
	if SpellUsable(fervor) and Focus() <=50 Spell(fervor)
	Spell(steady_shot)
}
AddIcon mastery=2 help=offgcd
{
	if not InCombat() 
	{
		Spell(trueshot_aura)
	}
	unless Stance(1) Spell(aspect_of_the_hawk)
	unless Stance(2) Spell(aspect_of_the_fox)
	if SpellUsable(glaive_toss) Spell(glaive_toss)
	Spell(stampede)
	if SpellUsable(a_murder_of_crows) and not target.DebuffPresent(a_murder_of_crows) Spell(a_murder_of_crows)
}
AddIcon mastery=2 help=aoe
{
	Spell(explosive_trap)
	Spell(multi_shot)
}
AddIcon mastery=2 help=cd
{
	Spell(blood_fury)
	if SpellUsable(lynx_rush) and not target.DebuffPresent(lynx_rush) Spell(lynx_rush)
	if not BuffPresent(rapid_fire) Spell(rapid_fire)
	if BuffPresent(rapid_fire) Spell(readiness)
}
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		if target.DeadIn() >=21 and not target.DebuffPresent(ranged_vulnerability any=1) Spell(hunters_mark)
		Spell(call_pet_1)
	}
	if SpellUsable(blink_strike) Spell(blink_strike)
	if BuffPresent(lock_and_load) Spell(explosive_shot)
	if SpellUsable(powershot) Spell(powershot)
	if SpellUsable(barrage) Spell(barrage)
	if Enemies() >2 Spell(cobra_shot)
	if not target.DebuffPresent(serpent_sting_aura) and target.DeadIn() >=10 Spell(serpent_sting)
	if SpellCooldown(explosive_shot) Spell(explosive_shot)
	if target.HealthPercent(less 20) Spell(kill_shot)
	if not target.DebuffPresent(black_arrow) and target.DeadIn() >=8 Spell(black_arrow)
	if SpellUsable(dire_beast) Spell(dire_beast)
	if SpellUsable(fervor) and Focus() <=50 Spell(fervor)
	if target.DebuffRemains(serpent_sting_aura) <6 Spell(cobra_shot)
	if Focus() >=67 Spell(arcane_shot)
	Spell(cobra_shot)
}
AddIcon mastery=3 help=offgcd
{
	if not InCombat() 
	{
		Spell(trueshot_aura)
	}
	unless Stance(1) Spell(aspect_of_the_hawk)
	unless Stance(2) Spell(aspect_of_the_fox)
	if SpellUsable(a_murder_of_crows) and not target.DebuffPresent(a_murder_of_crows) Spell(a_murder_of_crows)
	if SpellUsable(glaive_toss) Spell(glaive_toss)
	Spell(stampede)
}
AddIcon mastery=3 help=aoe
{
	Spell(explosive_trap)
	Spell(multi_shot)
	if BuffPresent(thrill_of_the_hunt) Spell(multi_shot)
}
AddIcon mastery=3 help=cd
{
	Spell(blood_fury)
	if SpellUsable(lynx_rush) and not target.DebuffPresent(lynx_rush) Spell(lynx_rush)
	if not BuffPresent(rapid_fire) Spell(rapid_fire)
	if BuffPresent(rapid_fire) Spell(readiness)
}
]]