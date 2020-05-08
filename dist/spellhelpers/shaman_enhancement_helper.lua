local __exports = LibStub:GetLibrary("ovale/scripts/ovale_shaman")
if not __exports then return end
__exports.registerShamanEnhancementHelper = function(OvaleScripts)
do
	local name = "SHAWMUNENHANCEhelp"
	local desc = "[Xel][8.x] Spellhelper: Enhancement"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_shaman_stormstrike) # Stormstrike
	Texture(ability_skyreach_four_wind) # Windstrike (Stormstrike during Ascendance)
	Texture(spell_nature_rockbiter) # Rockbiter
	Texture(spell_fire_flametounge) # Flametongue
	Texture(spell_shaman_unleashweapon_frost) # Frostbrand
	Texture(ability_shaman_lavalash) # Lava Lash
	Texture(spell_shaman_crashlightning) # Crash Lightning
	Texture(spell_nature_lightning) # Lightning Bolt
	Texture(spell_nature_cyclone) # Wind Shear
	Texture(spell_nature_brilliance) # Lightning Surge Totem
	Texture(spell_shaman_hex) # Hex

	# Buffs
	Texture(spell_nature_earthelemental_totem) # Earth Elemental Totem
	Texture(spell_shaman_feralspirit) # Feral Spirit
	Texture(spell_nature_spiritwolf) # Ghost Wolf
	Texture(spell_nature_healingway) # Healing Surge
	Texture(ability_shaman_astralshift) # Astral Shift

	# PvP Talent skills
	Texture(spell_nature_bloodlust) # Bloodlust (Shamanism, Horde)
	Texture(ability_shaman_heroism) # Heroism (Shamanism, Alliance)

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

	# Talents
	Texture(spell_nature_lightningshield) # Lightning Shield (T1)
	Texture(spell_nature_wrathofair_totem) # Totem Mastery (T2)
	Texture(spell_nature_skinofearth) # Earth Shield (T3)
	Texture(spell_beastmaster_wolf) # Feral Lunge (T5)
	Texture(ability_shaman_windwalktotem) # Wind Rush Totem (T5)
	Texture(ability_ironmaidens_swirlingvortex) # Fury of Air (T6)
	Texture(ability_rhyolith_lavapool) # Sundering (T6)
	Texture(ability_earthen_pillar) # Earthen Spike (T7)
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

		OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
	end
end
