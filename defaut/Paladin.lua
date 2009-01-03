Ovale.defaut["PALADIN"] = 
[[AddListItem(sceau piete "Sceau de piété")
AddListItem(sceau autorite "Sceau d'autorité")
AddListItem(sceau martyr "Sceau de martyr/sang")
AddListItem(sceau vengeance "Sceau de vengeance/corruption")
AddListItem(jugement lumiere "Jugement de lumière")
AddListItem(jugement sagesse "Jugement de sagesse")
AddCheckBox(consecration "Consécration")
AddCheckBox(tempete "Tempête divine")

if List(sceau piete) and BuffExpires(21084 3) Spell(21084)
if List(sceau autorite) and BuffExpires(20375 3) Spell(20375)
if List(sceau martyr)
{
    if BuffExpires(53720 3) Spell(53720)
    if BuffExpires(31892 3) Spell(31892)
}
if List(sceau vengeance)
{
    if BuffExpires(31801 3) Spell(31801)
    if BuffExpires(53736 3) Spell(53736)
}
if List(jugement lumiere) Spell(20271)
if List(jugement sagesse) Spell(53408)
if TargetLifePercent(less 20) Spell(24275)
Spell(35395) #Inquisition
if CheckBoxOn(tempete) Spell(53385)
if CheckBoxOn(consecration) Spell(26573)
Spell(20473) #Horion sacré
if BuffPresent(59578) Spell(19750 priority=2)]]
		