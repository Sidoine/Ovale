local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidBalanceHelper = function(OvaleScripts)
do
	local name = "Balancehelper"
	local desc = "[Xel][8.x] Spellhelper: Balance"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_nature_wrathv2) # Solar Wrath
	Texture(spell_arcane_starfire) # Lunar Strike
	Texture(ability_mage_firestarter) # Sunfire
	Texture(spell_nature_starfall) # Moonfire
	Texture(spell_arcane_arcane03) # Starsurge
	Texture(ability_druid_starfall) # Starfall
	Texture(ability_vehicle_sonicshockwave) # Solar Beam
	
	# Buffs
	Texture(spell_nature_forceofnature) # Moonkin Form
	Texture(ability_druid_travelform) # Travel Form
	Texture(ability_druid_catform) # Cat Form
	Texture(spell_nature_natureguardian) # Celestial Alignment
	Texture(ability_druid_dash) # Dash
	Texture(ability_druid_prowl) # Prowl
	Texture(spell_nature_resistnature) # Regrowth
	Texture(spell_nature_rejuvenation) # Rejuvenation
	Texture(inv_relics_idolofrejuvenation) # Swiftmend
	
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
	Texture(ability_essence_reapingflames) # Reaping Flames
	Texture(ability_essence_momentofglory) # Moment of Glory
	Texture(ability_essence_replicaofknowledge) # Replica of Knowledge
	
	# Talents
	Texture(spell_holy_elunesgrace) # Warrior of Elune (T1)
	Texture(ability_druid_forceofnature) # Force of Nature (T1)
	Texture(ability_druid_dash_orange) # Tiger Dash (T2)
	Texture(spell_nature_natureblessing) # Renewal (T2)
	Texture(spell_druid_wildcharge) # Wild Charge (T2)
	Texture(ability_druid_bash) # Mighty Bash (T4)
	Texture(spell_druid_massentanglement) # Mass Entanglement (T4)
	Texture(ability_druid_typhoon) # Typhoon (T4)
	Texture(spell_druid_incarnation) # Incarnation (T5)
	Texture(ability_druid_stellarflare) # Stellar Flare (T6)
	Texture(ability_druid_dreamstate) # Fury of Elune (T7)
	Texture(artifactability_balancedruid_newmoon) # New Moon (T7)
	Texture(artifactability_balancedruid_halfmoon) # Half Moon (T7)
	Texture(artifactability_balancedruid_fullmoon) # Full Moon (T7)
	
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

		OvaleScripts:RegisterScript("DRUID", "balance", name, desc, code, "script")
	end
end
