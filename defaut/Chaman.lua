Ovale.defaut["SHAMAN"] =
[[AddCheckBox(chain "Chaîne d'éclairs")

Define(CHAINLIGHTNING 421)
Define(LIGHTNINGBOLT 403)
Define(LAVABURST 51505)
Define(WATERSHIELD 52127)
Define(FLAMESHOCK 8050)
Define(FLAMETHONG 8024)

if BuffExpires(FLAMETHONG 2) Spell(FLAMETHONG)
if BuffExpires(WATERSHIELD 2) Spell(WATERSHIELD)
if TargetDebuffExpires(FLAMESHOCK 0) Spell(FLAMESHOCK)
Spell(LAVABURST doNotRepeat=1)
if CheckBoxOn(chain) Spell(CHAINLIGHTNING doNotRepeat=1)
Spell(LIGHTNINGBOLT)
]]