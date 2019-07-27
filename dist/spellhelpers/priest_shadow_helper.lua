local __exports = LibStub:GetLibrary("ovale/scripts/ovale_priest")
if not __exports then return end
__exports.registerPriestShadowHelper = function(OvaleScripts)
do
	local name = "Shadowhelp"
	local desc = "[Xel][8.x] Spellhelper: Shadow"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_shadow_shadowwordpain) # Shadow Word: Pain
	Texture(spell_holy_stoicism) # Vampiric Touch
	Texture(spell_shadow_unholyfrenzy) # Mind Blast
	Texture(spell_shadow_siphonmana) # Mind Flay
	Texture(228260) # Void Eruption
	Texture(ability_ironmaidens_convulsiveshadows) # Void Bolt (Replaces Void Eruption)
	Texture(spell_shadow_mindshear) # Mind Sear
	Texture(ability_priest_silence) # Silence

	# Buffs
	Texture(spell_shadow_shadowform) # Shadowform
	Texture(spell_holy_wordfortitude) # Power Word: Fortitude
	Texture(spell_shadow_dispersion) # Dispersion
	Texture(spell_shadow_shadowfiend) # Shadowfiend
	
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
	Texture(spell_mage_presenceofmind) # Shadow Word: Void (T1) (Replaces Mind Blast)
	Texture(spell_shadow_mindbomb) # Mind Bomb (T4) (Replaces Psychic Scream)
	Texture(spell_shadow_psychichorrors) # Psychic Horror (T4)
	Texture(spell_shadow_demonicfortitude) # Shadow Word: Death (T5)
	Texture(spell_shadow_shadowfury) # Shadow Crash (T5)
	Texture(spell_shadow_soulleech_3) # Mindbender (T6) (Replaces Shadowfiend)
	Texture(spell_priest_voidsear) # Void Torrent (T6)
	Texture(achievement_boss_triumvirate_darknaaru) # Dark Ascension (T7)
	Texture(achievement_boss_generalvezax_01) # Surrender to Madness (T7)

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

		OvaleScripts:RegisterScript("PRIEST", "shadow", name, desc, code, "script")
	end
end
