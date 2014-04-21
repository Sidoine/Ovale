local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_items"
	local desc = "[5.4.7] Ovale: Items & Trinkets"
	local code = [[
###
### Potions (Mists of Pandaria only)
###

Define(jade_serpent_potion 76093)
Define(jade_serpent_potion_buff 105702)
	SpellInfo(jade_serpent_potion_buff duration=25)
Define(mogu_power_potion 76095)
Define(mogu_power_potion_buff 105706)
	SpellInfo(mogu_power_potion_buff duration=25)
Define(virmens_bite_potion 76089)
Define(virmens_bite_potion_buff 105697)
	SpellInfo(virmens_bite_potion_buff duration=25)

AddCheckBox(potions "Use potions" default)

AddFunction UsePotionAgility
{
	if CheckBoxOn(potions) and target.Classification(worldboss) Item(virmens_bite_potion usable=1)
}

AddFunction UsePotionIntellect
{
	if CheckBoxOn(potions) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction UsePotionStrength
{
	if CheckBoxOn(potions) and target.Classification(worldboss) Item(mogu_power_potion usable=1)
}

###
### Trinkets (Mists of Pandaria only)
###

# Agility
SpellList(trinket_proc_agility_buff 126554 126690 126707 128984 138699 138938 146308 146310 148896 148903)
SpellList(trinket_stacking_proc_agility_buff 138756)
SpellList(trinket_stat_agility_buff 126554 126690 126707 128984 138699 138938 146308 146310 148896 148903)
SpellList(trinket_stacking_stat_agility_buff 138756)

# Intellect
SpellList(trinket_proc_intellect_buff 126554 126690 126707 128984 138699 138938 146308 146310 148896 148903)
SpellList(trinket_stacking_proc_intellect_buff 138756)

# Strength
SpellList(trinket_proc_strength_buff 126554 126690 126707 128984 138699 138938 146308 146310 148896 148903)

# Critical Strike
SpellList(trinket_stacking_stat_crit_buff 138756)

AddCheckBox(opt_use_trinket0 "Use trinket 0" default)
AddCheckBox(opt_use_trinket1 "Use trinket 1" default)

AddFunction UseItemActions
{
	Item(HandsSlot usable=1)
	if CheckBoxOn(opt_use_trinket0) Item(Trinket0Slot usable=1)
	if CheckBoxOn(opt_use_trinket1) Item(Trinket1Slot usable=1)
}

###
### Legendary Meta Gem
###
Define(lucidity_druid_buff 137247)
	SpellInfo(lucidity_druid_buff duration=4)
Define(lucidity_monk_buff 137331)
	SpellInfo(lucidity_monk_buff duration=4)
Define(lucidity_paladin_buff 137288)
	SpellInfo(lucidity_paladin_buff duration=4)
Define(lucidity_priest_buff 137323)
	SpellInfo(lucidity_priest_buff duration=4)
Define(lucidity_shaman_buff 137326)
	SpellInfo(lucidity_shaman_buff duration=4)
]]

	OvaleScripts:RegisterScript(nil, name, desc, code, "include")
end
