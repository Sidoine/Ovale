local __exports = LibStub:GetLibrary("ovale/scripts/ovale_monk")
if not __exports then return end
__exports.registerMonkBrewmasterHelper = function(OvaleScripts)
do
	local name = "MBMhelp"
	local desc = "[Xel][7.3] Spellhelper: Brewmaster"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(achievement_brewery_2) # Keg Smash
	Texture(ability_monk_tigerpalm) # Tiger Palm
	Texture(ability_monk_blackoutstrike) # Blackout Strike
	Texture(ability_monk_breathoffire) # Breath of Fire
	Texture(ability_monk_expelharm) # Expel Harm
	Texture(ability_monk_spearhand) # Spear Hand Strike
	Texture(ability_monk_paralysis) # Paralysis

	# Buffs
	Texture(ability_monk_ironskinbrew) # Ironskin Brew
	Texture(inv_misc_beer_06) # Purifying Brew
	Texture(ability_monk_fortifyingale_new) # Fortifying Brew
	
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
	Texture(spell_arcane_arcanetorrent) # Chi Burst (T1)
	Texture(ability_monk_chiwave) # Chi Wave (T1)
	Texture(ability_monk_quitornado) # Chi Torpedo (T2)
	Texture(ability_monk_tigerslust) # Tiger's Lust (T2)
	Texture(ability_monk_chibrew) # Black Ox Brew (T3)
	Texture(spell_monk_ringofpeace) # Ring of Peace (T4)
	Texture(monk_ability_summonoxstatue) # Summon Black Ox Statue (T4)
	Texture(ability_monk_legsweep) # Leg Sweep (T4)
	Texture(ability_monk_jasmineforcetea) # Healing Elixir (T5)
	Texture(ability_monk_dampenharm) # Dampen Harm (T5)
	Texture(ability_monk_rushingjadewind) # Rushing Jade Wind (T6)
	Texture(ability_monk_summontigerstatue) # Invoke Niuzao, the Black Ox (T6)

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
	Texture(ability_ambush) # Shadowmeld (Night elf)
	Texture(ability_racial_forceshield) # Arcane Pulse (Nightborne)
	Texture(ability_racial_bullrush) # Bull Rush (Highmountain Tauren)
	Texture(ability_racial_orbitalstrike) # Light's Judgment (Lightforged Draenei)
	Texture(ability_racial_ancestralcall) # Ancestral Call (Mag'har Orcs)
	Texture(ability_racial_fireblood) # Fireblood (Dark Iron Dwarves)
	Texture(ability_racial_haymaker) # Haymaker (Kul Tiran Human)
	Texture(ability_racial_regeneratin) # Regeneratin (Zandalari Trolls)
	Texture(ability_racial_hyperorganiclightoriginator) # Hyper Organic Light Originator (Mechagnome)
	Texture(ability_racial_bagoftricks) # Bag of Tricks (Vulpera)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("MONK", "brewmaster", name, desc, code, "script")
	end
end
