local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidGuardianHelper = function(OvaleScripts)
do
	local name = "Guardianhelp"
	local desc = "[Xel][7.0.3] Spellhelper: Guardian"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_druid_thrash) # Thrash
	Texture(ability_druid_mangle2) # Mangle
	Texture(ability_druid_maul) # Maul
	Texture(inv_misc_monsterclaw_03) # Swipe
	Texture(spell_nature_starfall) # Moonfire
	Texture(inv_bone_skull_04) # Skull Bash
	
	# Buffs
	Texture(ability_racial_bearform) # Bear Form
	Texture(spell_nature_stoneclawtotem) # Barkskin
	Texture(ability_druid_ironfur) # Ironfur
	Texture(ability_bullrush) # Frenzied Regeneration
	Texture(ability_druid_tigersroar) # Survival Instincts
	Texture(ability_druid_markofursol) # Mark of Ursol
	Texture(spell_nature_healingtouch) # Healing Touch
	
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
	Texture(spell_druid_bristlingfur) # Bristling Fur (T1)
	Texture(spell_druid_displacement) # Displacer Beast (T2)
	Texture(spell_druid_feralchargecat) # Wild Charge (Cat)(T2)
	Texture(ability_hunter_pet_bear) # Wild Charge (Bear)(T2)
	Texture(ability_druid_bash) # Mighty Bash (T4)
	Texture(spell_druid_massentanglement) # Mass Entanglement (T4)
	Texture(ability_druid_typhoon) # Typhoon (T4)
	Texture(spell_druid_incarnation) # Incarnation (T6)
	Texture(spell_nature_moonglow) # Lunar Beam (T7)
	Texture(spell_druid_malfurionstenacity) # Pulverize (T7)
	
	# Racials
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(ability_warstomp) # War Stomp (Tauren)
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
}
]]

		OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
	end
end