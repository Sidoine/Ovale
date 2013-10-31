local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "Ovale"
	local desc = "[5.2] Ovale: Windwalker"
	local code = [[
Define(berserking 26297)
  SpellInfo(berserking duration=10 cd=180 )
  SpellAddBuff(berserking berserking=1)
Define(blackout_kick 100784)
  SpellInfo(blackout_kick chi=2 )
Define(chi_brew 115399)
  SpellInfo(chi_brew chi=-4 cd=90 )
Define(chi_sphere 121286)
  SpellInfo(chi_sphere duration=120 )
Define(chi_wave 115098)
  SpellInfo(chi_wave cd=15 )
Define(combo_breaker_bok 116768)
  SpellInfo(combo_breaker_bok duration=15 )
  SpellAddBuff(combo_breaker_bok combo_breaker_bok=1)
Define(combo_breaker_tp 118864)
  SpellInfo(combo_breaker_tp duration=15 )
  SpellAddBuff(combo_breaker_tp combo_breaker_tp=1)
Define(energizing_brew 115288)
  SpellInfo(energizing_brew duration=6 cd=60 )
  SpellAddBuff(energizing_brew energizing_brew=1)
Define(fists_of_fury 113656)
  SpellInfo(fists_of_fury duration=4 chi=3 cd=25 )
  SpellAddBuff(fists_of_fury fists_of_fury=1)
Define(invoke_xuen 123904)
  SpellInfo(invoke_xuen duration=45 cd=180 )
Define(jab 100780)
  SpellInfo(jab energy=40 chi=-1 )
Define(rising_sun_kick 107428)
  SpellInfo(rising_sun_kick chi=2 cd=8 )
Define(rushing_jade_wind 116847)
  SpellInfo(rushing_jade_wind duration=8 chi=2 cd=30 )
  SpellAddBuff(rushing_jade_wind rushing_jade_wind=1)
Define(spinning_crane_kick 101546)
  SpellInfo(spinning_crane_kick duration=2.25 energy=40 )
  SpellAddBuff(spinning_crane_kick spinning_crane_kick=1)
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
Define(ascension_talent 8)
Define(chi_brew_talent 9)
Define(chi_wave_talent 4)
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
	if BuffRemains(tiger_power) <=3 Spell(tiger_palm)
	if TalentPoints(rushing_jade_wind_talent) Spell(rushing_jade_wind)
	
	if BuffStacks(combo_breaker_bok) and TimeToMaxEnergy() <=2 Spell(blackout_kick)
	Spell(rising_sun_kick)
	if not BuffPresent(energizing_brew) and TimeToMaxEnergy() >{4 } and BuffRemains(tiger_power) >{4 } Spell(fists_of_fury)
	if BuffStacks(combo_breaker_bok) Spell(blackout_kick)
	if {BuffStacks(combo_breaker_tp) and TimeToMaxEnergy() >=2 } or {BuffRemains(combo_breaker_tp) <=2 and BuffStacks(combo_breaker_tp) } Spell(tiger_palm)
	if TalentPoints(chi_wave_talent) and TimeToMaxEnergy() >2 Spell(chi_wave)
	if TalentPoints(ascension_talent) and Chi() <=3 Spell(jab)
	if not TalentPoints(ascension_talent) and Chi() <=2 Spell(jab)
	if {Energy() +{EnergyRegen() *{SpellCooldown(rising_sun_kick) } } } >=40 Spell(blackout_kick)

}
AddIcon mastery=3 help=offgcd
{
	if TalentPoints(power_strikes_talent) and BuffStacks(chi_sphere) and Chi() <4 Spell(chi_sphere)
	if not BuffPresent(tigereye_brew_use) Spell(tigereye_brew)
	if TimeToMaxEnergy() >5 Spell(energizing_brew)
}
AddIcon mastery=3 help=aoe
{
	
	if Chi() ==4 Spell(rising_sun_kick)
	Spell(spinning_crane_kick)

}
AddIcon mastery=3 help=cd
{
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	Spell(berserking)
	if TalentPoints(chi_brew_talent) and Chi() ==0 Spell(chi_brew)
	if TalentPoints(invoke_xuen_talent) Spell(invoke_xuen)
}
]]

	OvaleScripts:RegisterScript("MONK", name, desc, code)
end
