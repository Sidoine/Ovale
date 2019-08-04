local __exports = LibStub:GetLibrary("ovale/scripts/ovale_mage")
if not __exports then return end
__exports.registerMageFireHelper = function(OvaleScripts)
do
	local name = "MAGEFIRE"
	local desc = "[Xel][8.x] Spellhelper: Fire"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_fire_flamebolt) # Fireball
	Texture(spell_fire_fireball) # Fire Blast
	Texture(spell_fire_fireball02) # Pyroblast
	Texture(spell_fire_soulburn) # Scorch
	Texture(spell_fire_selfdestruct) # Flamestrike
	Texture(inv_misc_head_dragon_01) # Dragons Breath
	Texture(spell_frost_iceshock) # Counterspell

	# Buffs
	Texture(spell_fire_sealoffire) # Combustion
	Texture(ability_mage_moltenarmor) # Blazing Barrier
	Texture(spell_holy_magicalsentry) # Arcane Intellect
	
	# Items
	Texture(inv_jewelry_talisman_12) # Link to a trinket macro
	
	# Heart of Azeroth Skills
	Texture(spell_azerite_essence_15) # Concentrated Flame
	Texture(spell_azerite_essence05) # Memory of Lucid Dreams
	Texture(298277) # Blood of the Enemy
	Texture(spell_azerite_essence14) # Guardian of Azeroth
	Texture(spell_azerite_essence12) # Focused Azerite Beam
	Texture(spell_azerite_essence04) # Purifying Blast
	Texture(spell_azerite_essence10) # Ripple in Space
	Texture(spell_azerite_essence03) # The Unbound Force
	Texture(inv_misc_azerite_01) # Worldvein Resonance

	# Talents
	Texture(spell_arcane_massdispel) # Shimmer (T2)
	Texture(spell_holy_excorcism_02) # Blast Wave (T2)
	Texture(spell_magic_lesserinvisibilty) # Mirror Image (T3)
	Texture(spell_mage_runeofpower) # Rune of Power (T3)
	Texture(ability_mage_livingbomb) # Living Bomb (T6)
	Texture(spell_mage_meteor) # Meteor (T7)

	# Racials
	Texture(racial_orc_berserkerstrength) # Blood Fury (Orc)
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(spell_shadow_raisedead) # Will of the Forsaken (Undead)
	Texture(inv_gizmo_rocketlauncher) # Rocket Barrage (Goblin)
	Texture(pandarenracial_quiveringpain) # Quaking Palm (Pandaren)
	Texture(spell_shadow_unholystrength) # Stoneform (Dwarf)
	Texture(spell_shadow_charm) # Every Man for Himself (Human)
	Texture(spell_holy_holyprotection) # Gift of the Naaru (Draenei)
	Texture(ability_racial_darkflight) # Darkflight (Worgen)
	Texture(ability_rogue_trip) # Escape Artist (Gnome)
	Texture(ability_ambush) # Shadowmeld (Night Elf)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("MAGE", "fire", name, desc, code, "script")
	end
end
