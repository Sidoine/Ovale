local __exports = LibStub:GetLibrary("ovale/scripts/ovale_shaman")
if not __exports then return end
__exports.registerShamanElementalHelper = function(OvaleScripts)
do
	local name = "SHAWMUNELEMhelp"
	local desc = "[Xel][8.x] Spellhelper: Elemental"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_nature_lightning) # Lightning Bolt
	Texture(spell_nature_chainlightning) # Chain Lightning
	Texture(ability_mage_firestarter) # Lava Beam (Ascendance Chain Lightning)
	Texture(spell_shaman_lavaburst) # Lava Burst
	Texture(spell_fire_flameshock) # Flame Shock
	Texture(spell_nature_earthshock) # Earth Shock
	Texture(spell_frost_frostshock) # Frost Shock
	Texture(spell_shaman_earthquake) # Earthquake
	Texture(spell_nature_cyclone) # Wind Shear
	Texture(spell_shaman_hex) # Hex
	Texture(shaman_pvp_lightninglasso) # Lightning Lasso

	# Buffs
	Texture(spell_fire_elemental_totem) # Fire Elemental Totem
	Texture(spell_nature_earthelemental_totem) # Earth Elemental Totem
	Texture(spell_nature_healingway) # Healing Surge
	Texture(ability_shaman_astralshift) # Astral Shift

	# Items
	Texture(inv_jewelry_talisman_12) # Trinkets

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

	# Talents
	Texture(shaman_talent_elementalblast) # Elemental Blast (T1)
	Texture(spell_nature_wrathofair_totem) # Totem Mastery (T2)
	Texture(spell_nature_skinofearth) # Earth Shield (T3)
	Texture(inv_stormelemental) # Storm Elemental (T4)(Replaces Fire Elemental Totem)
	Texture(spell_shaman_spewlava) # Liquid Magma Totem (T4)
	Texture(ability_shaman_ancestralguidance) # Ancestral Guidance (T5)
	Texture(ability_shaman_windwalktotem) # Wind Rush Totem (T5)
	Texture(spell_frost_iceshard) # Icefury (T6)
	Texture(ability_thunderking_lightningwhip) # Stormkeeper (T6)
	Texture(spell_fire_elementaldevastation) # Ascendance (T7)

	# Racials
	Texture(racial_orc_berserkerstrength) # Blood Fury (Orc)
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(ability_warstomp) # War Stomp (Tauren)
	Texture(spell_shadow_raisedead) # Will of the Forsaken (Undead)
	Texture(inv_gizmo_rocketlauncher) # Rocket Barrage (Goblin)
	Texture(pandarenracial_quiveringpain) # Quaking Palm (Pandaren)
	Texture(spell_shadow_unholystrength) # Stoneform (Dwarf)
	Texture(spell_holy_holyprotection) # Gift of the Naaru (Draenei)
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

		OvaleScripts:RegisterScript("SHAMAN", "elemental", name, desc, code, "script")
	end
end
