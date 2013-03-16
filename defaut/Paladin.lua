local _, Ovale = ...
local OvaleScripts = Ovale:GetModule("OvaleScripts")

local code = [[
Define(avenging_wrath 31884)
  SpellInfo(avenging_wrath duration=20 cd=180 )
  SpellAddBuff(avenging_wrath avenging_wrath=1)
Define(blessing_of_kings 20217)
  SpellInfo(blessing_of_kings duration=3600 )
  SpellAddBuff(blessing_of_kings blessing_of_kings=1)
Define(blessing_of_might 19740)
  SpellInfo(blessing_of_might duration=3600 )
  SpellAddBuff(blessing_of_might blessing_of_might=1)
Define(crusader_strike 35395)
  SpellInfo(crusader_strike holy=-1 cd=4.5 )
Define(divine_storm 53385)
  SpellInfo(divine_storm holy=3 )
Define(execution_sentence 114916)
  SpellInfo(execution_sentence duration=10 tick=1 )
  SpellAddTargetDebuff(execution_sentence execution_sentence=1)
Define(exorcism 879)
  SpellInfo(exorcism holy=-1 cd=15 )
Define(exorcism_glyphed 122032)
  SpellInfo(exorcism_glyphed holy=-1 cd=15)
Define(glyph_of_double_jeopardy 121027)
  SpellInfo(glyph_of_double_jeopardy duration=10 )
  SpellAddBuff(glyph_of_double_jeopardy glyph_of_double_jeopardy=1)
Define(guardian_of_ancient_kings 86659)
  SpellInfo(guardian_of_ancient_kings duration=12 cd=180 )
  SpellAddBuff(guardian_of_ancient_kings guardian_of_ancient_kings=1)
Define(hammer_of_the_righteous 53595)
  SpellInfo(hammer_of_the_righteous holy=-1 cd=4.5 )
Define(hammer_of_wrath 24275)
  SpellInfo(hammer_of_wrath holy=-0 cd=6 )
Define(inquisition 84963)
  SpellInfo(inquisition duration=10 holy=1 )
  SpellAddBuff(inquisition inquisition=1)
Define(judgment 20271)
  SpellInfo(judgment cd=6 )
Define(rebuke 96231)
  SpellInfo(rebuke duration=4 cd=15 )
Define(seal_of_righteousness 20154)
  SpellAddBuff(seal_of_righteousness seal_of_righteousness=1)
Define(seal_of_truth 31801)
  SpellAddBuff(seal_of_truth seal_of_truth=1)
Define(templars_verdict 85256)
  SpellInfo(templars_verdict holy=3 )
Define(glyph_of_mass_exorcism 122028)
AddCheckBox(showwait L(showwait) default)
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		if not BuffPresent(str_agi_int any=1) Spell(blessing_of_kings)
		if not BuffPresent(mastery any=1) and not BuffPresent(str_agi_int any=1) Spell(blessing_of_might)
		unless Stance(1) Spell(seal_of_truth)
	}
	if {BuffExpires(inquisition) or BuffRemains(inquisition) <=2 } and {HolyPower() >=3 or target.DeadIn() <HolyPower() *10 } Spell(inquisition)
	if HolyPower() ==5 Spell(templars_verdict)
	Spell(hammer_of_wrath usable=1)
	if SpellCooldown(hammer_of_wrath) >0 and SpellCooldown(hammer_of_wrath) <=0.2 if CheckBoxOn(showwait) Texture(Spell_nature_timestop) 
	if Glyph(glyph_of_mass_exorcism no)
	{
		Spell(exorcism)
		if SpellCooldown(exorcism) >0 and SpellCooldown(exorcism) <=0.2 if CheckBoxOn(showwait) Texture(Spell_nature_timestop) 
	}
	if Glyph(glyph_of_mass_exorcism)
	{
		Spell(exorcism_glyphed)
		if SpellCooldown(exorcism_glyphed) >0 and SpellCooldown(exorcism_glyphed) <=0.2 if CheckBoxOn(showwait) Texture(Spell_nature_timestop) 
	}
	if not {ArmorSetParts(T15 more 4) } and {target.HealthPercent() <=20 or BuffPresent(avenging_wrath) } Spell(judgment)
	Spell(crusader_strike)
	if SpellCooldown(crusader_strike) >0 and SpellCooldown(crusader_strike) <=0.2 if CheckBoxOn(showwait) Texture(Spell_nature_timestop) 
	Spell(judgment)
	if BuffRemains(inquisition) >4 Spell(templars_verdict)
}
AddIcon mastery=3 help=offgcd
{
	if target.IsInterruptible() Spell(rebuke)
	if BuffPresent(inquisition) Spell(execution_sentence)
}
AddIcon mastery=3 help=aoe
{
	if not InCombat() 
	{
		unless Stance(2) Spell(seal_of_righteousness)
	}
	if {HolyPower() ==5 } Spell(divine_storm)
	Spell(hammer_of_the_righteous)
	if BuffPresent(glyph_of_double_jeopardy) focus.Spell(judgment)
	if BuffRemains(inquisition) >4 Spell(divine_storm)
}
AddIcon mastery=3 help=cd
{
	if BuffPresent(inquisition) Spell(avenging_wrath)
	if BuffPresent(avenging_wrath) Spell(guardian_of_ancient_kings)
	if BuffPresent(inquisition)  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
}
]]

OvaleScripts:RegisterScript("PALADIN", "Ovale", "[5.2] Ovale: Retribution", code)
