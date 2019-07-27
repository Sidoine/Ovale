local __exports = LibStub:GetLibrary("ovale/scripts/ovale_warrior")
if not __exports then return end
__exports.registerWarriorArmsHelper = function(OvaleScripts)
do
	local name = "WARRARMShelp"
	local desc = "[Xel][7.0.3] Spellhelper: Arms"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_warrior_decisivestrike) # Slam
	Texture(ability_warrior_savageblow) # Mortal Strike
	Texture(ability_warrior_colossussmash) # Colossus Smash
	Texture(ability_warrior_bladestorm) # Bladestorm
	Texture(ability_warrior_cleave) # Cleave
	Texture(ability_whirlwind) # Whirlwind
	Texture(inv_sword_48) # Execute
	Texture(inv_gauntlets_04) # Pummel
	Texture(ability_warrior_charge) # Charge
	Texture(inv_axe_66) # Heroic Throw
	Texture(ability_warrior_devastate) # Victory Rush

	# Buffs
	Texture(warrior_talent_icon_innerrage) # Battle Cry
	Texture(spell_nature_ancestralguardian) # Berserker Rage
	
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
	Texture(ability_meleedamage) # Overpower (T1)
	Texture(ability_warrior_shockwave) # Shockwave (T2)
	Texture(warrior_talent_icon_stormbolt) # Storm Bolt (T2)
	Texture(ability_gouge) # Rend (T3)
	Texture(warrior_talent_icon_avatar) # Avatar (T3)
	Texture(ability_warrior_defensivestance) # Defensive Stance (T4)
	Texture(ability_warrior_focusedrage) # Focused Rage (T5)
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

		OvaleScripts:RegisterScript("WARRIOR", "arms", name, desc, code, "script")
	end
end
