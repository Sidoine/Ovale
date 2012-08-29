Ovale.defaut["PALADIN"] = [[Define(avenging_wrath 31884)
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
Define(execution_sentence 114916)
  SpellInfo(execution_sentence duration=10 tick=1 )
  SpellAddTargetDebuff(execution_sentence execution_sentence=1)
Define(exorcism 879)
  SpellInfo(exorcism holy=-1 cd=15 )
Define(glyph_word_of_glory 115522)
  SpellInfo(glyph_word_of_glory duration=6 )
  SpellAddBuff(glyph_word_of_glory glyph_word_of_glory=1)
Define(guardian_of_ancient_kings 86659)
  SpellInfo(guardian_of_ancient_kings duration=12 cd=180 )
  SpellAddBuff(guardian_of_ancient_kings guardian_of_ancient_kings=1)
Define(hammer_of_wrath 24275)
  SpellInfo(hammer_of_wrath holy=-0 cd=6 )
Define(harsh_word 130552)
Define(inquisition 84963)
  SpellInfo(inquisition duration=10 holy=1 )
  SpellAddBuff(inquisition inquisition=1)
Define(judgment 20271)
  SpellInfo(judgment cd=6 )
Define(rebuke 96231)
  SpellInfo(rebuke duration=4 cd=15 )
Define(seal_of_insight 20165)
  SpellAddBuff(seal_of_insight seal_of_insight=1)
Define(seal_of_truth 31801)
  SpellAddBuff(seal_of_truth seal_of_truth=1)
Define(templars_verdict 85256)
  SpellInfo(templars_verdict holy=3 )
AddIcon mastery=3 help=main
{
	if not InCombat() 
	{
		if not BuffPresent(str_agi_int) Spell(blessing_of_kings)
		if not BuffPresent(mastery) and not BuffPresent(str_agi_int) Spell(blessing_of_might)
		unless Stance(1) Spell(seal_of_truth)
	}
	if ManaPercent() >=90 or Stance(0) unless Stance(1) Spell(seal_of_truth)
	if ManaPercent() <=20 unless Stance(4) Spell(seal_of_insight)
	if {BuffExpires(inquisition) or BuffRemains(inquisition) <=2 } and {HolyPower() >=3 } Spell(inquisition)
	if HolyPower() ==5 Spell(templars_verdict)
	Spell(hammer_of_wrath usable=1)
	Spell(exorcism)
	Spell(crusader_strike)
	Spell(judgment)
	if HolyPower() >=3 Spell(templars_verdict)
}
AddIcon mastery=3 help=offgcd
{
	if target.IsInterruptible() Spell(rebuke)
	if {BuffExpires(glyph_word_of_glory) } and {HolyPower() >=3 } Spell(harsh_word)
	if BuffPresent(inquisition) Spell(execution_sentence)
}
AddIcon mastery=3 help=cd
{
	if BuffPresent(inquisition) Spell(avenging_wrath)
	if BuffPresent(inquisition) and BuffPresent(avenging_wrath) Spell(guardian_of_ancient_kings)
	if BuffPresent(inquisition)  { Item(Trinket0Slot usable=1) Item(Trinket1Slot usable=1) } 
}
]]