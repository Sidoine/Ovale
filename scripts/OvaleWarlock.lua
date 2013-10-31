local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.2] Ovale: Affliction, Demonology, Destruction"
	local code = [[
Define(agony 980)
  SpellInfo(agony duration=24 tick=2 haste=spell )
  SpellAddTargetDebuff(agony agony=1)
Define(backdraft 117896)
Define(blood_fury 20572)
  SpellInfo(blood_fury duration=15 cd=120 )
  SpellAddBuff(blood_fury blood_fury=1)
Define(chaos_bolt 116858)
  SpellInfo(chaos_bolt burningembers=10 tick=1 haste=spell )
  SpellAddTargetDebuff(chaos_bolt chaos_bolt=1)
Define(conflagrate 17962)
  SpellInfo(conflagrate duration=5 )
  SpellAddBuff(conflagrate conflagrate=1)
Define(corruption 172)
  SpellInfo(corruption duration=18 tick=2 haste=spell stance=0)
  SpellAddTargetDebuff(corruption corruption=1)
Define(curse_of_the_elements 1490)
  SpellInfo(curse_of_the_elements duration=300 )
  SpellAddTargetDebuff(curse_of_the_elements aura_of_the_elements=1)
Define(dark_intent 109773)
  SpellInfo(dark_intent duration=3600 )
  SpellAddBuff(dark_intent dark_intent=1)
Define(dark_soul_instability 113858)
  SpellInfo(dark_soul_instability duration=20 cd=120 )
  SpellAddBuff(dark_soul_instability dark_soul_instability=1)
Define(dark_soul_knowledge 113861)
  SpellInfo(dark_soul_knowledge duration=20 cd=120 )
  SpellAddBuff(dark_soul_knowledge dark_soul_knowledge=1)
Define(dark_soul_misery 113860)
  SpellInfo(dark_soul_misery duration=20 cd=120 )
  SpellAddBuff(dark_soul_misery dark_soul_misery=1)
Define(doom 603)
  SpellInfo(doom duration=60 demonicfury=60 tick=15 haste=spell stance=1)
  SpellAddTargetDebuff(doom doom=1)
Define(drain_soul 1120)
  SpellInfo(drain_soul duration=12 tick=2 haste=spell canStopChannelling=1 )
  SpellAddTargetDebuff(drain_soul drain_soul=1)
Define(fel_flame 77799)
Define(felstorm 89751)
  SpellInfo(felstorm duration=6 energy=60 cd=45 )
  SpellAddBuff(felstorm felstorm=1)
Define(fire_and_brimstone 108683)
  SpellInfo(fire_and_brimstone burningembers=10 cd=1 )
  SpellAddBuff(fire_and_brimstone fire_and_brimstone=1)
Define(grimoire_of_sacrifice 108503)
  SpellInfo(grimoire_of_sacrifice duration=3600 cd=30 )
  SpellAddBuff(grimoire_of_sacrifice grimoire_of_sacrifice=1)
Define(hand_of_guldan 105174)
  SpellInfo(hand_of_guldan stance=0)
Define(haunt 48181)
  SpellInfo(haunt duration=8 tick=2 shards=1 )
  SpellAddBuff(haunt haunt=1)
Define(havoc 80240)
  SpellInfo(havoc duration=15 cd=25 )
  SpellAddBuff(havoc havoc=1)
Define(hellfire 1949)
  SpellInfo(hellfire duration=14 tick=1 haste=spell canStopChannelling=1 )
  SpellAddTargetDebuff(hellfire hellfire=1)
Define(immolate 348)
  SpellInfo(immolate duration=15 tick=3 haste=spell )
  SpellAddTargetDebuff(immolate immolate=1)
Define(immolate_aoe 108686)
  SpellInfo(immolate_aoe duration=15 tick=3 haste=spell )
SpellList(immolate_debuff immolate immolate_aoe)
Define(immolation_aura 104025)
  SpellInfo(immolation_aura duration=10 demonicfury=0 stance=1)
  SpellAddBuff(immolation_aura immolation_aura=1)
Define(incinerate 29722)
Define(life_tap 1454)
  SpellInfo(life_tap mana=-15 )
  SpellAddBuff(life_tap life_tap=1)
Define(malefic_grasp 103103)
  SpellInfo(malefic_grasp duration=4 tick=1 haste=spell canStopChannelling=1 )
  SpellAddTargetDebuff(malefic_grasp malefic_grasp=1)
Define(melee 103988)
  SpellInfo(melee stance=1)
Define(metamorphosis 103958)
  SpellInfo(metamorphosis demonicfury=0 cd=10 )
  SpellAddBuff(metamorphosis metamorphosis=1)
Define(molten_core 122355)
  SpellInfo(molten_core duration=30 )
  SpellAddBuff(molten_core molten_core=1)
Define(rain_of_fire 5740)
  SpellInfo(rain_of_fire duration=6 )
  SpellAddBuff(rain_of_fire rain_of_fire=1)
Define(rain_of_fire_aftermath 104232)
Define(seed_of_corruption 27243)
  SpellInfo(seed_of_corruption duration=18 tick=3 haste=spell )
  SpellAddTargetDebuff(seed_of_corruption seed_of_corruption=1)
Define(service_felguard 111898)
  SpellInfo(service_felguard cd=120 )
Define(service_felhunter 111897)
  SpellInfo(service_felhunter cd=120 )
Define(shadow_bolt 686)
  SpellInfo(shadow_bolt demonicfury=40 stance=0)
Define(shadowburn 17877)
  SpellInfo(shadowburn burningembers=10 )
Define(shadowflame 47960)
  SpellInfo(shadowflame duration=6 tick=1 haste=spell )
  SpellAddTargetDebuff(shadowflame shadowflame=1)
Define(skull_banner 114207)
  SpellInfo(skull_banner duration=10 cd=180 )
Define(soul_fire 6353)
  SpellAddBuff(soul_fire molten_core=-1)
Define(soul_swap 86121)
Define(soulburn 74434)
  SpellInfo(soulburn duration=30 shards=1 cd=1 )
  SpellAddBuff(soulburn soulburn=1)
Define(soulburn_seed_of_corruption 86664)
Define(summon_doomguard 18540)
  SpellInfo(summon_doomguard cd=600 )
Define(summon_felguard 30146)
  SpellInfo(summon_felguard demonicfury=0 )
Define(summon_felhunter 691)
  SpellInfo(summon_felhunter demonicfury=0 )
Define(summon_infernal 1122)
  SpellInfo(summon_infernal cd=600 )
Define(touch_of_chaos 103964)
  SpellInfo(touch_of_chaos demonicfury=40 stance=1)
Define(unstable_affliction 30108)
  SpellInfo(unstable_affliction duration=14 tick=2 haste=spell )
  SpellAddTargetDebuff(unstable_affliction unstable_affliction=1)
Define(void_ray 115422)
  SpellInfo(void_ray demonicfury=40 )
Define(wrathstorm 115831)
  SpellInfo(wrathstorm duration=6 energy=60 cd=45 )
  SpellAddBuff(wrathstorm wrathstorm=1)
Define(grimoire_of_sacrifice_talent 15)
Define(grimoire_of_service_talent 14)
AddIcon mastery=1 help=main
{
	if not InCombat() 
	{
		if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
		if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice) unless pet.CreatureFamily(Felhunter) Spell(summon_felhunter)
		if TalentPoints(grimoire_of_service_talent) Spell(service_felhunter)
	}
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
	if TalentPoints(grimoire_of_service_talent) Spell(service_felhunter)
	if BuffPresent(soulburn) Spell(soul_swap)
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt) <CastTime(haunt) +1 +TickTime(haunt) and SoulShards() and target.HealthPercent() <=20 Spell(haunt)
	if BuffExpires(dark_soul_misery) and BuffExpires(bloodlust any=1) and ManaPercent() <10 and target.HealthPercent() <=20 Spell(life_tap)
	if target.HealthPercent() <=20 Spell(drain_soul)
	if target.HealthPercent() <=20 Spell(life_tap)
	if target.DebuffRemains(agony) <GCD() and target.DebuffRemains(agony) +2 <SpellCooldown(dark_soul_misery) Spell(agony)
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt) <CastTime(haunt) +1 +TickTime(haunt) and {SoulShards() >2 or SpellCooldown(dark_soul_misery) >35 or {SoulShards() >1 and SpellCooldown(dark_soul_misery) <CastTime(haunt) } } and SoulShards() Spell(haunt)
	if target.DebuffRemains(corruption) <GCD() and target.DebuffRemains(corruption) <SpellCooldown(dark_soul_misery) Spell(corruption)
	if target.DebuffRemains(unstable_affliction) <GCD() +CastTime(unstable_affliction) and target.DebuffRemains(unstable_affliction) <SpellCooldown(dark_soul_misery) Spell(unstable_affliction)
	if target.TicksRemain(agony) <=2 and target.DebuffRemains(agony) +2 <SpellCooldown(dark_soul_misery) Spell(agony)
	if target.TicksRemain(corruption) <=2 and target.DebuffRemains(corruption) <SpellCooldown(dark_soul_misery) Spell(corruption)
	if {target.DebuffRemains(unstable_affliction) -CastTime(unstable_affliction) } /{BuffDuration(unstable_affliction) /Ticks(unstable_affliction) } <=2 and target.DebuffRemains(unstable_affliction) <SpellCooldown(dark_soul_misery) Spell(unstable_affliction)
	if SpellPower() >LastSpellSpellPower(agony) and target.TicksRemain(agony) <Ticks(agony) /2 and target.DebuffRemains(agony) +2 <SpellCooldown(dark_soul_misery) Spell(agony)
	if SpellPower() >LastSpellSpellPower(corruption) and target.TicksRemain(corruption) <Ticks(corruption) /2 and target.DebuffRemains(corruption) <SpellCooldown(dark_soul_misery) Spell(corruption)
	if SpellPower() >LastSpellSpellPower(unstable_affliction) and target.TicksRemain(unstable_affliction) <Ticks(unstable_affliction) /2 and target.DebuffRemains(unstable_affliction) <SpellCooldown(dark_soul_misery) Spell(unstable_affliction)
	if BuffExpires(dark_soul_misery) and BuffExpires(bloodlust any=1) and ManaPercent() <50 Spell(life_tap)
	Spell(malefic_grasp)
	Spell(life_tap)
}
AddIcon mastery=1 help=offgcd
{
	if not InCombat() 
	{
		if TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	}
	if BuffPresent(dark_soul_misery) and {target.TicksRemain(agony) <=Ticks(agony) /2 or target.TicksRemain(corruption) <=Ticks(corruption) /2 or target.TicksRemain(unstable_affliction) <=Ticks(unstable_affliction) /2 } and SoulShards() Spell(soulburn)
	if {target.TicksRemain(unstable_affliction) <=1 or target.TicksRemain(corruption) <=1 or target.TicksRemain(agony) <=1 } and SoulShards() and target.HealthPercent() <=20 Spell(soulburn)
	if SpellPower() >LastSpellSpellPower(unstable_affliction) and target.TicksRemain(unstable_affliction) <=Ticks(unstable_affliction) /2 and SoulShards() and target.HealthPercent() <=20 Spell(soulburn)
}
AddIcon mastery=1 help=moving
{
	if ManaPercent() <80 and ManaPercent() <target.HealthPercent() Spell(life_tap)
	Spell(fel_flame)
}
AddIcon mastery=1 help=aoe
{
	
	if BuffExpires(soulburn) and not target.DebuffPresent(soulburn_seed_of_corruption) and not InFlightToTarget(soulburn_seed_of_corruption) and SoulShards() Spell(soulburn)
	if BuffPresent(soulburn) and not target.DebuffPresent(agony) and not target.DebuffPresent(corruption) Spell(soul_swap)
	if BuffPresent(soulburn) and target.DebuffPresent(corruption) and not target.DebuffPresent(agony) Spell(soul_swap)
	if {BuffExpires(soulburn) and not InFlightToTarget(seed_of_corruption) and not target.DebuffPresent(seed_of_corruption) } or {BuffPresent(soulburn) and not target.DebuffPresent(soulburn_seed_of_corruption) and not InFlightToTarget(soulburn_seed_of_corruption) } Spell(seed_of_corruption)
	if not InFlightToTarget(haunt) and target.DebuffRemains(haunt) <CastTime(haunt) +1 and SoulShards() Spell(haunt)
	if ManaPercent() <70 Spell(life_tap)
	if not InFlightToTarget(fel_flame) Spell(fel_flame)

}
AddIcon mastery=1 help=cd
{
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	Spell(blood_fury)
	Spell(dark_soul_misery)
	Spell(summon_doomguard)
}
AddIcon mastery=2 help=main
{
	if not InCombat() 
	{
		if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
		if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice) unless pet.CreatureFamily(Felguard) Spell(summon_felguard)
		if TalentPoints(grimoire_of_service_talent) Spell(service_felguard)
	}
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
	if TalentPoints(grimoire_of_service_talent) Spell(service_felguard)
	if BuffPresent(metamorphosis) and target.DebuffPresent(corruption) and target.DebuffRemains(corruption) <1.5 Spell(touch_of_chaos)
	if BuffPresent(metamorphosis) and {target.TicksRemain(doom) <=1 or {target.TicksRemain(doom) +1 <Ticks(doom) and BuffPresent(dark_soul_knowledge) } } and target.DeadIn() >=30 Spell(doom)
	if BuffPresent(metamorphosis) and target.DebuffPresent(corruption) and target.DebuffRemains(corruption) <20 Spell(touch_of_chaos)
	if BuffPresent(metamorphosis) and BuffExpires(dark_soul_knowledge) and DemonicFury() <=650 and target.DeadIn() >30 if Stance(1) cancel.Texture(Spell_shadow_demonform)
	if BuffPresent(metamorphosis) and BuffStacks(molten_core) and {BuffRemains(dark_soul_knowledge) <CastTime(shadow_bolt) or BuffRemains(dark_soul_knowledge) >CastTime(soul_fire) } Spell(soul_fire)
	if BuffPresent(metamorphosis) Spell(touch_of_chaos)
	if not target.DebuffPresent(corruption) and target.DeadIn() >=6 Spell(corruption)
	if not InFlightToTarget(hand_of_guldan) and target.DebuffRemains(shadowflame) <1 +CastTime(shadow_bolt) Spell(hand_of_guldan)
	if BuffStacks(molten_core) and {BuffRemains(dark_soul_knowledge) <CastTime(shadow_bolt) or BuffRemains(dark_soul_knowledge) >CastTime(soul_fire) } Spell(soul_fire)
	if ManaPercent() <60 Spell(life_tap)
	Spell(shadow_bolt)
	Spell(life_tap)
}
AddIcon mastery=2 help=offgcd
{
	if not InCombat() 
	{
		if TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	}
	Spell(melee)
	Spell(felstorm)
	Spell(wrathstorm)
	if {BuffPresent(dark_soul_knowledge) and DemonicFury() /32 >BuffRemains(dark_soul_knowledge) } or target.DebuffRemains(corruption) <5 or not target.DebuffPresent(doom) or DemonicFury() >=950 or DemonicFury() /32 >target.DeadIn() unless Stance(1) Spell(metamorphosis)
}
AddIcon mastery=2 help=moving
{
	Spell(fel_flame)
}
AddIcon mastery=2 help=aoe
{
	
	if BuffPresent(metamorphosis) and target.DebuffRemains(corruption) >10 and DemonicFury() <=650 and BuffExpires(dark_soul_knowledge) and not target.DebuffPresent(immolation_aura) if Stance(1) cancel.Texture(Spell_shadow_demonform)
	if BuffPresent(metamorphosis) Spell(immolation_aura)
	if BuffPresent(metamorphosis) and target.DebuffRemains(corruption) <10 Spell(void_ray)
	if BuffPresent(metamorphosis) and {not target.DebuffPresent(doom) or target.DebuffRemains(doom) <TickTime(doom) or {target.TicksRemain(doom) +1 <Ticks(doom) and BuffPresent(dark_soul_knowledge) } } and target.DeadIn() >=30 Spell(doom)
	if BuffPresent(metamorphosis) Spell(void_ray)
	if not target.DebuffPresent(corruption) and target.DeadIn() >30 Spell(corruption)
	Spell(hand_of_guldan)
	if target.DebuffRemains(corruption) <10 or BuffPresent(dark_soul_knowledge) or DemonicFury() >=950 or DemonicFury() /32 >target.DeadIn() unless Stance(1) Spell(metamorphosis)
	Spell(hellfire)
	Spell(life_tap)

}
AddIcon mastery=2 help=cd
{
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	Spell(blood_fury)
	Spell(dark_soul_knowledge)
	Spell(summon_doomguard)
}
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		if not BuffPresent(spell_power_multiplier any=1) Spell(dark_intent)
		if not TalentPoints(grimoire_of_sacrifice_talent) or BuffExpires(grimoire_of_sacrifice) unless pet.CreatureFamily(Felhunter) Spell(summon_felhunter)
		if TalentPoints(grimoire_of_service_talent) Spell(service_felhunter)
	}
	if target.DebuffExpires(magic_vulnerability any=1) Spell(curse_of_the_elements)
	if TalentPoints(grimoire_of_service_talent) Spell(service_felhunter)
	if BurningEmbers() if target.HealthPercent(less 20) Spell(shadowburn)
	if {target.TicksRemain(immolate_debuff) <Ticks(immolate-debuff) /2 or target.DebuffExpires(immolate_debuff) } and target.DeadIn() >=5 Spell(immolate)
	if Charges(conflagrate) ==2 Spell(conflagrate)
	if not target.DebuffPresent(rain_of_fire_aftermath) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	if BurningEmbers() and {BuffStacks(backdraft) <3 or Level() <86 } and {{BurningEmbers() / 10} >3.5 or BuffRemains(dark_soul_instability) >CastTime(chaos_bolt) or BuffRemains(skull_banner) >CastTime(chaos_bolt) } Spell(chaos_bolt)
	Spell(conflagrate)
	Spell(incinerate)
}
AddIcon mastery=3 help=offgcd
{
	if not InCombat() 
	{
		if TalentPoints(grimoire_of_sacrifice_talent) Spell(grimoire_of_sacrifice)
	}
}
AddIcon mastery=3 help=aoe
{
	
	if not target.DebuffPresent(rain_of_fire_aftermath) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	if {BurningEmbers() / 10} >=3.5 and BurningEmbers() and target.HealthPercent() <=20 focus.Spell(havoc)
	if {BurningEmbers() / 10} >=3.5 and BurningEmbers() and BuffStacks(havoc) >=1 if target.HealthPercent(less 20) Spell(shadowburn)
	if BurningEmbers() and BuffExpires(fire_and_brimstone) Spell(fire_and_brimstone)
	if BuffPresent(fire_and_brimstone) and not target.DebuffPresent(immolate_debuff) Spell(immolate)
	if BuffPresent(fire_and_brimstone) Spell(conflagrate)
	if BuffPresent(fire_and_brimstone) Spell(incinerate)
	if not target.DebuffPresent(immolate_debuff) Spell(immolate)

	if not target.DebuffPresent(rain_of_fire_aftermath) and not InFlightToTarget(rain_of_fire_aftermath) Spell(rain_of_fire_aftermath)
	focus.Spell(havoc)
}
AddIcon mastery=3 help=cd
{
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	Spell(blood_fury)
	Spell(dark_soul_instability)
	Spell(summon_doomguard)
}
]]

	OvaleScripts:RegisterScript("WARLOCK", name, desc, code)
end
