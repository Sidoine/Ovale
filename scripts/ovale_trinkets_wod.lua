local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_trinkets_wod"
	local desc = "[6.0.3] Ovale: Trinkets (Warlords of Draenor)"
	local code = [[
# Trinkets from Warlords of Draenor.

# Agility
	SpellInfo(177597 buff_cd=120)				# Lucky Double-Sided Coin (on-use)

# Bonus armor
	SpellInfo(176873 buff_cd=120)				# Tablet of Turnbuckle Teamwork (on-use)
	SpellInfo(177053 buff_cd=65)				# Evergaze Arcane Eidolon

# Critical Strike
	SpellInfo(162915 buff_cd=115)				# Skull of War
	SpellInfo(162917 buff_cd=115)				# Knight's Badge
	SpellInfo(162919 buff_cd=115)				# Sandman's Pouch
	SpellInfo(165532 buff_cd=120)				# Bonemaw's Big Toe (on-use)
	SpellInfo(165532 buff_cd=120)				# Voidmender's Shadowgem (on-use)
	SpellInfo(165830 buff_cd=65)				# Munificent Emblem of Terror
	SpellInfo(176978 buff_cd=65)				# Immaculate Living Mushroom
	SpellInfo(176982 buff_cd=65)				# Stoneheart Idol
	SpellInfo(177040 buff_cd=65)				# Tectus' Beating Heart
	SpellInfo(177046 buff_cd=65)				# Goren Soul Repository
	SpellInfo(177067 buff_cd=65 max_stacks=20)	# Humming Blackiron Trigger

# Haste
	SpellInfo(165531 buff_cd=120)				# Fleshrender's Meathook (on-use)
	SpellInfo(165821 buff_cd=65)				# Munificent Bonds of Fury
	SpellInfo(165821 buff_cd=65)				# Spores of Alacrity
	SpellInfo(165821 buff_cd=65)				# Witherbark's Branch
	SpellInfo(176875 buff_cd=120)				# Shards of Nothing (on-use)
	SpellInfo(176879 buff_cd=120)				# Emblem of Caustic Healing (on-use)
	SpellInfo(176882 buff_cd=120)				# Turbulent Focusing Crystal (on-use)
	SpellInfo(176885 buff_cd=90)				# Turbulent Seal of Defiance (on-use)
	SpellInfo(176937 buff_cd=65)				# Formidable Relic of Blood
	SpellInfo(176943 buff_cd=65)				# Formidable Censer of Faith
	SpellInfo(176980 buff_cd=65)				# Furyheart Talisman
	SpellInfo(177035 buff_cd=65)				# Meaty Dragonspine Trophy
	SpellInfo(177051 buff_cd=65)				# Darmac's Unstable Talisman
	SpellInfo(177086 buff_cd=65 max_stacks=20)	# Auto-Repairing Autoclave
	SpellInfo(177102 buff_cd=65 max_stacks=20)	# Battering Talisman

# Mastery
	SpellInfo(165485 buff_cd=120)				# Kihra's Adrenaline Injector (on-use)
	SpellInfo(165535 buff_cd=90)				# Kyrak's Vileblood Serum (on-use)
	SpellInfo(165535 buff_cd=90)				# Tharbek's Lucky Pebble (on-use)
	SpellInfo(165824 buff_cd=65)				# Munificent Censer of Tranquility
	SpellInfo(165824 buff_cd=65)				# Xeri'tac's Unhatched Egg Sac
	SpellInfo(176876 buff_cd=120)				# Pol's Blinded Eye (on-use)
	SpellInfo(176883 buff_cd=90)				# Turbulent Vial of Toxin (on-use)
	SpellInfo(176884 buff_cd=90)				# Turbulent Relic of Mendacity (on-use)
	SpellInfo(176939 buff_cd=65)				# Formidable Jar of Doom
	SpellInfo(176941 buff_cd=65)				# Formidable Orb of Putrescence
	SpellInfo(177042 buff_cd=65)				# Horn of Screaming Spirits
	SpellInfo(177056 buff_cd=65)				# Blast Furnace Door

# Multistrike
	SpellInfo(165542 buff_cd=90)				# Gor'ashan's Lodestone Spike (on-use)
	SpellInfo(165832 buff_cd=65)				# Coagulated Genesaur Blood
	SpellInfo(176874 buff_cd=120)				# Vial of Convulsive Shadows
	SpellInfo(176878 buff_cd=120)				# Beating Heart of the Mountain (on-use)
	SpellInfo(176881 buff_cd=120)				# Turbulent Emblem (on-use)
	SpellInfo(176935 buff_cd=65)				# Formidable Fang
	SpellInfo(176984 buff_cd=65)				# Blackheart Enforcer's Medallion
	SpellInfo(177038 buff_cd=65)				# Scales of Doom
	SpellInfo(177063 buff_cd=65)				# Elementalist's Shielding Talisman
	SpellInfo(177081 buff_cd=65 max_stacks=20)	# Blackiron Micro Crucible
	SpellInfo(177096 buff_cd=65 max_stacks=20)	# Forgemaster's Insignia

# Spellpower
	SpellInfo(177594 buff_cd=120)				# Copeland's Clarity (on-use)

# Spirit
	SpellInfo(162913 buff_cd=115)				# Winged Hourglass
	SpellInfo(177060 buff_cd=65)				# Ironspike Chew Toy

# Strength
	SpellInfo(177189 buff_cd=90)				# Scabbard of Kyanos

# Versatility
	SpellInfo(165534 buff_cd=120)				# Enforcer's Stun Grenade (on-use)
	SpellInfo(165543 buff_cd=90)				# Emberscale Talisman (on-use)
	SpellInfo(165543 buff_cd=90)				# Ragewing's Firefang (on-use)
	SpellInfo(165833 buff_cd=65)				# Leaf of the Ancient Protectors
	SpellInfo(165833 buff_cd=65)				# Munificent Orb of Ice
	SpellInfo(165833 buff_cd=65)				# Munificent Soul of Compassion
	SpellInfo(176974 buff_cd=65)				# Mote of the Mountain
]]

	OvaleScripts:RegisterScript(nil, name, desc, code, "include")
end
