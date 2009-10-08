Ovale.defaut["WARLOCK"]=
[[
Define(CURSEELEMENTS 1490)
Define(CURSEAGONY 980)
Define(CURSEDOOM 603)
Define(CURSETONGUES 1714)
Define(CURSEWEAKNESS 702)
Define(UNSTABLEAFFLICTION 30108)
Define(CORRUPTION 172)
Define(TALENTUNSTABLEAFFLICTION 1670)
Define(TALENTSHADOWBOLT 944)
Define(IMMOLATE 348)
Define(TALENTIMMOLATE 961)
Define(TALENTEMBERSTORM 966)
Define(SOULFIRE 6353)
Define(SHADOWBOLT 686)
Define(HAUNT 48181)
Define(TALENTBACKDRAFT 1888)
Define(CONFLAGRATE 17962)
Define(DRAINSOUL 47855)
Define(SHADOWEMBRACE 32391)
Define(TALENTSHADOWEMBRACE 1763)
Define(METAMORPHOSIS 47241)
Define(TALENTDECIMATION 2261)
Define(SOULSHARD 6265)
Define(DEMONICEMPOWERMENT 47193)
Define(INCINERATE 29722)
Define(DECIMATION 63167)
Define(CHAOSBOLT 50796)

AddListItem(curse elements SpellName(CURSEELEMENTS))
AddListItem(curse agony SpellName(CURSEAGONY))
AddListItem(curse doom SpellName(CURSEDOOM))
AddListItem(curse tongues SpellName(CURSETONGUES))
AddListItem(curse weakness SpellName(CURSEWEAKNESS))

SpellInfo(HAUNT cd=8)
SpellInfo(CONFLAGRATE cd=10)
SpellAddTargetDebuff(UNSTABLEAFFLICTION UNSTABLEAFFLICTION=15)
SpellAddTargetDebuff(IMMOLATE IMMOLATE=15)
ScoreSpells(CURSEELEMENTS SHADOWBOLT HAUNT UNSTABLEAFFLICTION IMMOLATE CONFLAGRATE CURSEDOOM CURSETONGUES CURSEWEAKNESS
	CURSEAGONY CORRUPTION SOULFIRE DRAINSOUL INCINERATE SHADOWBOLT)

AddIcon
{
if List(curse elements) and TargetDebuffExpires(CURSEELEMENTS 2) Spell(CURSEELEMENTS)
if TalentPoints(TALENTSHADOWEMBRACE more 0) and TargetDebuffExpires(SHADOWEMBRACE 0) Spell(SHADOWBOLT)
if TargetDebuffExpires(HAUNT 1.5 mine=1) Spell(HAUNT)
if TargetDebuffExpires(UNSTABLEAFFLICTION 1.5 mine=1 haste=spell) Spell(UNSTABLEAFFLICTION)
if TalentPoints(TALENTBACKDRAFT more 0) and TargetDebuffExpires(IMMOLATE 3 mine=1)
   and TargetDebuffPresent(IMMOLATE mine=1) Spell(CONFLAGRATE)
if TargetDebuffExpires(IMMOLATE 1.5 mine=1 haste=spell) and
		{TargetLifePercent(more 25) or TalentPoints(TALENTDECIMATION more 0)} 
			Spell(IMMOLATE)
if List(curse doom) and TargetDebuffExpires(CURSEDOOM 0 mine=1) Spell(CURSEDOOM)
if List(curse tongues) and TargetDebuffExpires(CURSETONGUES 2) Spell(CURSETONGUES)
if List(curse weakness) and TargetDebuffExpires(CURSEWEAKNESS 2) Spell(CURSEWEAKNESS)
if List(curse agony) and TargetDebuffExpires(CURSEAGONY 0 mine=1) Spell(CURSEAGONY)
if TargetDebuffExpires(CORRUPTION 0 mine=1) Spell(CORRUPTION)

if BuffPresent(DECIMATION) Spell(SOULFIRE)

if TargetLifePercent(less 25) and Level(more 76) and {TalentPoints(TALENTDECIMATION less 1) or ItemCount(SOULSHARD less 16)} Spell(DRAINSOUL)

Spell(CHAOSBOLT)
if TalentPoints(TALENTEMBERSTORM more 0) Spell(INCINERATE)
Spell(SHADOWBOLT)
}

AddIcon
{
	Spell(METAMORPHOSIS)
	Spell(DEMONICEMPOWERMENT)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

]]
