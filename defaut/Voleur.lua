local _, Ovale = ...
local OvaleScripts = Ovale:GetModule("OvaleScripts")

local code = [[
Define(adrenaline_rush 13750)
  SpellInfo(adrenaline_rush duration=15 cd=180 )
  SpellAddBuff(adrenaline_rush adrenaline_rush=1)
Define(ambush 8676)
  SpellInfo(ambush energy=60 combo=2 buff_combo=shadow_blades )
Define(anticipation 114015)
Define(backstab 53)
  SpellInfo(backstab energy=35 combo=1 buff_combo=shadow_blades )
Define(bandits_guile 84654)
Define(berserking 26297)
  SpellInfo(berserking duration=10 cd=180 )
  SpellAddBuff(berserking berserking=1)
Define(deep_insight 84747)
  SpellInfo(deep_insight duration=15 )
  SpellAddBuff(deep_insight deep_insight=1)
Define(dispatch 111240)
  SpellInfo(dispatch energy=30 combo=1 buff_combo=shadow_blades )
Define(envenom 32645)
  SpellInfo(envenom duration=1 combo=0 energy=35 )
  SpellAddBuff(envenom envenom=1)
Define(eviscerate 2098)
  SpellInfo(eviscerate combo=0 energy=35 )
Define(expose_armor 8647)
  SpellInfo(expose_armor energy=25 combo=1 buff_combo=shadow_blades )
  AddCheckBox(expose_armor_check SpellName(expose_armor))
Define(find_weakness 91021)
  SpellInfo(find_weakness duration=10 )
  SpellAddBuff(find_weakness find_weakness=1)
Define(hemorrhage 16511)
  SpellInfo(hemorrhage energy=30 combo=1 buff_combo=shadow_blades )
Define(honor_among_thieves 51701)
Define(kick 1766)
  SpellInfo(kick duration=5 cd=15 )
Define(killing_spree 51690)
  SpellInfo(killing_spree duration=3 cd=120 )
  SpellAddBuff(killing_spree killing_spree=1)
Define(master_of_subtlety 31223)
Define(mutilate 1329)
  SpellInfo(mutilate energy=55 combo=2 buff_combo=shadow_blades )
Define(premeditation 14183)
  SpellInfo(premeditation duration=18 combo=2 cd=20 )
Define(preparation 14185)
  SpellInfo(preparation cd=300 )
Define(revealing_strike 84617)
  SpellInfo(revealing_strike duration=18 tick=3 energy=40 combo=1 buff_combo=shadow_blades )
  SpellAddTargetDebuff(revealing_strike revealing_strike=1)
Define(rupture 1943)
  SpellInfo(rupture duration=4 tick=2 combo=0 energy=25 )
  SpellAddTargetDebuff(rupture rupture=1)
Define(shadow_blades 121471)
  SpellInfo(shadow_blades duration=12 cd=180 )
  SpellAddBuff(shadow_blades shadow_blades=1)
Define(shadow_dance 51713)
  SpellInfo(shadow_dance duration=8 cd=60 )
  SpellAddBuff(shadow_dance shadow_dance=1)
Define(sinister_strike 1752)
  SpellInfo(sinister_strike energy=40 combo=1 buff_combo=shadow_blades )
Define(slice_and_dice 5171)
  SpellInfo(slice_and_dice duration=6 combo=0 energy=25 )
  SpellAddBuff(slice_and_dice slice_and_dice=1)
Define(stealth 63880)
Define(stealthed 1784)
  SpellInfo(stealthed cd=6 )
  SpellAddBuff(stealthed stealthed=1)
Define(tricks_of_the_trade 57933)
  SpellInfo(tricks_of_the_trade duration=6 )
  SpellAddBuff(tricks_of_the_trade tricks_of_the_trade=1)
Define(vanish 1856)
  SpellInfo(vanish cd=120 )
  SpellAddBuff(vanish vanish=1)
Define(vendetta 79140)
  SpellInfo(vendetta duration=20 cd=120 )
  SpellAddBuff(vendetta vendetta=1)
Define(weakened_armor 113746)
  SpellInfo(weakened_armor duration=30 )
  SpellAddBuff(weakened_armor weakened_armor=1)
Define(anticipation_talent 18)
Define(shadow_focus_talent 3)
Define(subterfuge_talent 2)
AddIcon mastery=1 help=main
{
	if not InCombat() 
	{
		if WeaponEnchantExpires(mainhand 300) Item(6497) 
	}
	if {target.DebuffStacks(weakened_armor any=1) <3 or target.DebuffRemains(weakened_armor any=1) <3 } and ComboPoints() <5 if CheckBoxOn(expose_armor_check) Spell(expose_armor)
	Spell(ambush usable=1)
	if BuffRemains(slice_and_dice) <2 Spell(slice_and_dice)
	if target.TicksRemain(rupture) <2 and Energy() >90 Spell(dispatch usable=1)
	if target.TicksRemain(rupture) <2 and Energy() >90 Spell(mutilate)
	if target.TicksRemain(rupture) <2 or {ComboPoints() ==5 and target.TicksRemain(rupture) <3 } Spell(rupture)
	if ComboPoints() >4 Spell(envenom)
	if ComboPoints() >=2 and BuffRemains(slice_and_dice) <3 Spell(envenom)
	if ComboPoints() <5 Spell(dispatch usable=1)
	Spell(mutilate)
}
AddIcon mastery=1 help=offgcd
{
	if not InCombat() 
	{
		Spell(stealth)
	}
	if target.IsInterruptible() Spell(kick)
	Spell(tricks_of_the_trade)
}
AddIcon mastery=1 help=cd
{
	if not BuffPresent(vanish) and SpellCooldown(vanish) >60 Spell(preparation)
	 { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	Spell(berserking)
	if TimeInCombat() >10 and not BuffPresent(stealthed) and not BuffPresent(shadow_blades) Spell(vanish)
	if {BuffStacks(bloodlust any=1) or TimeInCombat() >60 } Spell(shadow_blades)
	Spell(vendetta)
}
AddIcon mastery=2 help=main
{
	if not InCombat() 
	{
		if WeaponEnchantExpires(mainhand 300) Item(6497) 
	}
	if {target.DebuffStacks(weakened_armor any=1) <3 or target.DebuffRemains(weakened_armor any=1) <3 } and ComboPoints() <5 if CheckBoxOn(expose_armor_check) Spell(expose_armor)
	Spell(ambush usable=1)
	if BuffRemains(slice_and_dice) <2 or {BuffRemains(slice_and_dice) <15 and BuffStacks(bandits_guile) ==11 and ComboPoints() >=4 } Spell(slice_and_dice)
	if ComboPoints() <5 or not target.DebuffPresent(revealing_strike) 
	{
		if target.TicksRemain(revealing_strike) <2 Spell(revealing_strike)
		Spell(sinister_strike)
	}
	if not TalentPoints(anticipation_talent) or BuffPresent(deep_insight) or SpellCooldown(shadow_blades) <=11 or BuffStacks(anticipation) >=4 or {BuffPresent(shadow_blades) and BuffStacks(anticipation) >=3 } 
	{
		if target.TicksRemain(rupture) <2 and target.DeadIn() >=26 Spell(rupture)
		Spell(eviscerate)
	}
	if Energy() >60 or BuffExpires(deep_insight) or BuffRemains(deep_insight) >5 -ComboPoints() 
	{
		if target.TicksRemain(revealing_strike) <2 Spell(revealing_strike)
		Spell(sinister_strike)
	}
}
AddIcon mastery=2 help=offgcd
{
	if not InCombat() 
	{
		Spell(stealth)
	}
	if target.IsInterruptible() Spell(kick)
}
AddIcon mastery=2 help=cd
{
	if not BuffPresent(vanish) and SpellCooldown(vanish) >60 Spell(preparation)
	if TimeInCombat() ==0 or BuffPresent(shadow_blades)  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	if TimeInCombat() ==0 or BuffPresent(shadow_blades) Spell(berserking)
	if TimeInCombat() >10 and {ComboPoints() <3 or {TalentPoints(anticipation_talent) and BuffStacks(anticipation) <3 } or {BuffExpires(shadow_blades) and {ComboPoints() <4 or {TalentPoints(anticipation_talent) and BuffStacks(anticipation) <4 } } } } and {{TalentPoints(shadow_focus_talent) and BuffExpires(adrenaline_rush) and Energy() <20 } or {TalentPoints(subterfuge_talent) and Energy() >=90 } or {not TalentPoints(shadow_focus_talent) and not TalentPoints(subterfuge_talent) and Energy() >=60 } } Spell(vanish)
	if not ArmorSetParts(T14 more 4) and TimeInCombat() >5 Spell(shadow_blades)
	if not ArmorSetParts(T14 more 4) and Energy() <35 and BuffExpires(adrenaline_rush) Spell(killing_spree)
	if not ArmorSetParts(T14 more 4) and {Energy() <35 or BuffPresent(shadow_blades) } Spell(adrenaline_rush)
	if ArmorSetParts(T14 more 4) and {{SpellCooldown(killing_spree) >30.5 and SpellCooldown(adrenaline_rush) <=9 } or {Energy() <35 and {SpellCooldown(killing_spree) ==0 or SpellCooldown(adrenaline_rush) ==0 } } } Spell(shadow_blades)
	if ArmorSetParts(T14 more 4) and {{BuffPresent(shadow_blades) and BuffExpires(adrenaline_rush) and {Energy() <35 or BuffRemains(shadow_blades) <=3.5 } } or {BuffExpires(shadow_blades) and SpellCooldown(shadow_blades) >30 } } Spell(killing_spree)
	if ArmorSetParts(T14 more 4) and BuffPresent(shadow_blades) and {Energy() <35 or BuffRemains(shadow_blades) <=15 } Spell(adrenaline_rush)
}
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		if WeaponEnchantExpires(mainhand 300) Item(6497) 
		Spell(slice_and_dice)
	}
	if {target.DebuffStacks(weakened_armor any=1) <3 or target.DebuffRemains(weakened_armor any=1) <3 } and ComboPoints() <5 if CheckBoxOn(expose_armor_check) Spell(expose_armor)
	if ComboPoints() <=5 and BuffStacks(anticipation) ==0 Spell(ambush usable=1)
	if BuffRemains(slice_and_dice) <3 and ComboPoints() ==5 Spell(slice_and_dice)
	if ComboPoints() ==5 and target.DebuffRemains(rupture) <5 Spell(rupture)
	if BuffStacks(anticipation) <3 and BuffRemains(shadow_dance) <=2 Spell(ambush usable=1)
	if ComboPoints() ==5 Spell(eviscerate)
	if ComboPoints() <4 and {target.DebuffRemains(hemorrhage) <4 or target.TargetIsPlayer() } Spell(hemorrhage)
	if ComboPoints() <5 and Energy() >80 and {target.DebuffRemains(hemorrhage) <4 or target.TargetIsPlayer() } Spell(hemorrhage)
	if ComboPoints() <4 and {SpellCooldown(shadow_dance) >7 or {SpellCooldown(shadow_dance) ==0 and TimeInCombat() <=9 } } Spell(backstab)
	if ComboPoints() <5 and Energy() >80 and SpellCooldown(shadow_dance) >=2 Spell(backstab)
}
AddIcon mastery=3 help=offgcd
{
	if not InCombat() 
	{
		Spell(stealth)
		Spell(premeditation usable=1)
	}
	if target.IsInterruptible() Spell(kick)
	if Energy() >=75 and BuffExpires(stealthed) and not target.DebuffPresent(find_weakness) Spell(shadow_dance)
	if {ComboPoints() <=3 and SpellCooldown(honor_among_thieves) >1.75 } or ComboPoints() <=2 Spell(premeditation usable=1)
	Spell(tricks_of_the_trade)
}
AddIcon mastery=3 help=cd
{
	if not BuffPresent(vanish) and SpellCooldown(vanish) >60 Spell(preparation)
	Spell(shadow_blades)
	if BuffPresent(shadow_dance)  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
	if BuffPresent(shadow_dance) Spell(berserking)
	if TimeInCombat() >10 and Energy() >=45 and Energy() <=75 and ComboPoints() <=3 and not BuffPresent(shadow_dance) and not BuffPresent(master_of_subtlety) and not target.DebuffPresent(find_weakness) Spell(vanish)
}
]]

OvaleScripts:RegisterScript("ROGUE", "Ovale", "[5.2] Ovale: Assassination, Combat, Subtlety", code)
