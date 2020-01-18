local __exports = LibStub:GetLibrary("ovale/scripts/ovale_warlock")
if not __exports then return end
__exports.registerWarlockAfflictionHelper = function(OvaleScripts)
do
	local name = "WLKAFFLICTIONhelp"
	local desc = "[Xel][8.x] Spellhelper: Affliction"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_shadow_shadowbolt) # Shadow Bolt
	Texture(spell_shadow_curseofsargeras) # Agony
	Texture(spell_shadow_abominationexplosion) # Corruption
	Texture(spell_shadow_unstableaffliction_3) # Unstable Affliction
	Texture(spell_shadow_lifedrain02) # Drain Life
	Texture(spell_shadow_seedofdestruction) # Seed of Corruption
	Texture(inv_beholderwarlock) # Summon Darkglare
	Texture(spell_shadow_mindrot) # Spel Lock (Felhunter)
	Texture(spell_shadow_painandsuffering) # Shadow Lock (Doomguard)

	# Survival stuff
	Texture(ability_deathwing_bloodcorruption_death) # Health Funnel
	Texture(inv_misc_gem_bloodstone_01) # Create Healthstone
	Texture(inv_stone_04) # Healthstone
	Texture(spell_shadow_demonictactics) # Unending Resolve

	# Buffs
	Texture(spell_shadow_demonbreath) # Unending Breath

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
	Texture(spell_shadow_haunting) # Drain Soul (T1) (replaces Shadow Bolt)
	Texture(spell_fire_twilightflamebolt) # Deathbolt (T1)
	Texture(spell_shadow_requiem) # Siphon Life (T2)
	Texture(inv_enchant_voidsphere) # Phantom Singularity (T4)
	Texture(sha_spell_shadow_shadesofdarkness_nightborne) # Vile Taint (T4)
	Texture(ability_warlock_mortalcoil) # Mortal Coil (T5)
	Texture(ability_warlock_haunt) # Haunt (T6)
	Texture(warlock_grimoireofsacrifice) # Grimoire of Sacrifice (T6)
	Texture(spell_warlock_soulburn) # Dark Soul: Misery (T7)

	# Racials
	Texture(racial_orc_berserkerstrength) # Blood Fury (Orc)
	Texture(racial_troll_berserk) # Berserking (Troll)
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(spell_shadow_raisedead) # Will of the Forsaken (Undead)
	Texture(inv_gizmo_rocketlauncher) # Rocket Barrage (Goblin)
	Texture(spell_shadow_unholystrength) # Stoneform (Dwarf)
	Texture(spell_shadow_charm) # Every Man for Himself (Human)
	Texture(ability_racial_darkflight) # Darkflight (Worgen)
	Texture(ability_rogue_trip) # Escape Artist (Gnome)
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

		OvaleScripts:RegisterScript("WARLOCK", "affliction", name, desc, code, "script")
	end
end
