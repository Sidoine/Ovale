Ovale.defaut["DEATHKNIGHT"] = [[Define(army_of_the_dead 42650)
  SpellInfo(army_of_the_dead duration=4 frost=1 blood=1 unholy=1 runicpower=-300 xxx=0 cd=600 )
  SpellAddBuff(army_of_the_dead army_of_the_dead=1)
Define(blood_fury 20572)
  SpellInfo(blood_fury duration=15 cd=120 )
  SpellAddBuff(blood_fury blood_fury=1)
Define(blood_plague 55078)
  SpellInfo(blood_plague duration=30 tick=3 )
  SpellAddTargetDebuff(blood_plague blood_plague=1)
Define(blood_tap 45529)
Define(dark_transformation 63560)
  SpellInfo(dark_transformation duration=30 unholy=1 runicpower=-100 xxx=0 )
  SpellAddBuff(dark_transformation dark_transformation=1)
Define(death_coil 47541)
  SpellInfo(death_coil runicpower=400 )
Define(empower_rune_weapon 47568)
  SpellInfo(empower_rune_weapon runicpower=-250 xxx=0 cd=300 )
Define(festering_strike 85948)
  SpellInfo(festering_strike frost=1 blood=1 runicpower=-200 xxx=0 )
Define(frost_fever 55095)
  SpellInfo(frost_fever duration=30 tick=3 )
  SpellAddTargetDebuff(frost_fever frost_fever=1)
Define(frost_presence 48266)
  SpellAddBuff(frost_presence frost_presence=1)
Define(frost_strike 49143)
  SpellInfo(frost_strike runicpower=350 )
Define(horn_of_winter 57330)
  SpellInfo(horn_of_winter duration=300 runicpower=-100 xxx=0 cd=20 )
  SpellAddBuff(horn_of_winter horn_of_winter=1)
Define(howling_blast 49184)
  SpellInfo(howling_blast frost=1 runicpower=-100 xxx=0 )
Define(icy_touch 45477)
  SpellInfo(icy_touch frost=1 runicpower=-100 xxx=0 )
Define(mogu_power_potion_aura 105706)
  SpellInfo(mogu_power_potion_aura duration=25 cd=1 )
  SpellAddBuff(mogu_power_potion_aura mogu_power_potion_aura=1)
Define(obliterate 49020)
  SpellInfo(obliterate frost=1 unholy=1 runicpower=-200 xxx=0 )
Define(outbreak 77575)
  SpellInfo(outbreak runicpower=0 cd=60 )
Define(pillar_of_frost 51271)
  SpellInfo(pillar_of_frost duration=20 frost=1 runicpower=-100 xxx=0 cd=60 )
  SpellAddBuff(pillar_of_frost pillar_of_frost=1)
Define(plague_leech 123693)
  SpellInfo(plague_leech cd=25 )
Define(plague_strike 45462)
  SpellInfo(plague_strike unholy=1 runicpower=-100 xxx=0 )
Define(raise_dead 46584)
  SpellInfo(raise_dead cd=120 )
  SpellAddBuff(raise_dead raise_dead=1)
Define(rime 59057)
Define(scourge_strike 55090)
  SpellInfo(scourge_strike unholy=1 runicpower=-100 xxx=0 )
Define(soul_reaper 114867)
Define(sudden_doom 49530)
Define(summon_gargoyle 49206)
  SpellInfo(summon_gargoyle duration=40 runicpower=600 cd=180 )
  SpellAddBuff(summon_gargoyle summon_gargoyle=1)
Define(unholy_frenzy 49016)
  SpellInfo(unholy_frenzy duration=30 cd=180 )
  SpellAddBuff(unholy_frenzy unholy_frenzy=1)
Define(unholy_presence 48265)
  SpellAddBuff(unholy_presence unholy_presence=1)
Define(blood_tap_talent 13)
Define(plague_leech_talent 2)
AddIcon mastery=2 help=main
{
	if not InCombat() 
	{
		Spell(horn_of_winter)
		unless Stance(2) Spell(frost_presence)
	}
	if target.DebuffRemains(frost_fever) <=0 or target.DebuffRemains(blood_plague) <=0 Spell(outbreak)
	if not target.DebuffPresent(frost_fever) Spell(howling_blast)
	if not target.DebuffPresent(blood_plague) Spell(plague_strike)
	if TalentPoints(plague_leech_talent) and {{SpellCooldown(outbreak) <1 } or {BuffPresent(rime) and target.DebuffRemains(blood_plague) <3 and {RuneCount(unholy) >=1 or RuneCount(death) >=1 } } } Spell(plague_leech)
	if BuffPresent(rime) Spell(howling_blast)
	if RunicPower() >=76 Spell(frost_strike)
	if RuneCount(unholy) >=1 Spell(obliterate)
	Spell(howling_blast)
	Spell(frost_strike)
	Spell(obliterate)
	Spell(horn_of_winter)
}
AddIcon mastery=2 help=offgcd
{
	Spell(pillar_of_frost)
	if target.HealthPercent() <=35 Spell(soul_reaper)
	if TalentPoints(blood_tap_talent) Spell(blood_tap)
}
AddIcon mastery=2 help=cd
{
	if not InCombat() 
	{
		Spell(army_of_the_dead)
	}
	if TimeInCombat() >=10 Spell(blood_fury)
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	Spell(raise_dead)
	if target.DeadIn() <=60 and BuffPresent(mogu_power_potion_aura) Spell(empower_rune_weapon)
	Spell(empower_rune_weapon)
}
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		Spell(horn_of_winter)
		unless Stance(3) Spell(unholy_presence)
	}
	if target.DebuffRemains(frost_fever) <3 or target.DebuffRemains(blood_plague) <3 Spell(outbreak)
	if not target.DebuffPresent(frost_fever) Spell(icy_touch)
	if not target.DebuffPresent(blood_plague) Spell(plague_strike)
	if TalentPoints(plague_leech_talent) and {SpellCooldown(outbreak) <1 } Spell(plague_leech)
	Spell(dark_transformation)
	if RuneCount(unholy) ==2 and RunicPower() <90 Spell(scourge_strike)
	if RuneCount(blood) ==2 and RuneCount(frost) ==2 and RunicPower() <90 Spell(festering_strike)
	if RunicPower() >90 Spell(death_coil)
	if BuffPresent(sudden_doom) Spell(death_coil)
	Spell(scourge_strike)
	Spell(festering_strike)
	if SpellCooldown(summon_gargoyle) >8 Spell(death_coil)
	Spell(horn_of_winter)
}
AddIcon mastery=3 help=offgcd
{
	if target.HealthPercent() <=35.5 Spell(soul_reaper)
	if TalentPoints(blood_tap_talent) Spell(blood_tap)
}
AddIcon mastery=3 help=cd
{
	if not InCombat() 
	{
		Spell(army_of_the_dead)
		Spell(raise_dead)
	}
	if TimeInCombat() >=2 Spell(blood_fury)
	if TimeInCombat() >=4 Spell(unholy_frenzy)
	if TimeInCombat() >=4  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	Spell(summon_gargoyle)
	if target.DeadIn() <=60 and BuffPresent(mogu_power_potion_aura) Spell(empower_rune_weapon)
	Spell(empower_rune_weapon)
}
]]