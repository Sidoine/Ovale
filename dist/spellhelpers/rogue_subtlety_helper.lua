local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueSubtletyHelper = function(OvaleScripts)
do
	local name = "ROGUESHANKY"
	local desc = "[Xel][8.x] Spellhelper: Shanky (Subtlety)"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_backstab) # Backstab
	Texture(ability_rogue_shadowstrike) # Shadowstrike
	Texture(ability_rogue_eviscerate) # Eviscerate
	Texture(ability_rogue_nightblade) # Nightblade
	Texture(ability_rogue_shurikenstorm) # Shuriken Storm
	Texture(inv_throwingknife_07) # Shuriken Toss

	# Interrupts
	Texture(ability_kick) # Kick
	Texture(ability_rogue_kidneyshot) # Kidney Shot
	Texture(ability_cheapshot) # Cheap Shot
	Texture(spell_shadow_mindsteal) # Blind

	# Buffs
	Texture(ability_stealth) # Stealth
	Texture(ability_rogue_shadowstep) # Shadowstep
	Texture(spell_shadow_rune) # Symbols of Death
	Texture(ability_rogue_crimsonvial) # Crimson Vial
	Texture(ability_rogue_shadowdance) # Shadow Dance
	Texture(ability_vanish) # Vanish
	Texture(inv_knife_1h_grimbatolraid_d_03) # Shadow Blades

	# Buffs PvP (Used in PvE)
	Texture(spell_ice_lament) # Cold Blood

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
	Texture(ability_ironmaidens_convulsiveshadows) # Gloomblade (T1) (Replaces Backstab)
	Texture(achievement_bg_killingblow_berserker) # Marked for Death (T3)
	Texture(ability_rogue_sinistercalling) # Secret Technique (T7)
	Texture(ability_rogue_throwingspecialization) # Shuriken Tornado (T7)

	# Racials
	Texture(racial_orc_berserkerstrength) # Blood Fury (Orc)
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(spell_shadow_raisedead) # Will of the Forsaken (Undead)
	Texture(inv_gizmo_rocketlauncher) # Rocket Barrage (Goblin)
	Texture(pandarenracial_quiveringpain) # Quaking Palm (Pandaren)
	Texture(spell_shadow_unholystrength) # Stoneform (Dwarf)
	Texture(spell_shadow_charm) # Every Man for Himself (Human)
	Texture(ability_racial_darkflight) # Darkflight (Worgen)
	Texture(ability_rogue_trip) # Escape Artist (Gnome)
	Texture(ability_ambush) # Shadowmeld (Night Elf)



















































}
]]

		OvaleScripts:RegisterScript("ROGUE", "subtlety", name, desc, code, "script")
	end
end
