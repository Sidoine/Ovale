Ovale.defaut["SHAMAN"] = [[Define(ancestral_swiftness 16188)
  SpellInfo(ancestral_swiftness cd=90 )
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
Define(earthquake 61882)
  SpellInfo(earthquake duration=10 cd=10 )
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
Define(fire_nova 1535)
  SpellInfo(fire_nova cd=4 )
Define(flame_shock 8050)
  SpellInfo(flame_shock duration=24 tick=3 sharedcd=shock cd=6 )
  SpellAddTargetDebuff(flame_shock flame_shock=1)
Define(flametongue_weapon 8024)
Define(heroism 32182)
  SpellInfo(heroism duration=40 cd=300 )
  SpellAddBuff(heroism heroism=1)
Define(lava_beam 114074)
Define(lava_burst 51505)
  SpellInfo(lava_burst cd=8 )
Define(lava_lash 60103)
  SpellInfo(lava_lash cd=10 )
Define(lightning_bolt 403)
Define(lightning_shield 324)
  SpellInfo(lightning_shield duration=3600 )
  SpellAddBuff(lightning_shield lightning_shield=1)
Define(maelstrom_weapon 53817)
  SpellInfo(maelstrom_weapon duration=30 )
  SpellAddBuff(maelstrom_weapon maelstrom_weapon=1)
Define(magma_totem 8187)
Define(searing_totem 3599)
  SpellInfo(searing_totem duration=60 )
Define(spiritwalkers_grace 79206)
  SpellInfo(spiritwalkers_grace duration=15 cd=120 )
  SpellAddBuff(spiritwalkers_grace spiritwalkers_grace=1)
Define(stormblast 115356)
  SpellInfo(stormblast duration=15 sharedcd=strike cd=8 )
  SpellAddBuff(stormblast stormblast=1)
Define(stormlash 120687)
Define(stormlash_totem 120668)
  SpellInfo(stormlash_totem duration=10 cd=300 )
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
		if WeaponEnchantExpires(mainhand) main.Spell(flametongue_weapon)
		if not BuffPresent(lightning_shield) Spell(lightning_shield)
	}
	
	if TalentPoints(unleashed_fury_talent) and not BuffPresent(ascendance) Spell(unleash_elements)
	if target.DebuffRemains(flame_shock) >CastTime(lava_burst) and {BuffPresent(ascendance) or SpellCooldown(lava_burst) } Spell(lava_burst)
	if target.TicksRemain(flame_shock) <3 and {target.TicksRemain(flame_shock) <2 or BuffPresent(bloodlust any=1) or BuffPresent(elemental_mastery) } Spell(flame_shock)
	if TalentPoints(elemental_blast_talent) Spell(elemental_blast)
	if BuffStacks(lightning_shield) ==7 Spell(earth_shock)
	if BuffStacks(lightning_shield) >3 and target.DebuffRemains(flame_shock) >SpellCooldown(earth_shock) and target.DebuffRemains(flame_shock) <SpellCooldown(earth_shock) +TickTime(flame_shock) Spell(earth_shock)
	if SpellCooldown(fire_elemental_totem) >15 and not TotemPresent(fire) Spell(searing_totem)
	Spell(lightning_bolt)

}
AddIcon mastery=1 help=offgcd
{
	if target.IsInterruptible() Spell(wind_shear)
}
AddIcon mastery=1 help=moving
{
	
	Spell(unleash_elements)

}
AddIcon mastery=1 help=aoe
{
	
	Spell(lava_beam)
	if not TotemPresent(fire) Spell(magma_totem)
	if Enemies() <=2 and not TotemPresent(fire) Spell(searing_totem)
	if Enemies() <3 and target.DebuffRemains(flame_shock) >CastTime(lava_burst) and SpellCooldown(lava_burst) Spell(lava_burst)
	if not target.DebuffPresent(flame_shock) and Enemies() <3 Spell(flame_shock)
	Spell(earthquake)
	if ManaPercent() <80 Spell(thunderstorm)
	if ManaPercent() >10 Spell(chain_lightning)
	Spell(lightning_bolt)

}
AddIcon mastery=1 help=cd
{
	if target.HealthPercent() <25 or TimeInCombat() >5 { Spell(bloodlust) Spell(heroism) }
	if not TotemPresent(air) and not BuffPresent(stormlash) and {BuffPresent(bloodlust any=1) or TimeInCombat() >=60 } Spell(stormlash_totem)
	
	if {{SpellCooldown(ascendance) >10 or Level() <87 } and SpellCooldown(fire_elemental_totem) >10 } or BuffPresent(ascendance) or BuffPresent(bloodlust any=1) or TotemPresent(fire)  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	if BuffPresent(bloodlust any=1) or BuffPresent(ascendance) or {{SpellCooldown(ascendance) >10 or Level() <87 } and SpellCooldown(fire_elemental_totem) >10 } Spell(blood_fury)
	if TalentPoints(elemental_mastery_talent) and TimeInCombat() >15 and {{not BuffPresent(bloodlust any=1) and TimeInCombat() <120 } or {not BuffPresent(berserking) and not BuffPresent(bloodlust any=1) and BuffPresent(ascendance) } or {TimeInCombat() >=200 and {SpellCooldown(ascendance) >30 or Level() <87 } } } Spell(elemental_mastery)
	if not TotemPresent(fire) Spell(fire_elemental_totem)
	if target.DebuffRemains(flame_shock) >0 and {target.DeadIn() <20 or BuffPresent(bloodlust any=1) or TimeInCombat() >=180 } and SpellCooldown(lava_burst) >0 Spell(ascendance)
	if TalentPoints(ancestral_swiftness_talent) and not BuffPresent(ascendance) Spell(ancestral_swiftness)
	if not TotemPresent(earth) and SpellCooldown(fire_elemental_totem) >=50 Spell(earth_elemental_totem)
	Spell(spiritwalkers_grace)

}
AddIcon mastery=2 help=main
{
	if not InCombat() 
	{
		if WeaponEnchantExpires(mainhand) main.Spell(windfury_weapon)
		if WeaponEnchantExpires(offhand) off.Spell(flametongue_weapon)
		if not BuffPresent(lightning_shield) Spell(lightning_shield)
	}
	
	if not TotemPresent(fire) Spell(searing_totem)
	if TalentPoints(unleashed_fury_talent) Spell(unleash_elements)
	if TalentPoints(elemental_blast_talent) Spell(elemental_blast)
	if BuffStacks(maelstrom_weapon) ==5 Spell(lightning_bolt)
	Spell(stormblast)
	Spell(stormstrike)
	if BuffPresent(unleash_flame) and not target.DebuffPresent(flame_shock) Spell(flame_shock)
	Spell(lava_lash)
	if BuffPresent(unleash_flame) Spell(flame_shock)
	Spell(unleash_elements)
	if BuffStacks(maelstrom_weapon) >=3 and not BuffPresent(ascendance) Spell(lightning_bolt)
	if BuffPresent(ancestral_swiftness) Spell(lightning_bolt)
	Spell(earth_shock)
	if BuffStacks(maelstrom_weapon) >1 and not BuffPresent(ascendance) Spell(lightning_bolt)

}
AddIcon mastery=2 help=offgcd
{
	if target.IsInterruptible() Spell(wind_shear)
}
AddIcon mastery=2 help=aoe
{
	
	if not TotemPresent(fire) Spell(magma_totem)
	if Enemies() <=5 and not TotemPresent(fire) Spell(searing_totem)
	if {Enemies() <=5 and DebuffCount(flame_shock) ==Enemies() } or DebuffCount(flame_shock) >=5 Spell(fire_nova)
	if target.DebuffPresent(flame_shock) Spell(lava_lash)
	if BuffStacks(maelstrom_weapon) >=3 Spell(chain_lightning)
	Spell(unleash_elements)
	if not target.DebuffPresent(flame_shock) Spell(flame_shock)
	Spell(stormblast)
	Spell(stormstrike)
	if BuffStacks(maelstrom_weapon) ==5 and SpellCooldown(chain_lightning) >=2 Spell(lightning_bolt)
	if BuffStacks(maelstrom_weapon) >1 Spell(chain_lightning)
	if BuffStacks(maelstrom_weapon) >1 Spell(lightning_bolt)

}
AddIcon mastery=2 help=cd
{
	if target.HealthPercent() <25 or TimeInCombat() >5 { Spell(bloodlust) Spell(heroism) }
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	if not TotemPresent(air) and not BuffPresent(stormlash) and {BuffPresent(bloodlust any=1) or TimeInCombat() >=60 } Spell(stormlash_totem)
	
	Spell(blood_fury)
	if TalentPoints(elemental_mastery_talent) Spell(elemental_mastery)
	if not TotemPresent(fire) and {BuffPresent(bloodlust any=1) or BuffPresent(elemental_mastery) or target.DeadIn() <=0 +10 or {TalentPoints(elemental_mastery_talent) and {SpellCooldown(elemental_mastery) ==0 or SpellCooldown(elemental_mastery) >80 } or TimeInCombat() >=60 } } Spell(fire_elemental_totem)
	if SpellCooldown(strike) >=3 Spell(ascendance)
	if TalentPoints(ancestral_swiftness_talent) and BuffStacks(maelstrom_weapon) <2 Spell(ancestral_swiftness)
	Spell(feral_spirit)
	if not TotemPresent(earth) and SpellCooldown(fire_elemental_totem) >=50 Spell(earth_elemental_totem)
	Spell(spiritwalkers_grace)

}
]]