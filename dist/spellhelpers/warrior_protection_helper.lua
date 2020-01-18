local __exports = LibStub:GetLibrary("ovale/scripts/ovale_warrior")
if not __exports then return end
__exports.registerWarriorProtectionHelper = function(OvaleScripts)
do
	local name = "WARRPROThelp"
	local desc = "[Xel][7.x] Spellhelper: Protection"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(inv_sword_11) # Devastate
	Texture(ability_warrior_focusedrage) # Focused Rage
	Texture(inv_shield_05) # Shield Slam
	Texture(ability_warrior_revenge) # Revenge
	Texture(spell_nature_thunderclap) # Thunder Clap
	Texture(ability_warrior_devastate) # Victory Rush
	Texture(ability_warrior_victoryrush) # Intercept
	Texture(inv_axe_66) # Heroic Throw
	Texture(inv_gauntlets_04) # Pummel

	# Buffs
	Texture(ability_warrior_renewedvigor) # Ignore Pain
	Texture(ability_defend) # Shield Block
	Texture(warrior_talent_icon_innerrage) # Battle Cry
	Texture(spell_nature_ancestralguardian) # Berserker Rage
	Texture(ability_warrior_warcry) # Demoralizing Shout
	Texture(spell_holy_ashestoashes) # Last Stand
	Texture(ability_warrior_shieldwall) # Shield Wall
	
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
	Texture(ability_warrior_shockwave) # Shockwave (T1)
	Texture(warrior_talent_icon_stormbolt) # Storm Bolt (T1)
	Texture(spell_impending_victory) # Impending Victory (T2) (replaces Victroy Rush)
	Texture(warrior_talent_icon_avatar) # Avatar (T3)
	Texture(warrior_talent_icon_ravager) # Ravager (T7)

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
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("WARRIOR", "protection", name, desc, code, "script")
	end
end
