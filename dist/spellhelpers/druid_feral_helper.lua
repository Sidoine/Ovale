local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidFeralHelper = function(OvaleScripts)
do
	local name = "Feralhelp"
	local desc = "[Xel][8.x] Spellhelper: Feral"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_shadow_vampiricaura) # Shred
	Texture(ability_druid_disembowel) # Rake
	Texture(inv_misc_monsterclaw_03) # Swipe
	Texture(spell_druid_thrash) # Thrash
	Texture(ability_ghoulfrenzy) # Rip
	Texture(ability_druid_ferociousbite) # Ferocious Bite
	Texture(spell_nature_starfall) # Moonfire
	Texture(inv_bone_skull_04) # Skull Bash
	Texture(ability_druid_mangle) # Maim
	
	# Buffs
	Texture(ability_druid_catform) # Cat Form
	Texture(ability_druid_travelform) # Travel Form
	Texture(ability_druid_prowl) # Prowl
	Texture(ability_mount_jungletiger) # Tiger's Fury
	Texture(ability_druid_berserk) # Berserk
	Texture(spell_nature_resistnature) # Regrowth
	
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
	Texture(ability_druid_dash_orange) # Tiger Dash (T2)(Replaces Dash)
	Texture(spell_nature_natureblessing) # Renewal (T2)
	Texture(spell_druid_feralchargecat) # Wild Charge (Cat)(T2)
	Texture(ability_hunter_pet_bear) # Wild Charge (Bear)(T2)
	Texture(ability_druid_bash) # Mighty Bash (T4)
	Texture(spell_druid_massentanglement) # Mass Entanglement (T4)
	Texture(ability_druid_typhoon) # Typhoon (T4)
	Texture(ability_druid_skinteeth) # Savage Roar (T5)
	Texture(spell_druid_incarnation) # Incarnation: King of the Jungle (T5)
	Texture(ability_druid_ravage) # Brutal Slash (T6)(Replaces Swipe)
	Texture(artifactability_feraldruid_ashamanesbite) # Primal Wrath (T6)
	Texture(ability_druid_rake) # Feral Frenzy (T7)
	
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
	Texture(ability_ambush) # Shadowmeld (Night elf)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("DRUID", "feral", name, desc, code, "script")
	end
end
