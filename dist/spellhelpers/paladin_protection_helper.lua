local __exports = LibStub:GetLibrary("ovale/scripts/ovale_paladin")
if not __exports then return end
__exports.registerPaladinProtectionHelper = function(OvaleScripts)
do
	local name = "Prothelp"
	local desc = "[Xel][7.x] Spellhelper: Protection"
	local code = [[
AddIcon
{
	# Remove a line when you have its colour
	# Spells
	Texture(ability_paladin_shieldofvengeance) # Shield of the Righteous
	Texture(ability_paladin_hammeroftherighteous) # Hammer of the Righteous
	Texture(spell_holy_righteousfury) # Judgment
	Texture(spell_holy_innerfire) # Consecration
	Texture(spell_holy_avengersshield) # Avengers Shield
	Texture(spell_holy_rebuke) # Rebuke
	Texture(spell_holy_flashheal) # Flash of Light
	Texture(ability_paladin_lightoftheprotector) # Light of the Protector

	# Buffs
	Texture(spell_holy_heroism) # Guardian of Ancient Kings
	Texture(spell_holy_ardentdefender) # Ardent Defender
	Texture(spell_holy_divineshield) # Divine Shield
	Texture(spell_holy_sealofprotection) # Blessing of Protection
	Texture(spell_holy_avenginewrath) # Avenging Wrath
	Texture(spell_holy_sealofsacrifice) # Blessing of Sacrifice
	Texture(spell_holy_layonhands) # Lay on Hands

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
	Texture(paladin_retribution) # Blessed Hammer (T1)(Replaces Hammer of the Righteous)
	Texture(paladin_protection) # Bastion of Light (T2)
	Texture(spell_holy_prayerofhealing) # Repentance (T3)
	Texture(ability_paladin_blindinglight) # Blinding Light (T3)
	Texture(spell_holy_blessingofprotection) # Blessing of Spellwarding (T4)(Replaces Blessing of Protection)
	Texture(ability_paladin_blessedhands) # Hand of the Protector (T5)(Replaces Light of the Protector)
	Texture(spell_holy_greaterblessingoflight) # Aegis of Light (T6)
	Texture(ability_paladin_seraphim) # Seraphim (T7)

	# Racials
	Texture(spell_shadow_teleport) # Arcane Torrent (Blood Elf)
	Texture(ability_warstomp) # War Stomp (Tauren)
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

		OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
	end
end
