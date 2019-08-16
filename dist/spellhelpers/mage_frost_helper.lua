local __exports = LibStub:GetLibrary("ovale/scripts/ovale_mage")
if not __exports then return end
__exports.registerMageFrostHelper = function(OvaleScripts)
do
	local name = "MAGEFROST"
	local desc = "[Xel][8.x] Spellhelper: Frost"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_frost_frostbolt02) # Frostbolt
	Texture(spell_frost_frostblast) # Ice Lance
	Texture(ability_warlock_burningembersblue) # Flurry
	Texture(spell_frost_glacier) # Cone of Cold
	Texture(spell_frost_frostnova) # Frost Nova
	Texture(spell_frost_frozenorb) # Frozen Orb
	Texture(spell_frost_icestorm) # Blizzard
	
	# Buffs
	Texture(spell_frost_coldhearted) # Icy Veins
	Texture(spell_ice_lament) # Ice Barrier
	Texture(spell_holy_magicalsentry) # Arcane Intellect
	Texture(spell_arcane_arcane02) # Spellsteal
	
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
	Texture(spell_mage_icenova) # Ice Nova (T1)
	Texture(spell_arcane_massdispel) # Shimmer (T2)
	Texture(spell_mage_iceflows) # Ice Floes (T2)
	Texture(spell_magic_lesserinvisibilty) # Mirror Image (T3)
	Texture(spell_mage_runeofpower) # Rune of Power (T3)
	Texture(artifactability_frostmage_ebonbolt) # Ebonbolt (T4)
	Texture(spell_mage_cometstorm) # Comet Storm (T6)
	Texture(ability_mage_rayoffrost) # Ray of Frost (T7)
	Texture(ability_mage_glacialspike) # Glacial Spike (T7)

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

		OvaleScripts:RegisterScript("MAGE", "frost", name, desc, code, "script")
	end
end
