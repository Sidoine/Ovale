local __exports = LibStub:GetLibrary("ovale/scripts/ovale_demonhunter")
if not __exports then return end
__exports.registerDemonHunterHavocHelper = function(OvaleScripts)
do
	local name = "DMHAVOChelper"
	local desc = "[Xel][7.x] Spellhelper: Havoc"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(inv_weapon_glave_01) # Demon's Bite (Passive with Demon Blades Talent)
	Texture(ability_demonhunter_chaosstrike) # Chaos Strike
	Texture(inv_glaive_1h_npc_d_02) # Annihilation (Chaos Strike)
	Texture(ability_demonhunter_eyebeam) # Eye Beam
	Texture(ability_demonhunter_throwglaive) # Throw Glaive
	Texture(ability_demonhunter_bladedance) # Blade Dance
	Texture(inv_glaive_1h_artifactaldrochi_d_02dual) # Death Sweep (Blade Dance)
	Texture(spell_fire_felfirenova) # Chaos Nova
	Texture(ability_demonhunter_consumemagic) # Consume Magic

	# Buffs
	Texture(ability_demonhunter_metamorphasisdps) # Metamorphosis
	
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
	
	# Artifact
	Texture(inv_glaive_1h_artifactazgalor_d_01) # Fury of the Illidari

	# Talents
	Texture(ability_demonhunter_felblade) # Felblade (T1)
	Texture(ability_bossfellord_felspike) # Fel Eruption (T5)
	Texture(ability_warlock_improveddemonictactics) # Nemesis (T5)
	Texture(inv_glaive_1h_artifactaldrochi_d_03dual) # Chaos Blades (T7)
	Texture(ability_felarakkoa_feldetonation_green) # Fel Barrage (T7)

	# Racials
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(ability_ambush) # Shadowmeld (Night elf)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("DEMONHUNTER", "havoc", name, desc, code, "script")
	end
end
