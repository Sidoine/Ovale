local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_trinket_mop"
	local desc = "[6.0] Ovale: Trinkets (Mists of Pandaria)"
	local code = [[
# Trinkets from Mists of Pandaria.

# Agility
	SpellInfo(126554 buff_cd=55)				# Bottle of Infinite Stars
	SpellInfo(126690 buff_cd=60)				# PvP agility trinket (on-use)
	SpellInfo(126707 buff_cd=55)				# PvP agility trinket (proc)
	SpellInfo(128984 buff_cd=55)				# Relic of Xuen (agility)
	SpellInfo(138699 buff_cd=115)				# Vicious Talisman of the Shado-Pan Assault
	SpellInfo(138756 buff_cd=50 max_stacks=10)	# Renataki's Soul Charm
	SpellInfo(138938 buff_cd=55)				# Bad Juju
	SpellInfo(146308 buff_cd=115)				# Assurance of Consequence
	SpellInfo(146310 buff_cd=60)				# Ticking Ebon Detonator
	SpellInfo(148896 buff_cd=85)				# Sigil of Rampage
	SpellInfo(148903 buff_cd=65)				# Haromm's Talisman

# Critical Strike
	SpellInfo(138963 buff_cd=110)				# Unerring Vision of Lei-Shen
	SpellInfo(138963 buff_cd=165 specialization=balance)	# UVLS adjustment for balance druids
	SpellInfo(146285 buff_cd=65 max_stacks=20)	# Skeer's Bloodsoaked Talisman

# Intellect
	SpellInfo(126577 buff_cd=55)				# Light of the Cosmos
	SpellInfo(126683 buff_cd=60)				# PvP intellect trinket (on-use)
	SpellInfo(126705 buff_cd=55)				# PvP intellect trinket (proc)
	SpellInfo(128985 buff_cd=55)				# Relic of Yu'lon
	SpellInfo(136082 buff_cd=60)				# Shock-Charger/Static-Caster's Medallion
	SpellInfo(138786 buff_cd=50 max_stacks=10)	# Wushoolay's Final Choice
	SpellInfo(138898 buff_cd=55)				# Breath of the Hydra
	SpellInfo(139133 buff_cd=55)				# Cha-Ye's Essence of Brilliance (assume 20% crit chance)
	SpellInfo(146046 buff_cd=115)				# Purified Bindings of Immerseus
	SpellInfo(146184 buff_cd=65 max_stacks=10)	# Black Blood of Y'Shaarj
	SpellInfo(148897 buff_cd=85)				# Frenzied Crystal of Rage
	SpellInfo(148906 buff_cd=65)				# Kardris' Toxic Totem

# Strength
	SpellInfo(126582 buff_cd=55)				# Lei Shen's Final Orders
	SpellInfo(126679 buff_cd=60)				# PvP strength trinket (on-use)
	SpellInfo(126700 buff_cd=55)				# PvP strength trinket (proc)
	SpellInfo(128986 buff_cd=55)				# Relic of Xuen (strength)
	SpellInfo(138702 buff_cd=85)				# Brutal Talisman of the Shado-Pan Assault
	SpellInfo(138759 buff_cd=50 max_stacks=10)	# Fabled Feather of Ji-Kun
	SpellInfo(138870 buff_cd=17 max_stacks=5)	# Primordius' Talisman of Rage
	SpellInfo(146245 buff_cd=55)				# Evil Eye of Galakras
	SpellInfo(146250 buff_cd=115)				# Thok's Tail Tip
	SpellInfo(148899 buff_cd=85)				# Fusion-Fire Core
]]

	OvaleScripts:RegisterScript(nil, name, desc, code, "include")
end
