local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueOutlawHelper = function(OvaleScripts)
do
	local name = "ROGUEPOKEY"
	local desc = "[Xel][8.x] Spellhelper: Pokey (Outlaw)"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_shadow_ritualofsacrifice) # Sinister Strike
	Texture(ability_rogue_ambush) # Ambush (Stealth only)
	Texture(ability_rogue_pistolshot) # Pistol Shot
	Texture(inv_weapon_rifle_01) # Between the Eyes
	Texture(ability_rogue_waylay) # Dispatch

	# Interrupts
	Texture(ability_kick) # Kick
	Texture(ability_gouge) # Gouge
	Texture(ability_cheapshot) # Cheap Shot
	Texture(spell_shadow_mindsteal) # Blind

	# Buffs
	Texture(ability_rogue_rollthebones) # Roll the Bones
	Texture(ability_stealth) # Stealth
	Texture(ability_vanish) # Vanish
	Texture(spell_shadow_shadowworddominate) # Adrenaline Rush
	Texture(ability_rogue_crimsonvial) # Crimson Vial
	Texture(ability_warrior_punishingblow) # Blade Flurry

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
	Texture(ability_creature_cursed_02) # Ghostly Strike (T1)
	Texture(achievement_bg_killingblow_berserker) # Marked for Death (T3)
	Texture(ability_rogue_slicedice) # Slice and Dice (T6) (replaces Roll the Bones)
	Texture(ability_arakkoa_spinning_blade) # Blade Rush (T7)
	Texture(ability_rogue_murderspree) # Killing Spree (T7)

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
	Texture(ability_racial_forceshield) # Arcane Pulse (Nightborne)































}
]]

		OvaleScripts:RegisterScript("ROGUE", "outlaw", name, desc, code, "script")
	end
end
