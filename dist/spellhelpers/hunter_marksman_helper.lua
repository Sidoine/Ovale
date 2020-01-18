local __exports = LibStub:GetLibrary("ovale/scripts/ovale_hunter")
if not __exports then return end
__exports.registerHunterMarksmanshipHelper = function(OvaleScripts)
do
	local name = "Xelhelpmark"
	local desc = "[Xel][8.x] Spellhelper: Marksman"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_impalingbolt) # Arcane Shot
	Texture(ability_upgrademoonglaive) # Multi-Shot
	Texture(inv_spear_07) # Aimed Shot
	Texture(ability_hunter_steadyshot) # Steady Shot
	Texture(ability_hunter_efficiency) # Rapid Fire
	Texture(ability_hunter_burstingshot) # Bursting Shot
	Texture(inv_ammo_arrow_03) # Counter Shot
	Texture(spell_frost_stun) # Concussive Shot

	# Buffs
	Texture(ability_trueshot) # Trueshot
	Texture(ability_hunter_onewithnature) # Exhilaration
	Texture(ability_hunter_mendpet) # Mend Pet
	Texture(inv_misc_pheonixpet_01) # Heart of the Phoenix
	Texture(ability_hunter_beastsoothe) # Revive Pet
	
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
	Texture(spell_hunter_exoticmunitions_poisoned) # Serpent Sting (T1)
	Texture(ability_hunter_murderofcrows) # A Murder of Crows (T1)
	Texture(ability_hunter_explosiveshot) # Explosive Shot (T2)
	Texture(ability_hunter_camouflage) # Camouflage (T3)
	Texture(ability_hunter_markedfordeath) # Hunter's Mark (T4)
	Texture(spell_shaman_bindelemental) # Binding Shot (T5)
	Texture(ability_hunter_rapidregeneration) # Barrage (T6)
	Texture(ability_hunter_crossfire) # Double Tap (T6)
	Texture(ability_cheapshot) # Piercing Shot (T7)

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

		OvaleScripts:RegisterScript("HUNTER", "marksmanship", name, desc, code, "script")
	end
end
