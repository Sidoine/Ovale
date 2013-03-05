local code = [[
Define(alter_time 110909)
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
Define(arcane_missiles 5143)
  SpellInfo(arcane_missiles duration=2 )
Define(arcane_missiles_aura 79683)
  SpellInfo(arcane_missiles_aura duration=20 )
  SpellAddBuff(arcane_missiles_aura arcane_missiles_aura=1)
Define(arcane_power 12042)
  SpellInfo(arcane_power duration=15 cd=90 )
  SpellAddBuff(arcane_power arcane_power=1)
Define(berserking 26297)
  SpellInfo(berserking duration=10 cd=180 )
  SpellAddBuff(berserking berserking=1)
Define(brain_freeze 44549)
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
Define(invokers_energy 116257)
  SpellInfo(invokers_energy duration=40 )
  SpellAddBuff(invokers_energy invokers_energy=1)
Define(living_bomb 44457)
  SpellInfo(living_bomb duration=12 tick=3 )
  SpellAddTargetDebuff(living_bomb living_bomb=1)
Define(mage_armor 6117)
  SpellAddBuff(mage_armor mage_armor=1)
Define(mana_gem 56597)
Define(mirror_image 55342)
  SpellInfo(mirror_image duration=30 cd=180 )
  SpellAddBuff(mirror_image mirror_image=1)
Define(molten_armor 30482)
  SpellAddBuff(molten_armor molten_armor=1)
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
  SpellInfo(rune_of_power duration=60 )
Define(scorch 2948)
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
		if BuffExpires(arcane_brilliance) Spell(arcane_brilliance)
		Spell(mage_armor)
		Spell(rune_of_power)
	}
	if ItemCharges(36799) <3 and False() Spell(conjure_mana_gem)
	if BuffPresent(alter_time) and BuffRemains(alter_time) <2 Spell(arcane_barrage)
	if BuffPresent(alter_time) or BuffStacks(arcane_missiles_aura) ==2 Spell(arcane_missiles)
	if BuffRemains(rune_of_power) <=2 and BuffExpires(alter_time) Spell(rune_of_power)
	if {not target.DebuffPresent(living_bomb) or target.DebuffRemains(living_bomb) <TickTime(living_bomb) } and target.DeadIn() >TickTime(living_bomb) *3 Spell(living_bomb)
	if ManaPercent() >92 or BuffPresent(alter_time) or BuffRemains(arcane_charge) <3 Spell(arcane_blast)
	if BuffStacks(arcane_missiles_aura) and {SpellCooldown(alter_time_activate) >4 or target.DeadIn() <10 } Spell(arcane_missiles)
	if {SpellCooldown(mana_gem) <=9 and not ManaPercent() <=80 } or target.DeadIn() <30 Spell(arcane_blast)
	if BuffExpires(alter_time) Spell(scorch)
}
AddIcon mastery=1 help=offgcd
{
	if target.IsInterruptible() if target.IsInterruptible() Spell(counterspell)
	cancel.Spell(alter_time)
	if target.HealthPercent() <25 or TimeInCombat() >5 Spell(time_warp)
	if BuffExpires(alter_time) and BuffPresent(arcane_power) and BuffStacks(arcane_missiles_aura) ==2 and BuffStacks(arcane_charge) >3 and BuffRemains(rune_of_power) >6 Spell(alter_time)
	if ManaPercent() <80 and BuffExpires(alter_time) Spell(mana_gem)
}
AddIcon mastery=1 help=moving
{
	if BuffPresent(arcane_charge) and BuffRemains(arcane_charge) <=2 Spell(arcane_barrage)
	Spell(scorch)
	Spell(fire_blast)
	Spell(ice_lance)
}
AddIcon mastery=1 help=cd
{
	if not InCombat() 
	{
		Spell(mirror_image)
	}
	if target.DeadIn() <18 Spell(arcane_power)
	if target.DeadIn() <18 Spell(berserking)
	if BuffExpires(alter_time)  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	if SpellCooldown(alter_time_activate) >45 or target.DeadIn() <25 and BuffRemains(rune_of_power) >20  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	Spell(mirror_image)
	if BuffRemains(rune_of_power) >15 and BuffExpires(alter_time) and BuffStacks(arcane_charge) >1 Spell(arcane_power)
	if BuffRemains(rune_of_power) >10 and BuffExpires(alter_time) and BuffStacks(arcane_charge) >2 Spell(berserking)
}
AddIcon mastery=2 help=main
{
	if not InCombat() 
	{
		if BuffExpires(arcane_brilliance) Spell(arcane_brilliance)
		Spell(molten_armor)
	}
	if ItemCharges(36799) <3 and False() Spell(conjure_mana_gem)
	if BuffStacks(pyroblast_aura) and {SpellCooldown(alter_time_activate) >4 or BuffStacks(heating_up) } Spell(pyroblast)
	if BuffPresent(presence_of_mind) and SpellCooldown(alter_time_activate) >4 Spell(pyroblast)
	if BuffStacks(heating_up) and BuffExpires(pyroblast_aura) Spell(inferno_blast)
	if {not target.DebuffPresent(living_bomb) or target.DebuffRemains(living_bomb) <TickTime(living_bomb) } and target.DeadIn() >TickTime(living_bomb) *3 Spell(living_bomb)
	if not target.DebuffPresent(pyroblast_aura) Spell(pyroblast)
	Spell(fireball)
}
AddIcon mastery=2 help=offgcd
{
	if target.IsInterruptible() if target.IsInterruptible() Spell(counterspell)
	cancel.Spell(alter_time)
	if target.HealthPercent() <25 or TimeInCombat() >5 Spell(time_warp)
	if target.DeadIn() <22 Spell(combustion)
	if LastSpellDamage(ignite) >={{CritDamage(fireball) +CritDamage(inferno_blast) +Damage(pyroblast) } *{Mastery() /100} *0.5 } and target.DebuffPresent(pyroblast_aura) Spell(combustion)
	if ManaPercent() <84 and BuffExpires(alter_time) Spell(mana_gem)
	if BuffExpires(alter_time) and BuffStacks(pyroblast_aura) and BuffRemains(invokers_energy) >6 Spell(alter_time)
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
		Spell(mirror_image)
	}
	if BuffRemains(invokers_energy) >10 and BuffExpires(alter_time) and ManaPercent() >28 Spell(berserking)
	if BuffExpires(invokers_energy) and BuffExpires(alter_time) Spell(evocation)
	if target.DeadIn() <18 Spell(berserking)
	if BuffExpires(alter_time)  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	if SpellCooldown(alter_time_activate) >45 or target.DeadIn() <25 and BuffRemains(invokers_energy) >20  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	if ManaPercent() <10 and target.DeadIn() >=30 Spell(evocation)
	Spell(mirror_image)
	if BuffExpires(alter_time) Spell(presence_of_mind)
}
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		if BuffExpires(arcane_brilliance) Spell(arcane_brilliance)
		if BuffExpires(frost_armor) Spell(frost_armor)
	}
	if ItemCharges(36799) <3 and False() Spell(conjure_mana_gem)
	if BuffPresent(alter_time) and BuffPresent(brain_freeze) Spell(frostfire_bolt)
	if BuffPresent(alter_time) and BuffStacks(fingers_of_frost_aura) Spell(ice_lance)
	if BuffPresent(alter_time) and BuffPresent(presence_of_mind) Spell(frostbolt)
	if target.DeadIn() >=4 and BuffStacks(fingers_of_frost_aura) <2 and SpellCooldown(icy_veins) <GCD() and BuffRemains(invokers_energy) >20 and BuffExpires(alter_time) Spell(frozen_orb)
	if BuffPresent(brain_freeze) and {{target.DebuffPresent(frost_bomb) and target.DebuffRemains(frost_bomb) <2 } or BuffRemains(brain_freeze) <2 } Spell(frostfire_bolt)
	if BuffStacks(fingers_of_frost_aura) and BuffRemains(fingers_of_frost_aura) <2 Spell(ice_lance)
	if target.DebuffStacks(frostbolt) <3 Spell(frostbolt)
	if BuffStacks(fingers_of_frost_aura) Spell(ice_lance)
	if BuffPresent(brain_freeze) and {BuffPresent(alter_time) or SpellCooldown(alter_time_activate) >4 } Spell(frostfire_bolt)
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
	cancel.Spell(alter_time)
	if target.HealthPercent() <25 or TimeInCombat() >5 Spell(time_warp)
	if BuffExpires(alter_time) and BuffStacks(fingers_of_frost_aura) <2 Spell(water_elemental_freeze)
	if not target.DebuffPresent(frost_bomb) and target.DeadIn() >CastTime(frost_bomb) +TickTime(frost_bomb) Spell(frost_bomb)
	if BuffExpires(alter_time) and BuffPresent(brain_freeze) and BuffStacks(fingers_of_frost_aura) and BuffRemains(invokers_energy) >6 Spell(alter_time)
	if BuffExpires(alter_time) and BuffPresent(brain_freeze) and BuffStacks(fingers_of_frost_aura) Spell(alter_time)
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
		Spell(mirror_image)
	}
	if BuffExpires(alter_time) Spell(presence_of_mind)
	if target.DeadIn() <22 Spell(icy_veins)
	if target.DeadIn() <18 Spell(berserking)
	if ArmorSetParts(T14 more 4) and BuffRemains(invokers_energy) >20 and BuffExpires(alter_time) Spell(icy_veins)
	if not ArmorSetParts(T14 more 4) and target.DebuffPresent(frozen_orb) Spell(icy_veins)
	if target.DebuffPresent(frozen_orb) and BuffExpires(alter_time) Spell(icy_veins)
	Spell(mirror_image)
	if BuffExpires(invokers_energy) and BuffExpires(alter_time) Spell(evocation)
	if BuffRemains(invokers_energy) >10 and BuffExpires(alter_time) and ManaPercent() >28 Spell(berserking)
}
]]

OvaleScripts:RegisterScript("MAGE", "Ovale", "[5.2] Ovale: Arcane, Fire, Frost", code)
