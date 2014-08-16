local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_common"
	local desc = "[5.4] Ovale: Common spell definitions"
	local code = [[
# Common spell definitions shared by all classes and specializations.

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
	SpellInfo(126554 buff_cd=55)				# Bottle of Infinite Stars
	SpellInfo(126690 buff_cd=60)				# PvP agility trinket (on-use)
	SpellInfo(126707 buff_cd=55)				# PvP agility trinket (proc)
	SpellInfo(128984 buff_cd=55)				# Relic of Xuen (agility)
	SpellInfo(138699 buff_cd=115)				# Vicious Talisman of the Shado-Pan Assault
	SpellInfo(138756 buff_cd=50 maxstacks=10)	# Renataki's Soul Charm
	SpellInfo(138938 buff_cd=55)				# Bad Juju
	SpellInfo(146308 buff_cd=115)				# Assurance of Consequence
	SpellInfo(146310 buff_cd=60)				# Ticking Ebon Detonator
	SpellInfo(148896 buff_cd=85)				# Sigil of Rampage
	SpellInfo(148903 buff_cd=65)				# Haromm's Talisman

# Intellect
SpellList(trinket_proc_intellect_buff 126577 126683 126705 128985 136082 138898 139133 146046 148897 148906)
SpellList(trinket_stacking_proc_intellect_buff 138786 146184)
SpellList(trinket_stat_intellect_buff 126577 126683 126705 128985 136082 138898 139133 146046 148897 148906)
SpellList(trinket_stacking_stat_intellect_buff 138786 146184)
	SpellInfo(126577 buff_cd=55)				# Light of the Cosmos
	SpellInfo(126683 buff_cd=60)				# PvP intellect trinket (on-use)
	SpellInfo(126705 buff_cd=55)				# PvP intellect trinket (proc)
	SpellInfo(128985 buff_cd=55)				# Relic of Yu'lon
	SpellInfo(136082 buff_cd=60)				# Shock-Charger/Static-Caster's Medallion
	SpellInfo(138786 buff_cd=50 maxstacks=10)	# Wushoolay's Final Choice
	SpellInfo(138898 buff_cd=55)				# Breath of the Hydra
	SpellInfo(139133 buff_cd=55)				# Cha-Ye's Essence of Brilliance (assume 20% crit chance)
	SpellInfo(146046 buff_cd=115)				# Purified Bindings of Immerseus
	SpellInfo(146184 buff_cd=65 maxstacks=10)	# Black Blood of Y'Shaarj
	SpellInfo(148897 buff_cd=85)				# Frenzied Crystal of Rage
	SpellInfo(148906 buff_cd=65)				# Kardris' Toxic Totem

# Strength
SpellList(trinket_proc_strength_buff 126582 126679 126700 128986 138702 146245 146250 148899)
SpellList(trinket_stacking_proc_strength_buff 138759 138870)
SpellList(trinket_stat_strength_buff 126582 126679 126700 128986 138702 146245 146250 148899)
SpellList(trinket_stacking_stat_strength_buff 138759 138870)
	SpellInfo(126582 buff_cd=55)				# Lei Shen's Final Orders
	SpellInfo(126679 buff_cd=60)				# PvP strength trinket (on-use)
	SpellInfo(126700 buff_cd=55)				# PvP strength trinket (proc)
	SpellInfo(128986 buff_cd=55)				# Relic of Xuen (strength)
	SpellInfo(138702 buff_cd=85)				# Brutal Talisman of the Shado-Pan Assault
	SpellInfo(138759 buff_cd=50)				# Fabled Feather of Ji-Kun
	SpellInfo(138870 buff_cd=17 maxstacks=5)	# Primordius' Talisman of Rage
	SpellInfo(146245 buff_cd=55)				# Evil Eye of Galakras
	SpellInfo(146250 buff_cd=115)				# Thok's Tail Tip
	SpellInfo(148899 buff_cd=85)				# Fusion-Fire Core

# Critical Strike
SpellList(trinket_proc_crit_buff 138963)
SpellList(trinket_stacking_proc_crit_buff 146285)
SpellList(trinket_stat_crit_buff 138963)
SpellList(trinket_stacking_stat_crit_buff 146285)
	SpellInfo(138963 buff_cd=110)							# Unerring Vision of Lei-Shen
	SpellInfo(138963 buff_cd=165 specialization=balance)	# UVLS adjustment for balance druids
	SpellInfo(146285 buff_cd=65)							# Skeer's Bloodsoaked Talisman

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

###
### Racials
###

Define(arcane_torrent_chi 129597)
	SpellInfo(arcane_torrent_chi cd=120 chi=1)
Define(arcane_torrent_energy 25046)
	SpellInfo(arcane_torrent_energy cd=120 energy=-15)
Define(arcane_torrent_focus 80483)
	SpellInfo(arcane_torrent_focus cd=120 focus=-15)
Define(arcane_torrent_mana 28730)
	SpellInfo(arcane_torrent_mana cd=120)
Define(arcane_torrent_rage 69179)
	SpellInfo(arcane_torrent_rage cd=120 rage=-15)
Define(arcane_torrent_runicpower 50613)
	SpellInfo(arcane_torrent_runicpower cd=120 runicpower=-15)
Define(berserking 26297)
	SpellInfo(berserking cd=180)
	SpellAddBuff(berserking berserking_buff=1)
Define(berserking_buff 26297)
	SpellInfo(berserking_buff duration=10)
Define(blood_fury_ap 20572)
	SpellInfo(blood_fury_ap cd=120)
	SpellAddBuff(blood_fury_ap blood_fury_ap_buff=1)
Define(blood_fury_ap_buff 20572)
	SpellInfo(blood_fury_ap_buff duration=15)
Define(blood_fury_apsp 33697)
	SpellInfo(blood_fury_apsp cd=120)
	SpellAddBuff(blood_fury_apsp blood_fury_apsp_buff=1)
Define(blood_fury_apsp_buff 33697)
	SpellInfo(blood_fury_apsp_buff duration=15)
Define(blood_fury_sp 33702)
	SpellInfo(blood_fury_sp cd=120)
	SpellAddBuff(blood_fury_sp blood_fury_sp_buff=1)
Define(blood_fury_sp_buff 33702)
	SpellInfo(blood_fury_sp_buff duration=15)
Define(quaking_palm 107079)
	SpellInfo(quaking_palm cd=120)
Define(stoneform 20594)
	SpellInfo(stoneform cd=120)
	SpellAddBuff(stoneform stoneform_buff=1)
Define(stoneform_buff 20594)
	SpellInfo(stoneform_buff duration=8)

AddFunction UseRacialSurvivalActions
{
	Spell(stoneform)
}

###
### Raid buffs and debuffs
###

Define(weakened_armor 113746)
	SpellInfo(weakened_armor duration=30 maxstacks=3)
Define(weakened_blows 115798)
	SpellInfo(weakened_blows duration=30)
]]

	OvaleScripts:RegisterScript(nil, name, desc, code, "include")
end
