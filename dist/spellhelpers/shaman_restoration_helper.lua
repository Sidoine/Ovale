local __exports = LibStub:GetLibrary("ovale/scripts/ovale_shaman")
if not __exports then return end
__exports.registerShamanRestorationHelper = function(OvaleScripts)
do
	local name = "SHAWMUNRESTOhelp"
	local desc = "[Xel][7.x] Spellhelper: Restoration"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_nature_healingwavelesser) # Healing Wave
	Texture(spell_nature_healingway) # Healing Surge
	Texture(spell_nature_riptide) # Riptide
	Texture(spell_nature_healingwavegreater) # Chain Heal
	Texture(spell_nature_giftofthewaterspirit) # Healing Rain
	Texture(ability_shaman_cleansespirit) # Purify Spirit
	Texture(spell_nature_cyclone) # Wind Shear

	# Buffs
	Texture(spell_shaman_spiritwalkersgrace) # Spiritwalker's Grace
	Texture(ability_shaman_astralshift) # Astral Shift
	Texture(inv_spear_04) # Healing Stream Totem
	Texture(ability_shaman_healingtide) # Healing Tide Totem
	Texture(spell_shaman_spiritlink) # Spirit Link Totem
	Texture(spell_nature_spiritwolf) # Ghost Wolf
	
	# Artifact
	Texture(inv_mace_1h_artifactazshara_d_02) # Gift of the Queen
	
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
	Texture(spell_shaman_unleashweapon_life) # Unleash Life (T1)
	Texture(ability_skyreach_four_wind) # Gust of Wind (T2)
	Texture(ability_shaman_windwalktotem) # Wind Rush Totem (T2)
	Texture(spell_nature_brilliance) # Lightning Surge Totem (T3)
	Texture(spell_nature_stranglevines) # Earthgrab Totem (T3)
	Texture(spell_totem_wardofdraining) # Voodoo Totem (T3)
	Texture(ability_shaman_ancestralguidance) # Ancestral Guidance (T4)
	Texture(spell_nature_reincarnation) # Ancestral Protection Totem (T5)
	Texture(spell_nature_stoneskintotem) # Earthen Shield Totem (T5)
	Texture(ability_shaman_condensationtotem) # Cloudburst Totem (T6)
	Texture(spell_fire_elementaldevastation) # Ascendance (T7)
	Texture(ability_shawaterelemental_split) # Wellspring (T7)

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

		OvaleScripts:RegisterScript("SHAMAN", "restoration", name, desc, code, "script")
	end
end
