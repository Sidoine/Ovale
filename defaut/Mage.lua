Ovale.defaut["MAGE"]=
[[
Define(TALENTLIVINGBOMB 1852)
Define(TALENTPIERCINGICE 61)
Define(TALENTCHILLEDTOTHEBONES 1856)
Define(TALENTARCANEBARRAGE 1847)

Define(HOTSTREAK 48108)
Define(IMPROVEDSCORCH 22959)

Define(PYROBLAST 11366)
Define(LIVINGBOMB 44457)
Define(SCORCH 2948)
Define(FROSTFIREBOLT 44614)
Define(FROSTBOLT 116)
Define(FIREBALL 133)
Define(ARCANEBARRAGE 44425)
Define(ARCANEMISSILES 5143)
Define(ARCANEBLAST 30451)
Define(ARCANEPOWER 12042)

Define(COMBUSTION 11129)
Define(ICYVEINS 12472)
Define(MIRRORIMAGE 55342)
Define(SUMMONWATERELEMENTAL 31687)
Define(PRESENCEOFMIND 12043)

AddCheckBox(scorch SpellName(SCORCH))

SpellAddDebuff(ARCANEBLAST ARCANEBLAST=10)
SpellAddTargetDebuff(SCORCH IMPROVEDSCORCH=30)
SpellAddTargetDebuff(LIVINGBOMB LIVINGBOMB=12)
ScoreSpells(SCORCH PYROBLAST LIVINGBOMB FROSTFIREBOLT FIREBALL SUMMONWATERELEMENTAL FROSTBOLT ARCANEBLAST ARCANEMISSILES)

AddIcon
{
       if TalentPoints(TALENTLIVINGBOMB more 0)
       {
              #Fire spec
              if TargetDebuffExpires(IMPROVEDSCORCH 6 stacks=5) and CheckBoxOn(scorch) Spell(SCORCH)
              if BuffPresent(HOTSTREAK) Spell(PYROBLAST)
              if TargetDebuffExpires(LIVINGBOMB 0 mine=1) Spell(LIVINGBOMB)
              if TalentPoints(TALENTPIERCINGICE more 0)
                     Spell(FROSTFIREBOLT)
              if TalentPoints(TALENTPIERCINGICE less 1)
                     Spell(FIREBALL)
       }
       
       if TalentPoints(TALENTCHILLEDTOTHEBONES more 0)
       {
              #Frost spec
              Spell(SUMMONWATERELEMENTAL)
              Spell(FROSTBOLT)
       }
       
       if TalentPoints(TALENTARCANEBARRAGE more 0)
       {
              #Arcane spec
              if DebuffExpires(ARCANEBLAST 0 stacks=4)
                     Spell(ARCANEBLAST)
              Spell(ARCANEMISSILES)
       }
}

AddIcon
{
       Spell(MIRRORIMAGE)
}

AddIcon
{
       if DebuffPresent(ARCANEBLAST stacks=3) Spell(ARCANEPOWER)
       Spell(COMBUSTION)
       Spell(ICYVEINS)
       Spell(PRESENCEOFMIND)
       Item(Trinket0Slot usable=1)
       Item(Trinket1Slot usable=1)
}

]]