Ovale.defaut["SHAMAN"] = [[Define(ancestral_swiftness 16188)
  SpellInfo(ancestral_swiftness cd=60 )
  SpellAddBuff(ancestral_swiftness ancestral_swiftness=1)
Define(ascendance 114049)
  SpellInfo(ascendance cd=180 )
Define(berserking 26297)
  SpellInfo(berserking duration=10 cd=180 )
  SpellAddBuff(berserking berserking=1)
Define(blood_fury 20572)
  SpellInfo(blood_fury duration=15 cd=120 )
  SpellAddBuff(blood_fury blood_fury=1)
Define(bloodlust 2825)
  SpellInfo(bloodlust duration=40 cd=300 )
  SpellAddBuff(bloodlust bloodlust=1)
Define(chain_lightning 421)
  SpellInfo(chain_lightning cd=3 )
Define(earth_elemental_totem 2062)
  SpellInfo(earth_elemental_totem duration=60 cd=300 )
Define(earth_shock 8042)
  SpellInfo(earth_shock sharedcd=shock cd=6 )
Define(earthquake 77478)
  SpellInfo(earthquake duration=3 )
  SpellAddBuff(earthquake earthquake=1)
Define(elemental_blast 117014)
  SpellInfo(elemental_blast cd=12 )
Define(elemental_mastery 16166)
  SpellInfo(elemental_mastery duration=20 cd=120 )
  SpellAddBuff(elemental_mastery elemental_mastery=1)
Define(feral_spirit 51533)
  SpellInfo(feral_spirit duration=30 cd=120 )
Define(fire_elemental_totem 2894)
  SpellInfo(fire_elemental_totem duration=60 cd=300 )
Define(fire_nova 8349)
Define(flame_shock 8050)
  SpellInfo(flame_shock duration=24 tick=3 sharedcd=shock cd=6 )
  SpellAddTargetDebuff(flame_shock flame_shock=1)
Define(flametongue_weapon 8024)
Define(lava_beam 114074)
Define(lava_burst 51505)
  SpellInfo(lava_burst cd=8 )
Define(lava_lash 60103)
  SpellInfo(lava_lash cd=10 )
Define(lightning_bolt 403)
Define(lightning_shield 26364)
  SpellInfo(lightning_shield cd=3 )
Define(maelstrom_weapon 51530)
Define(magma_totem 8187)
Define(searing_totem 3599)
  SpellInfo(searing_totem duration=60 )
Define(spiritwalkers_grace 79206)
  SpellInfo(spiritwalkers_grace duration=15 cd=120 )
  SpellAddBuff(spiritwalkers_grace spiritwalkers_grace=1)
Define(stormblast 115356)
  SpellInfo(stormblast duration=15 sharedcd=strike cd=8 )
  SpellAddBuff(stormblast stormblast=1)
Define(stormstrike 17364)
  SpellInfo(stormstrike duration=15 sharedcd=strike cd=8 )
  SpellAddBuff(stormstrike stormstrike=1)
Define(thunderstorm 51490)
  SpellInfo(thunderstorm duration=5 cd=45 )
  SpellAddBuff(thunderstorm thunderstorm=1)
Define(unleash_elements 73680)
  SpellInfo(unleash_elements cd=15 )
Define(unleash_flame 73683)
  SpellInfo(unleash_flame duration=8 )
  SpellAddBuff(unleash_flame unleash_flame=1)
Define(unleashed_fury_ft 118470)
  SpellInfo(unleashed_fury_ft duration=10 )
  SpellAddBuff(unleashed_fury_ft unleashed_fury_ft=1)
Define(wind_shear 57994)
  SpellInfo(wind_shear duration=3 cd=12 )
Define(windfury_weapon 8232)
Define(ancestral_swiftness_talent 11)
Define(elemental_blast_talent 18)
Define(elemental_mastery_talent 10)
Define(unleashed_fury_talent 16)
AddIcon mastery=1 help=main
{
	if not InCombat() 
	{
		main.Spell(flametongue_weapon)
	}
	
	{
		if TalentPoints(elemental_blast_talent) and not BuffPresent(ascendance) Spell(elemental_blast)
		if TalentPoints(unleashed_fury_talent) and not BuffPresent(ascendance) Spell(unleash_elements)
		if not BuffPresent(ascendance) and {not target.DebuffPresent(flame_shock) or TicksRemain(flame_shock) <2 or {{BuffPresent(bloodlust) or BuffPresent(elemental_mastery) } and TicksRemain(flame_shock) <3 } } Spell(flame_shock)
		if target.DebuffRemains(flame_shock) >CastTime(lava_burst) and {BuffPresent(ascendance) or SpellCooldown(lava_burst) } Spell(lava_burst)
		if BuffPresent(lightning_shield) ==0 Spell(earth_shock)
		if not TotemPresent(fire) Spell(searing_totem)
		Spell(lightning_bolt)
	}
	if Enemies() >1 
	{
		Spell(lava_beam)
		if not TotemPresent(fire) Spell(searing_totem)
		if not target.DebuffPresent(flame_shock) Spell(flame_shock)
		if target.DebuffRemains(flame_shock) >CastTime(lava_burst) and SpellCooldown(lava_burst) Spell(lava_burst)
		if ManaPercent() <80 Spell(thunderstorm)
		if ManaPercent() >10 Spell(chain_lightning)
		Spell(lightning_bolt)
	}
}
AddIcon mastery=1 help=offgcd
{
	if not InCombat() 
	{
		if not BuffPresent(lightning_shield) Spell(lightning_shield)
	}
	if target.IsInterruptible() Spell(wind_shear)
	
	{
		if TalentPoints(ancestral_swiftness_talent) and not BuffPresent(ascendance) Spell(ancestral_swiftness)
	}
	if Enemies() >1 
	{
		if Enemies() >2 and not TotemPresent(fire) Spell(magma_totem)
		if Enemies() >4 Spell(earthquake)
	}
}
AddIcon mastery=1 help=moving
{
	
	{
		Spell(unleash_elements)
	}
}
AddIcon mastery=1 help=cd
{
	if target.HealthPercent() <25 or TimeInCombat() >5 Spell(bloodlust)
	
	{
		if {{SpellCooldown(ascendance) >10 or Level() <87 } and SpellCooldown(fire_elemental_totem) >10 } or BuffPresent(ascendance) or BuffPresent(bloodlust) or TotemPresent(fire_elemental_totem)  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
		if BuffPresent(bloodlust) or BuffPresent(ascendance) or {{SpellCooldown(ascendance) >10 or Level() <87 } and SpellCooldown(fire_elemental_totem) >10 } Spell(blood_fury)
		if TalentPoints(elemental_mastery_talent) and TimeInCombat() >15 and {{not BuffPresent(bloodlust) and TimeInCombat() <120 } or {not BuffPresent(berserking) and not BuffPresent(bloodlust) and BuffPresent(ascendance) } or {TimeInCombat() >=200 and {SpellCooldown(ascendance) >30 or Level() <87 } } } Spell(elemental_mastery)
		if not TotemPresent(fire) Spell(fire_elemental_totem)
		if target.DebuffRemains(flame_shock) >0 and {target.DeadIn() <20 or BuffPresent(bloodlust) or TimeInCombat() >=180 } Spell(ascendance)
		if not Spell(earth_elemental_totem)
		Spell(spiritwalkers_grace)
	}
	if Enemies() >1 
	{
		Spell(ascendance)
	}
}
AddIcon mastery=2 help=main
{
	if not InCombat() 
	{
		main.Spell(windfury_weapon)
		off.Spell(flametongue_weapon)
	}
	
	{
		if not TotemPresent(fire) Spell(searing_totem)
		if TalentPoints(unleashed_fury_talent) Spell(unleash_elements)
		if TalentPoints(elemental_blast_talent) Spell(elemental_blast)
		if BuffPresent(maelstrom_weapon) ==5 or {ArmorSetParts(T13 more 4) ==1 and BuffPresent(maelstrom_weapon) >=4 and False() } Spell(lightning_bolt)
		Spell(stormblast)
		if BuffPresent(unleash_flame) and not target.DebuffPresent(flame_shock) Spell(flame_shock)
		Spell(stormstrike)
		Spell(lava_lash)
		Spell(unleash_elements)
		if BuffPresent(maelstrom_weapon) >=3 and target.DebuffPresent(unleashed_fury_ft) and not BuffPresent(ascendance) Spell(lightning_bolt)
		if BuffPresent(ancestral_swiftness) Spell(lightning_bolt)
		if BuffPresent(unleash_flame) and target.DebuffRemains(flame_shock) <=3 Spell(flame_shock)
		Spell(earth_shock)
		if BuffPresent(maelstrom_weapon) >1 and not BuffPresent(ascendance) Spell(lightning_bolt)
	}
	if Enemies() >1 
	{
		if not TotemPresent(fire) Spell(searing_totem)
		if target.DebuffPresent(flame_shock) Spell(lava_lash)
		if Enemies() >2 and BuffPresent(maelstrom_weapon) >=3 Spell(chain_lightning)
		Spell(unleash_elements)
		if not target.DebuffPresent(flame_shock) Spell(flame_shock)
		Spell(stormstrike)
		if BuffPresent(maelstrom_weapon) ==5 and SpellCooldown(chain_lightning) >=2 Spell(lightning_bolt)
		if Enemies() >2 and BuffPresent(maelstrom_weapon) >1 Spell(chain_lightning)
		if BuffPresent(maelstrom_weapon) >1 Spell(lightning_bolt)
	}
}
AddIcon mastery=2 help=offgcd
{
	if not InCombat() 
	{
		if not BuffPresent(lightning_shield) Spell(lightning_shield)
	}
	if target.IsInterruptible() Spell(wind_shear)
	
	{
		if TalentPoints(ancestral_swiftness_talent) and BuffPresent(maelstrom_weapon) <2 Spell(ancestral_swiftness)
	}
	if Enemies() >1 
	{
		if Enemies() >5 and not TotemPresent(fire) Spell(magma_totem)
		if {DebuffCount(flame_shock) ==Enemies() } or DebuffCount(flame_shock) >=5 Spell(fire_nova)
	}
}
AddIcon mastery=2 help=cd
{
	if target.HealthPercent() <25 or TimeInCombat() >5 Spell(bloodlust)
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	
	{
		Spell(blood_fury)
		if TalentPoints(elemental_mastery_talent) Spell(elemental_mastery)
		if not TotemPresent(fire) and {BuffPresent(bloodlust) or BuffPresent(elemental_mastery) or target.DeadIn() <=0 +10 or {TalentPoints(elemental_mastery_talent) and {SpellCooldown(elemental_mastery) ==0 or SpellCooldown(elemental_mastery) >80 } or TimeInCombat() >=60 } } Spell(fire_elemental_totem)
		if SpellCooldown(strike) >=3 Spell(ascendance)
		Spell(feral_spirit)
		if not Spell(earth_elemental_totem)
		Spell(spiritwalkers_grace)
	}
	if Enemies() >1 
	{
		Spell(blood_fury)
		Spell(ascendance)
		if not TotemPresent(fire) Spell(fire_elemental_totem)
		Spell(feral_spirit)
	}
}
]]