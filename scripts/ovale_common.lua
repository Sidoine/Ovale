local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_common"
	local desc = "[5.4] Ovale: Common functions"
	local code = [[
# Common functions and UI elements for default scripts.

Include(ovale_items)
Include(ovale_racials)

###
### Use potions.
###
AddCheckBox(opt_potions "Use potions" default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(opt_potions) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potions) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction UsePotionStrength
{
	if CheckBoxOn(opt_potions) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

###
### Use glove tinker and trinkets.
###
AddCheckBox(opt_use_trinket0 "Use trinket 0" default)
AddCheckBox(opt_use_trinket1 "Use trinket 1" default)

AddFunction UseItemActions
{
	Item(HandsSlot usable=1)
	if CheckBoxOn(opt_use_trinket0) Item(Trinket0Slot usable=1)
	if CheckBoxOn(opt_use_trinket1) Item(Trinket1Slot usable=1)
}

###
### Racial actions.
###

AddFunction UseRacialSurvivalActions
{
	Spell(stoneform)
}
]]

	OvaleScripts:RegisterScript(nil, name, desc, code, "include")
end
