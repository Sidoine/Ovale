Ovale.defaut["MAGE"] = [[Define(alter_time 110909)
  SpellInfo(alter_time duration=6 )
  SpellAddBuff(alter_time alter_time=1)
Define(alter_time_activate 108978)
  SpellInfo(alter_time_activate duration=10 cd=180 )
Define(arcane_barrage 44425)
  SpellInfo(arcane_barrage cd=3 )
Define(arcane_blast 30451)
Define(arcane_brilliance 1459)
  SpellInfo(arcane_brilliance duration=3600 )
  SpellAddBuff(arcane_brilliance arcane_brilliance=1)
Define(arcane_charge 36032)
  SpellInfo(arcane_charge duration=10 )
  SpellAddBuff(arcane_charge arcane_charge=1)
Define(arcane_missiles 7268)
Define(arcane_missiles_aura 79683)
  SpellInfo(arcane_missiles_aura duration=20 )
  SpellAddBuff(arcane_missiles_aura arcane_missiles_aura=1)
Define(arcane_power 12042)
  SpellInfo(arcane_power duration=15 cd=90 )
  SpellAddBuff(arcane_power arcane_power=1)
Define(berserking 26297)
  SpellInfo(berserking duration=10 cd=180 )
  SpellAddBuff(berserking berserking=1)
Define(blood_fury 20572)
  SpellInfo(blood_fury duration=15 cd=120 )
  SpellAddBuff(blood_fury blood_fury=1)
Define(brain_freeze 44549)
Define(cold_snap 11958)
  SpellInfo(cold_snap cd=180 )
Define(combustion 11129)
  SpellInfo(combustion cd=45 )
Define(conjure_mana_gem 759)
Define(counterspell 2139)
  SpellInfo(counterspell duration=6 cd=24 )
Define(evocation 12051)
  SpellInfo(evocation duration=6 cd=120 )
  SpellAddBuff(evocation evocation=1)
Define(fingers_of_frost_aura 44544)
  SpellInfo(fingers_of_frost_aura duration=15 )
  SpellAddBuff(fingers_of_frost_aura fingers_of_frost_aura=1)
Define(fire_blast 2136)
  SpellInfo(fire_blast cd=8 )
Define(fireball 133)
Define(frost_armor 7302)
  SpellAddBuff(frost_armor frost_armor=1)
Define(frost_bomb 113092)
  SpellInfo(frost_bomb duration=2 )
  SpellAddBuff(frost_bomb frost_bomb=1)
Define(frostbolt 116)
  SpellInfo(frostbolt duration=15 )
  SpellAddBuff(frostbolt frostbolt=1)
Define(frostfire_bolt 44614)
  SpellInfo(frostfire_bolt duration=8 )
  SpellAddBuff(frostfire_bolt frostfire_bolt=1)
Define(frozen_orb 84714)
  SpellInfo(frozen_orb duration=10 cd=60 )
Define(heating_up 48107)
  SpellInfo(heating_up duration=10 )
  SpellAddBuff(heating_up heating_up=1)
Define(ice_lance 30455)
Define(icy_veins 12472)
  SpellInfo(icy_veins duration=20 cd=180 )
  SpellAddBuff(icy_veins icy_veins=1)
Define(ignite 12654)
  SpellInfo(ignite duration=4 tick=2 )
  SpellAddTargetDebuff(ignite ignite=1)
Define(inferno_blast 108853)
  SpellInfo(inferno_blast cd=8 )
Define(invocation 114003)
Define(mage_armor 6117)
  SpellAddBuff(mage_armor mage_armor=1)
Define(mana_gem 56597)
Define(mirror_image 55342)
  SpellInfo(mirror_image duration=30 cd=180 )
  SpellAddBuff(mirror_image mirror_image=1)
Define(molten_armor 30482)
  SpellAddBuff(molten_armor molten_armor=1)
Define(nether_tempest 114923)
  SpellInfo(nether_tempest duration=12 tick=1 )
  SpellAddTargetDebuff(nether_tempest nether_tempest=1)
Define(presence_of_mind 12043)
  SpellInfo(presence_of_mind cd=90 )
  SpellAddBuff(presence_of_mind presence_of_mind=1)
Define(pyroblast 11366)
  SpellInfo(pyroblast duration=18 tick=3 )
  SpellAddTargetDebuff(pyroblast pyroblast=1)
Define(pyroblast_aura 48108)
  SpellInfo(pyroblast_aura duration=15 )
  SpellAddBuff(pyroblast_aura pyroblast_aura=1)
Define(rune_of_power 116011)
  SpellInfo(rune_of_power duration=60 cd=6 )
Define(time_warp 35346)
  SpellInfo(time_warp duration=6 cd=15 )
  SpellAddBuff(time_warp time_warp=1)
Define(water_elemental 63859)
Define(water_elemental_freeze 33395)
  SpellInfo(water_elemental_freeze duration=8 cd=25 )
  SpellAddBuff(water_elemental_freeze water_elemental_freeze=1)
AddIcon mastery=1 help=main
{
	if not InCombat() 
	{
		Spell(arcane_brilliance)
		Spell(mage_armor)
		Spell(rune_of_power)
	}
	if ItemCharges(36799) <3 and False() Spell(conjure_mana_gem)
	if BuffPresent(alter_time) and BuffPresent(presence_of_mind) Spell(arcane_blast)
	if not target.DebuffPresent(nether_tempest) Spell(nether_tempest)
	if BuffExpires(rune_of_power) and BuffExpires(alter_time) Spell(rune_of_power)
	if not target.DebuffPresent(nether_tempest) Spell(nether_tempest)
	if ManaPercent() >92 Spell(arcane_blast)
	if BuffPresent(arcane_charge) and BuffExpires(arcane_power) and BuffExpires(alter_time) and target.DeadIn() >25 and {ManaPercent() <92 or SpellCooldown(mana_gem) >10 or ItemCharges(36799) ==0 } Spell(arcane_barrage)
	if BuffStacks(arcane_charge) ==6 and BuffExpires(arcane_missiles_aura) and target.DeadIn() >25 Spell(arcane_barrage)
	Spell(arcane_blast)
}
AddIcon mastery=1 help=offgcd
{
	if target.IsInterruptible() if target.IsInterruptible() Spell(counterspell)
	if target.HealthPercent() <25 or TimeInCombat() >5 Spell(time_warp)
	if BuffExpires(alter_time) and BuffPresent(arcane_power) and BuffStacks(arcane_missiles_aura) ==2 and BuffStacks(arcane_charge) >3 and BuffRemains(rune_of_power) >6 Spell(alter_time)
	if BuffPresent(alter_time) or BuffStacks(arcane_missiles_aura) ==2 Spell(arcane_missiles)
	if ManaPercent() <84 and BuffExpires(alter_time) Spell(mana_gem)
	if BuffPresent(arcane_missiles_aura) and {SpellCooldown(alter_time_activate) >4 or target.DeadIn() <10 } Spell(arcane_missiles)
}
AddIcon mastery=1 help=moving
{
	Spell(arcane_barrage)
	Spell(fire_blast)
	Spell(ice_lance)
}
AddIcon mastery=1 help=cd
{
	if target.DeadIn() <18 Spell(arcane_power)
	if target.DeadIn() <18 Spell(berserking)
	Spell(mirror_image)
	if BuffRemains(rune_of_power) >15 and BuffExpires(alter_time) and BuffStacks(arcane_charge) >1 Spell(arcane_power)
	if BuffRemains(rune_of_power) >10 and BuffExpires(alter_time) and BuffStacks(arcane_charge) >2 Spell(berserking)
	if BuffExpires(alter_time) Spell(presence_of_mind)
}
AddIcon mastery=2 help=main
{
	if not InCombat() 
	{
		Spell(arcane_brilliance)
		Spell(molten_armor)
	}
	if ItemCharges(36799) <3 and False() Spell(conjure_mana_gem)
	if BuffPresent(pyroblast_aura) and {SpellCooldown(alter_time_activate) >4 or BuffPresent(heating_up) } Spell(pyroblast)
	if BuffPresent(presence_of_mind) and SpellCooldown(alter_time_activate) >4 Spell(pyroblast)
	if BuffPresent(heating_up) and BuffExpires(pyroblast_aura) Spell(inferno_blast)
	if not target.DebuffPresent(nether_tempest) Spell(nether_tempest)
	Spell(fireball)
}
AddIcon mastery=2 help=offgcd
{
	if target.IsInterruptible() if target.IsInterruptible() Spell(counterspell)
	if target.HealthPercent() <25 or TimeInCombat() >5 Spell(time_warp)
	if target.DeadIn() <12 Spell(combustion)
	if ArmorSetParts(T14 more 4) and target.DebuffPresent(ignite) and target.DebuffPresent(pyroblast_aura) Spell(combustion)
	if not ArmorSetParts(T14 more 4) and LastSpellDamage(ignite) >=12000 and target.DebuffPresent(pyroblast_aura) Spell(combustion)
	if ManaPercent() <84 and BuffExpires(alter_time) Spell(mana_gem)
	if BuffExpires(alter_time) and BuffPresent(pyroblast_aura) and BuffRemains(invocation) >6 Spell(alter_time)
}
AddIcon mastery=2 help=moving
{
	Spell(inferno_blast)
	Spell(ice_lance)
}
AddIcon mastery=2 help=cd
{
	if not InCombat() 
	{
		Spell(evocation)
	}
	if BuffRemains(invocation) >10 and BuffExpires(alter_time) and ManaPercent() >28 Spell(berserking)
	if BuffExpires(invocation) and BuffExpires(alter_time) Spell(evocation)
	if target.DeadIn() <18 Spell(berserking)
	if ManaPercent() <10 and target.DeadIn() >=30 Spell(evocation)
	Spell(mirror_image)
	if BuffExpires(alter_time) Spell(presence_of_mind)
}
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		Spell(arcane_brilliance)
		Spell(frost_armor)
	}
	if ItemCharges(36799) <3 and False() Spell(conjure_mana_gem)
	if BuffPresent(alter_time) and BuffPresent(brain_freeze) Spell(frostfire_bolt)
	if BuffPresent(alter_time) and BuffPresent(fingers_of_frost_aura) Spell(ice_lance)
	if BuffPresent(alter_time) and BuffPresent(presence_of_mind) Spell(frostbolt)
	if BuffPresent(fingers_of_frost_aura) and BuffRemains(fingers_of_frost_aura) <5 Spell(ice_lance)
	if target.DeadIn() >=4 and BuffStacks(fingers_of_frost_aura) <2 and SpellCooldown(icy_veins) <GCD() and BuffRemains(invocation) >20 and BuffExpires(alter_time) Spell(frozen_orb)
	if BuffPresent(fingers_of_frost_aura) and BuffRemains(fingers_of_frost_aura) <2 Spell(ice_lance)
	if BuffPresent(brain_freeze) and {BuffPresent(alter_time) or SpellCooldown(alter_time_activate) >4 } Spell(frostfire_bolt)
	if BuffPresent(brain_freeze) and {BuffPresent(alter_time) or SpellCooldown(alter_time_activate) >4 } Spell(ice_lance)
	if BuffPresent(fingers_of_frost_aura) Spell(ice_lance)
	if target.DeadIn() >=4 and BuffStacks(fingers_of_frost_aura) <2 Spell(frozen_orb)
	Spell(frostbolt)
}
AddIcon mastery=3 help=offgcd
{
	if not InCombat() 
	{
		Spell(water_elemental)
	}
	if target.IsInterruptible() if target.IsInterruptible() Spell(counterspell)
	if target.HealthPercent() <25 or TimeInCombat() >5 Spell(time_warp)
	if BuffExpires(alter_time) and BuffStacks(fingers_of_frost_aura) <2 Spell(water_elemental_freeze)
	if not target.DebuffPresent(frost_bomb) Spell(frost_bomb)
	if BuffExpires(alter_time) and BuffPresent(brain_freeze) and BuffPresent(fingers_of_frost_aura) and BuffRemains(invocation) >6 Spell(alter_time)
	if BuffExpires(alter_time) and BuffPresent(brain_freeze) and BuffPresent(fingers_of_frost_aura) Spell(alter_time)
	if ManaPercent() <84 and BuffExpires(alter_time) Spell(mana_gem)
}
AddIcon mastery=3 help=moving
{
	Spell(fire_blast)
	Spell(ice_lance)
}
AddIcon mastery=3 help=cd
{
	if not InCombat() 
	{
		Spell(evocation)
	}
	if Health() <30 Spell(cold_snap)
	if BuffExpires(alter_time) Spell(presence_of_mind)
	if target.DeadIn() <22 Spell(icy_veins)
	if target.DeadIn() <12 Spell(blood_fury)
	if ArmorSetParts(T14 more 4) and BuffRemains(invocation) >20 and BuffExpires(alter_time) Spell(icy_veins)
	if not ArmorSetParts(T14 more 4) and target.DebuffPresent(frozen_orb) Spell(icy_veins)
	if target.DebuffPresent(frozen_orb) and BuffExpires(alter_time) Spell(icy_veins)
	Spell(mirror_image)
	if BuffExpires(invocation) and BuffExpires(alter_time) Spell(evocation)
	if BuffRemains(invocation) >15 and BuffExpires(alter_time) and ManaPercent() >28 Spell(blood_fury)
}
]]