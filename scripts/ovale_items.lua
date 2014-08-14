local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_items"
	local desc = "[5.4.7] Ovale: Items & Trinkets"
	local code = [[
###
### Potions (Mists of Pandaria only)
###

Define(golemblood_potion 58146)
Define(golemblood_potion_buff 79634)
	SpellInfo(golemblood_potion_buff duration=25)
Define(jade_serpent_potion 76093)
Define(jade_serpent_potion_buff 105702)
	SpellInfo(jade_serpent_potion_buff duration=25)
Define(mogu_power_potion 76095)
Define(mogu_power_potion_buff 105706)
	SpellInfo(mogu_power_potion_buff duration=25)
Define(mountains_potion 76090)
Define(mountains_potion_buff 105698)
	SpellInfo(mountains_potion_buff duration=25)
Define(virmens_bite_potion 76089)
Define(virmens_bite_potion_buff 105697)
	SpellInfo(virmens_bite_potion_buff duration=25)

###
### Trinkets (Mists of Pandaria only)
###

# Agility
SpellList(trinket_proc_agility_buff 126554 126690 126707 128984 138699 138938 146308 146310 148896 148903)
SpellList(trinket_stacking_proc_agility_buff 138756)
SpellList(trinket_stat_agility_buff 126554 126690 126707 128984 138699 138938 146308 146310 148896 148903)
SpellList(trinket_stacking_stat_agility_buff 138756)

# Intellect
SpellList(trinket_proc_intellect_buff 126577 126683 126705 128985 136082 138898 139133 146046 148897 148906)
SpellList(trinket_stacking_proc_intellect_buff 138786 146184)
SpellList(trinket_stat_intellect_buff 126577 126683 126705 128985 136082 138898 139133 146046 148897 148906)
SpellList(trinket_stacking_stat_intellect_buff 138786 146184)

# Strength
SpellList(trinket_proc_strength_buff 126582 126679 126700 128986 138702 146245 146250 148899)
SpellList(trinket_stacking_proc_strength_buff 138759 138870)
SpellList(trinket_stat_strength_buff 126582 126679 126700 128986 138702 146245 146250 148899)
SpellList(trinket_stacking_stat_strength_buff 138759 138870)

# Critical Strike
SpellList(trinket_proc_crit_buff 138963)
SpellList(trinket_stacking_proc_crit_buff 146285)
SpellList(trinket_stat_crit_buff 138963)
SpellList(trinket_stacking_stat_crit_buff 146285)

# Amplification trinket passive buff.
Define(amplified_buff 146051)

# Cooldown reduction trinket passive buffs.
Define(cooldown_reduction_agility_buff 146019)
Define(cooldown_reduction_strength_buff 145955)
Define(cooldown_reduction_tank_buff 146025)

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
Define(tempus_repit_buff 137590)
	SpellInfo(tempus_repit_buff duration=10)
]]

	OvaleScripts:RegisterScript(nil, name, desc, code, "include")
end
