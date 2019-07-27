local __exports = LibStub:GetLibrary("ovale/scripts/ovale_priest")
if not __exports then return end
__exports.registerPriestDisciplineHelper = function(OvaleScripts)
do
	local name = "Disciplinehelp"
	local desc = "[Xel][7.1.5] Spellhelper: Discipline"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_holy_holysmite) # Smite
	Texture(spell_shadow_shadowwordpain) # Shadow Word: Pain
	Texture(spell_holy_penance) # Penance
	Texture(spell_priest_plea_blue) # Plea
	Texture(spell_shadow_shadowmend) # Shadow Mend
	Texture(194509) # Power Word: Radiance

	# Buffs
	Texture(spell_holy_powerwordshield) # Power Word: Shield
	Texture(spell_shadow_shadowfiend) # Shadowfiend
	Texture(spell_holy_painsupression) # Pain Suppression
	
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
	Texture(spell_warlock_focusshadow) # Schism (T1)
	Texture(ability_priest_flashoflight) # Power Word: Solace (T4)
	Texture(spell_shadow_soulleech_3) # Mind Bender (T4) (Replaces Shadowfiend)
	Texture(spell_holy_powerinfusion) # Power Infusion (T5)
	Texture(ability_mage_firestarter) # Purge the Wicked (T7)
	Texture(spell_shadow_summonvoidwalker) # Shadow Covenant (T7)

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

		OvaleScripts:RegisterScript("PRIEST", "discipline", name, desc, code, "script")
	end
end
