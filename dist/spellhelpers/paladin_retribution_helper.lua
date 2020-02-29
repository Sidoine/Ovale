local __exports = LibStub:GetLibrary("ovale/scripts/ovale_paladin")
if not __exports then return end
__exports.registerPaladinRetributionHelper = function(OvaleScripts)
do
	local name = "Retrihelp"
	local desc = "[Xel][8.x] Spellhelper: Retribution"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(spell_holy_crusaderstrike) # Crusader Strike
	Texture(spell_holy_righteousfury) # Judgment
	Texture(ability_paladin_bladeofjustice) # Blade of Justice
	Texture(spell_paladin_templarsverdict) # Templar's Verdict
	Texture(ability_paladin_divinestorm) # Divine Storm
	Texture(spell_holy_rebuke) # Rebuke
	Texture(spell_holy_sealofmight) # Hammer of Justice

	# Buffs
	Texture(spell_magic_greaterblessingofkings) # Greater Blessing of Kings
	Texture(spell_holy_greaterblessingofwisdom) # Greater Blessing of Wisdom
	Texture(spell_holy_avenginewrath) # Avenging Wrath
	Texture(ability_paladin_shieldofthetemplar) # Shield of Vengeance

	# Utility
	Texture(spell_holy_layonhands) # Lay on Hands
	Texture(spell_holy_flashheal) # Flash of Light
	Texture(spell_holy_divineshield) # Divine Shield
	Texture(spell_holy_sealofprotection) # Blessing of Protection
	Texture(spell_holy_sealofvalor) # Blessing of Freedom
	Texture(ability_paladin_handofhindrance) # Hand of Hindrance
	Texture(ability_paladin_enlightenedjudgements) # Hammer of Reckoning

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
	Texture(spell_holy_sealofblood) # Zeal (T1)
	Texture(spell_paladin_executionsentence) # Execution Sentence (T1)
	Texture(spell_paladin_hammerofwrath) # Hammer of Wrath (T2)
	Texture(spell_holy_prayerofhealing) # Repentance (T3)
	Texture(ability_paladin_blindinglight) # Blinding Light (T3)
	Texture(spell_holy_innerfire) # Consecration (T4)
	Texture(inv_sword_2h_artifactashbringerfire_d_03) # Wake of Ashes (T4)
	Texture(spell_holy_weaponmastery) # Eye for an Eye (T5)
	Texture(spell_holy_retributionaura) # Justicar's Vengeance (T6)
	Texture(inv_helmet_96) # Word of Glory (T6)
	Texture(ability_paladin_sanctifiedwrath) # Crusade (T7) (Replaces Avenging Wrath)
	Texture(spell_paladin_inquisition) # Inquisition (T7)

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
	Texture(ability_racial_orbitalstrike) # Light's Judgment (Lightforged Draenei)











































}
]]

		OvaleScripts:RegisterScript("PALADIN", "retribution", name, desc, code, "script")
	end
end
