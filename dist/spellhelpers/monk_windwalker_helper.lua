local __exports = LibStub:GetLibrary("ovale/scripts/ovale_monk")
if not __exports then return end
__exports.registerMonkWindwalkerHelper = function(OvaleScripts)
do
	local name = "MWWhelp"
	local desc = "[Xel][8.x] Spellhelper: Windwalker"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_monk_tigerpalm) # Tiger Palm
	Texture(ability_monk_roundhousekick) # Blackout Kick
	Texture(ability_monk_risingsunkick) # Rising Sun Kick
	Texture(monk_ability_fistoffury) # Fists of Fury
	Texture(ability_monk_cranekick_new) # Spinning Crane Kick
	Texture(ability_monk_touchofdeath) # Touch of Death
	Texture(ability_monk_cracklingjadelightning) # Crackling Jade Lightning
	Texture(ability_monk_spearhand) # Spear Hand Strike
	Texture(ability_monk_paralysis) # Paralysis
	Texture(ability_monk_legsweep) # Leg Sweep
	
	# Buffs
	Texture(spell_nature_giftofthewild) # Storm, Earth, and Fire
	
	# Items
	Texture(inv_jewelry_talisman_12) # Trinkets
	
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
	Texture(ability_monk_expelharm) # Conflict and Strife: Reverse Harm

	# Talents
	Texture(ability_monk_chiwave) # Chi Wave (T1)
	Texture(spell_arcane_arcanetorrent) # Chi Burst (T1)
	Texture(ability_monk_quitornado) # Chi Torpedo (T2)(replaces roll)
	Texture(ability_monk_tigerslust) # Tiger's Lust (T2)
	Texture(inv_fistofthewhitetiger) # Fist of the White Tiger (T3)
	Texture(ability_monk_energizingwine) # Energizing Elixir (T3)
	Texture(spell_monk_ringofpeace) # Ring of Peace (T4)
	Texture(spell_monk_diffusemagic) # Diffuse Magic (T5)
	Texture(ability_monk_dampenharm) # Dampen Harm (T5)
	Texture(ability_monk_rushingjadewind) # Rushing Jade Wind (T6)
	Texture(ability_monk_summontigerstatue) # Invoke Xuen, the White Tiger (T6)
	Texture(ability_monk_hurricanestrike) # Whirling Dragon Punch (T7)
	Texture(ability_monk_serenity) # Serenity (T7)(replaces SEF)

	# Racials
	Texture(racial_orc_berserkerstrength) # Blood Fury (Orc)
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(ability_warstomp) # War Stomp (Tauren)
	Texture(spell_shadow_raisedead) # Will of the Forsaken (Undead)
	Texture(pandarenracial_quiveringpain) # Quaking Palm (Pandaren)
	Texture(spell_shadow_unholystrength) # Stoneform (Dwarf)
	Texture(spell_shadow_charm) # Every Man for Himself (Human)
	Texture(spell_holy_holyprotection) # Gift of the Naaru (Draenei)
	Texture(ability_rogue_trip) # Escape Artist (Gnome)
	Texture(ability_ambush) # Shadowmeld (Night Elf)

	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("MONK", "windwalker", name, desc, code, "script")
	end
end