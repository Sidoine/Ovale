local __exports = LibStub:GetLibrary("ovale/scripts/ovale_mage")
if not __exports then return end
__exports.registerMageArcaneHelper = function(OvaleScripts)
do
	local name = "MAGEARCANE"
	local desc = "[Xel][8.0] Spellhelper: Arcane"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_arcane_blast) # Arcane Blast
	Texture(spell_nature_starfall) # Arcane Missiles
	Texture(ability_mage_arcanebarrage) # Arcane Barrage
	Texture(spell_nature_wispsplode) # Arcane Explosion
	Texture(spell_frost_iceshock) # Counterspell

	# Buffs
	Texture(spell_holy_magicalsentry) # Arcane Brilliance
	Texture(spell_nature_lightning) # Arcane Power
	Texture(spell_nature_enchantarmor) # Presence of Mind
	Texture(spell_nature_purge) # Evocation
	
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
	Texture(ability_essence_reapingflames) # Reaping Flames
	Texture(ability_essence_momentofglory) # Moment of Glory
	Texture(ability_essence_replicaofknowledge) # Replica of Knowledge
	
	# Utility
	Texture(spell_arcane_arcane02) # Spellsteal
	Texture(spell_nature_slow) # Slow
	Texture(spell_frost_frostnova) # Frost Nova
	Texture(spell_magearmor) # Prismatic Barrier

	# Talents
	Texture(ability_socererking_arcanemines) # Arcane Familiar (T1)
	Texture(spell_magic_lesserinvisibilty) # Mirror Image (T3)
	Texture(spell_mage_runeofpower) # Rune of Power (T3)
	Texture(ability_thunderking_overcharge) # Charged Up (T4)
	Texture(spell_mage_supernova) # Supernova (T4)
	Texture(spell_mage_nethertempest) # Nether Tempest (T6)
	Texture(spell_mage_arcaneorb) # Arcane Orb (T7)

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
	Texture(ability_ambush) # Shadowmeld (Night elf)
	Texture(ability_racial_forceshield) # Arcane Pulse (Nightborne)
	Texture(ability_racial_bullrush) # Bull Rush (Highmountain Tauren)
	Texture(ability_racial_orbitalstrike) # Light's Judgment (Lightforged Draenei)
	Texture(ability_racial_ancestralcall) # Ancestral Call (Mag'har Orcs)
	Texture(ability_racial_fireblood) # Fireblood (Dark Iron Dwarves)
	Texture(ability_racial_haymaker) # Haymaker (Kul Tiran Human)
	Texture(ability_racial_regeneratin) # Regeneratin (Zandalari Trolls)
	Texture(ability_racial_hyperorganiclightoriginator) # Hyper Organic Light Originator (Mechagnome)
	Texture(ability_racial_bagoftricks) # Bag of Tricks (Vulpera)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("MAGE", "arcane", name, desc, code, "script")
	end
end
