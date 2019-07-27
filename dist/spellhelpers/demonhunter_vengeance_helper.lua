local __exports = LibStub:GetLibrary("ovale/scripts/ovale_demonhunter")
if not __exports then return end
__exports.registerDemonHunterVengeanceHelper = function(OvaleScripts)
do
	local name = "DMVENGEANCEhelper"
	local desc = "[Xel][8.x] Spellhelper: Vengeance"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_demonhunter_hatefulstrike) # Shear
	Texture(ability_demonhunter_soulcleave) # Soul Cleave
	Texture(ability_demonhunter_throwglaive) # Throw Glaive
	Texture(ability_demonhunter_immolation) # Immolation Aura
	Texture(ability_demonhunter_sigilofinquisition) # Sigil of Flame
	Texture(ability_demonhunter_infernalstrike1) # Infernal Strike
	
	# Interrupts
	Texture(ability_demonhunter_consumemagic) # Disrupt
	Texture(ability_demonhunter_sigilofsilence) # Sigil of Silence
	Texture(ability_demonhunter_sigilofmisery) # Sigil of Misery
	Texture(spell_fire_felflamering) # Imprison (wrong texture but it works)

	# Utils
	Texture(ability_demonhunter_metamorphasistank) # Metamorphosis
	Texture(ability_demonhunter_demonspikes) # Demon Spikes
	Texture(ability_demonhunter_fierybrand) # Fiery Brand
	Texture(spell_misc_zandalari_council_soulswap) # Consume Magic
	
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
	Texture(ability_demonhunter_felblade) # Felblade (T3)
	Texture(ability_creature_felsunder) # Fracture (T4)
	Texture(ability_demonhunter_sigilofchains) # Sigil of Chains (T5) (interrupt)
	Texture(inv_icon_shadowcouncilorb_purple) # Spirit Bomb (T6)
	Texture(ability_demonhunter_feldevastation) # Fel Devastation (T6)
	Texture(inv_glaive_1h_artifactaldrochi_d_05) # Soul Barrier (T7)

	# Racials
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(ability_ambush) # Shadowmeld (Night elf)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
	end
end