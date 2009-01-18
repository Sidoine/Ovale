Ovale.defaut["PALADIN"] = 
[[
Define(SEALRIGHTEOUSNESS 21084)
Define(SEALCOMMAND 20375)
Define(SEALBLOOD 31892)
Define(SEALMARTYR 53720)
Define(SEALVENGEANCE 31801)
Define(SEALCORRUPTION 53736)
Define(JUDGELIGHT 20271)
Define(JUDGEWISDOM 53408)
Define(CONSECRATE 26573)
Define(DIVINESTORM 53385)
Define(HAMMEROFWRATH 24275)
Define(INQUISITION 35395)
Define(HOLYSHOCK 20473)
Define(THEARTOFWAR 59578)
Define(FLASHOFLIGHT 19750)
Define(EXORCISM 879)
Define(AVENGINGWRATH 31884)

AddListItem(sceau piete SpellName(SEALRIGHTEOUSNESS))
AddListItem(sceau autorite SpellName(SEALCOMMAND))
AddListItem(sceau martyr SpellName(SEALMARTYR))
AddListItem(sceau vengeance SpellName(SEALVENGEANCE))
AddListItem(jugement lumiere SpellName(JUDGELIGHT))
AddListItem(jugement sagesse SpellName(JUDGEWISDOM))
AddCheckBox(consecration SpellName(CONSECRATE))
AddCheckBox(tempete SpellName(DIVINESTORM))

AddIcon
{
     if List(sceau piete) and BuffExpires(SEALRIGHTEOUSNESS 3) Spell(SEALRIGHTEOUSNESS)
     if List(sceau autorite) and BuffExpires(SEALCOMMAND 3) Spell(SEALCOMMAND)
     if List(sceau martyr)
     {
          if BuffExpires(SEALMARTYR 3) Spell(SEALMARTYR)
          if BuffExpires(SEALBLOOD 3) Spell(SEALBLOOD)
     }
     if List(sceau vengeance)
     {
          if BuffExpires(SEALVENGEANCE 3) Spell(SEALVENGEANCE)
          if BuffExpires(SEALCORRUPTION 3) Spell(SEALCORRUPTION)
     }
     if List(jugement lumiere) Spell(JUDGELIGHT)
     if List(jugement sagesse) Spell(JUDGEWISDOM)
     if TargetLifePercent(less 35) Spell(HAMMEROFWRATH)
     Spell(INQUISITION)
     if CheckBoxOn(tempete) Spell(DIVINESTORM)
     if CheckBoxOn(consecration) Spell(CONSECRATE)
     Spell(HOLYSHOCK) 
     Spell(EXORCISM usable=1)
     if BuffPresent(THEARTOFWAR) Spell(FLASHOFLIGHT priority=2)
}
AddIcon
{
     Spell(AVENGINGWRATH)
}
]]
