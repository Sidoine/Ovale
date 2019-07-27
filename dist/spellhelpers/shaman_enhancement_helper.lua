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

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("SHAMAN", "enhancement", name, desc, code, "script")
	end
end
