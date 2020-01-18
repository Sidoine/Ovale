local __exports = LibStub:GetLibrary("ovale/scripts/ovale_warrior")
if not __exports then return end
__exports.registerWarriorFuryHelper = function(OvaleScripts)
do
	local name = "WARRFURYhelp"
	local desc = "[Xel][8.x] Spellhelper: Fury"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_whirlwind) # Whirlwind
	Texture(spell_nature_bloodlust) # Bloodthirst
	Texture(warrior_wild_strike) # Raging Blow
	Texture(inv_sword_48) # Execute
	Texture(ability_warrior_rampage) # Rampage
	Texture(ability_warrior_charge) # Charge
	Texture(ability_warrior_devastate) # Victory Rush
	Texture(inv_axe_66) # Heroic Throw

	# Interrupts
	Texture(inv_gauntlets_04) # Pummel
	Texture(ability_golemthunderclap) # Intimidating Shout

	# Buffs
	Texture(ability_warrior_battleshout) # Battle Shout
	Texture(spell_nature_ancestralguardian) # Berserker Rage
	Texture(warrior_talent_icon_innerrage) # Recklessness
	Texture(ability_warrior_focusedrage) # Enraged Regeneration

	# Utility
	Texture(spell_shadow_deathscream) # Piercing Howl

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
	Texture(spell_impending_victory) # Impending Victory (T2) (replaces Victory Rush)
	Texture(warrior_talent_icon_stormbolt) # Storm Bolt (T2)
	Texture(ability_warrior_weaponmastery) # Furious Slash (T3)
	Texture(ability_warrior_dragonroar) # Dragon Roar (T6)
	Texture(ability_warrior_bladestorm) # Bladestorm (T6)
	Texture(inv_mace_101) # Siegebreaker (T7)

	# Racials
	Texture(racial_orc_berserkerstrength) # Blood Fury (Orc)
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(ability_warstomp) # War Stomp (Tauren)
	Texture(spell_shadow_raisedead) # Will of the Forsaken (Undead)
	Texture(inv_gizmo_rocketlauncher) # Rocket Barrage (Goblin)
	Texture(pandarenracial_quiveringpain) # Quaking Palm (Pandaren)
	Texture(spell_shadow_unholystrength) # Stoneform (Dwarf)
	Texture(spell_shadow_charm) # Every Man for Himself (Human)
	Texture(spell_holy_holyprotection) # Gift of the Naaru (Draenei)
	Texture(ability_racial_darkflight) # Darkflight (Worgen)
	Texture(ability_rogue_trip) # Escape Artist (Gnome)
	Texture(ability_ambush) # Shadowmeld (Night Elf)
	Texture(ability_racial_fireblood) # Fireblood (Dark Iron Dwarf)
































}
]]

		OvaleScripts:RegisterScript("WARRIOR", "fury", name, desc, code, "script")
	end
end
