local __exports = LibStub:GetLibrary("ovale/scripts/ovale_deathknight")
if not __exports then return end
__exports.registerDeathKnightFrostHelper = function(OvaleScripts)
do
	local name = "DKFhelp"
	local desc = "[Xel][8.0] Spellhelper: Frost"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_deathknight_classicon) # Obliterate
	Texture(spell_deathknight_empowerruneblade2) # Frost STrike
	Texture(spell_frost_arcticwinds) # Howling Blast
	Texture(spell_frost_chainsofice) # Chains of Ice
	Texture(ability_deathknight_remorselesswinters2) # Remorseless Winter
	Texture(spell_deathknight_butcher2) # Death Strike
	Texture(spell_deathknight_mindfreeze) # Mind Freeze

	# Buffs
	Texture(ability_deathknight_pillaroffrost) # Pillar of Frost
	Texture(inv_sword_62) # Empower Rune Weapon
	
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
	Texture(inv_misc_horn_02) # Horn of Winter (T2)
	Texture(ability_deathknight_asphixiate) # Asphyxiate (T3)
	Texture(spell_frost_chillingblast) # Blinding Sleet (T3)
	Texture(inv_misc_2h_farmscythe_a_01) # Frostscythe (T4)
	Texture(ability_hunter_glacialtrap) # Glacial Advance (T6)
	Texture(achievement_boss_sindragosa) # Frostwyrm's Fury (T6)
	Texture(spell_deathknight_breathofsindragosa) # Breath of Sindragosa(T7)

	# Racials
	Texture(racial_orc_berserkerstrength) # Blood Fury (Orc)
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(ability_warstomp) # War Stomp (Tauren)
	Texture(spell_shadow_raisedead) # Will of the Forsaken (Undead)
	Texture(inv_gizmo_rocketlauncher) # Rocket Barrage (Goblin)
	Texture(spell_shadow_unholystrength) # Stoneform (Dwarf)
	Texture(spell_shadow_charm) # Every Man for Himself (Human)
	Texture(spell_holy_holyprotection) # Gift of the Naaru (Draenei)
	Texture(ability_racial_darkflight) # Darkflight (Worgen)
	Texture(ability_rogue_trip) # Escape Artist (Gnome)
	Texture(ability_ambush) # Shadowmeld (Night elf)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("DEATHKNIGHT", "frost", name, desc, code, "script")
	end
end
