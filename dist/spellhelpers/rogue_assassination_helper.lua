local __exports = LibStub:GetLibrary("ovale/scripts/ovale_rogue")
if not __exports then return end
__exports.registerRogueAssassinationHelper = function(OvaleScripts)
do
	local name = "ROGUESTABBY"
	local desc = "[Xel][8.x] Spellhelper: Stabby (Assassination)"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_rogue_shadowstrikes) # Mutilate
	Texture(ability_rogue_garrote) # Garrote
	Texture(ability_rogue_rupture) # Rupture
	Texture(ability_rogue_disembowel) # Envenom
	Texture(ability_rogue_fanofknives) # Fan of Knives
	Texture(ability_rogue_poisonedknife) # Poisoned Knife

	# Interrupts
	Texture(ability_kick) # Kick
	Texture(ability_rogue_kidneyshot) # Kidney Shot
	Texture(ability_cheapshot) # Cheap Shot
	Texture(spell_shadow_mindsteal) # Blind

	# Poisons
	Texture(spell_nature_corrosivebreath) # Deadly Poison
	Texture(ability_poisonsting) # Crippling Poison

	# Buffs
	Texture(ability_stealth) # Stealth
	Texture(ability_rogue_deadliness) # Vendetta
	Texture(ability_vanish) # Vanish
	Texture(ability_rogue_crimsonvial) # Crimson Vial
	Texture(ability_rogue_shadowstep) # Shadow Step

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
	Texture(ability_rogue_focusedattacks) # Blindside (T1)
	Texture(achievement_bg_killingblow_berserker) # Marked for Death (T3)
	Texture(rogue_leeching_poison) # Leeching Poison (T4)
	Texture(inv_weapon_shortblade_62) # Toxic Blade (T6)
	Texture(ability_deathwing_bloodcorruption_earth) # Exsanguinate (T6)
	Texture(inv_knife_1h_cataclysm_c_05) # Crimson Tempest (T7)

	# Racials
	Texture(racial_orc_berserkerstrength) # Blood Fury (Orc)
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(spell_shadow_raisedead) # Will of the Forsaken (Undead)
	Texture(inv_gizmo_rocketlauncher) # Rocket Barrage (Goblin)
	Texture(pandarenracial_quiveringpain) # Quaking Palm (Pandaren)
	Texture(spell_shadow_unholystrength) # Stoneform (Dwarf)
	Texture(spell_shadow_charm) # Every Man for Himself (Human)
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

		OvaleScripts:RegisterScript("ROGUE", "assassination", name, desc, code, "script")
	end
end
