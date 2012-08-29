Ovale.defaut["MONK"] = [[Define(berserking 26297)
  SpellInfo(berserking duration=10 cd=180 )
  SpellAddBuff(berserking berserking=1)
Define(blackout_kick 100784)
  SpellInfo(blackout_kick chi=2 )
Define(chi_burst 123986)
  SpellInfo(chi_burst chi=2 )
Define(chi_sphere 121286)
  SpellInfo(chi_sphere duration=120 )
Define(combo_breaker_bok 116768)
  SpellInfo(combo_breaker_bok duration=15 )
  SpellAddBuff(combo_breaker_bok combo_breaker_bok=1)
Define(combo_breaker_tp 118864)
  SpellInfo(combo_breaker_tp duration=15 )
  SpellAddBuff(combo_breaker_tp combo_breaker_tp=1)
Define(energizing_brew 115288)
  SpellInfo(energizing_brew duration=6 cd=60 )
  SpellAddBuff(energizing_brew energizing_brew=1)
Define(fists_of_fury 117418)
  SpellAddBuff(fists_of_fury fists_of_fury=1)
Define(invoke_xuen 123904)
  SpellInfo(invoke_xuen duration=45 cd=180 )
Define(jab 100780)
  SpellInfo(jab energy=40 chi=-1 )
Define(power_strikes 121817)
Define(rising_sun_kick 107428)
  SpellInfo(rising_sun_kick chi=2 cd=8 )
Define(rushing_jade_wind 116847)
  SpellInfo(rushing_jade_wind duration=8 chi=2 cd=30 )
  SpellAddBuff(rushing_jade_wind rushing_jade_wind=1)
Define(spinning_crane_kick 117640)
Define(tiger_palm 100787)
  SpellInfo(tiger_palm chi=1 )
Define(tiger_power 125359)
  SpellInfo(tiger_power duration=20 )
  SpellAddBuff(tiger_power tiger_power=1)
Define(tigereye_brew 125195)
  SpellInfo(tigereye_brew duration=120 )
  SpellAddBuff(tigereye_brew tigereye_brew=1)
Define(tigereye_brew_use 116740)
  SpellInfo(tigereye_brew_use duration=15 cd=1 )
  SpellAddBuff(tigereye_brew_use tigereye_brew_use=1)
Define(invoke_xuen_the_white_tiger_talent 17)
Define(power_strikes_talent 7)
Define(rushing_jade_wind_talent 16)
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		False() 
	}
	if not target.DebuffRemains(rising_sun_kick) or target.DebuffRemains(rising_sun_kick) <=3 Spell(rising_sun_kick)
	if Enemies() >5 
	{
		if TalentPoints(rushing_jade_wind_talent) Spell(rushing_jade_wind)
		if Chi() ==4 Spell(chi_burst)
	}
	
	{
		if BuffStacks(tiger_power) <3 or BuffRemains(tiger_power) <=3 or {BuffRemains(tiger_power) <=6 and SpellCooldown(fists_of_fury) <=1 } Spell(tiger_palm)
		Spell(rising_sun_kick)
		if BuffPresent(combo_breaker_bok) Spell(blackout_kick)
		if BuffPresent(combo_breaker_tp) and {Energy() <=90 or {BuffPresent(energizing_brew) and Energy() <=80 } or {BuffPresent(combo_breaker_tp) and BuffRemains(combo_breaker_tp) <=3 } } Spell(tiger_palm)
		if {Chi() <=2 and SpellCooldown(power_strikes) } or {Chi() <=1 and not SpellCooldown(power_strikes) } Spell(jab)
		if {BuffPresent(energizing_brew) and Energy() >=20 } or Energy() >=30 Spell(blackout_kick)
	}
}
AddIcon mastery=3 help=offgcd
{
	if TalentPoints(power_strikes_talent) and BuffPresent(chi_sphere) and Chi() <4 Spell(chi_sphere)
	if Enemies() >5 
	{
		if not BuffPresent(tigereye_brew_use) and BuffPresent(tigereye_brew) ==10 Spell(tigereye_brew_use)
		if not BuffPresent(tigereye_brew_use) and {BuffPresent(tigereye_brew) >=7 and {SpellCooldown(energizing_brew) <=2 or BuffPresent(energizing_brew) } } Spell(tigereye_brew_use)
		if Energy() <=35 Spell(energizing_brew)
		Spell(spinning_crane_kick)
	}
	
	{
		if not BuffPresent(tigereye_brew_use) and BuffPresent(tigereye_brew) ==10 Spell(tigereye_brew_use)
		if not BuffPresent(tigereye_brew_use) and {BuffPresent(tigereye_brew) >=7 and {SpellCooldown(energizing_brew) <=2 or BuffPresent(energizing_brew) } } Spell(tigereye_brew_use)
		if not BuffPresent(tigereye_brew_use) and SpellCooldown(energizing_brew) >=45 and SpellCooldown(energizing_brew) <=48 Spell(tigereye_brew_use)
		if Energy() <=35 Spell(energizing_brew)
		if not BuffPresent(energizing_brew) and Energy() <=65 and BuffRemains(tiger_power) >=6.5 Spell(fists_of_fury)
	}
}
AddIcon mastery=3 help=cd
{
	Spell(berserking)
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	
	{
		if TalentPoints(invoke_xuen_talent) Spell(invoke_xuen)
	}
}
]]