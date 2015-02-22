local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "nerien_shaman_restoration"
	local desc = "[6.0] Nerien: Restoration"
	local code = [[
###
### Nerien's restoration shaman script.
###

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_shaman_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=restoration)

AddFunction RestorationInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		Spell(wind_shear)
		if not target.Classification(worldboss)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			Spell(war_stomp)
		}
	}
}

AddFunction RestorationMainActions
{
	if BuffExpires(water_shield_buff) Spell(water_shield)
	if BuffCountOnAny(earth_shield_buff) == 0 Spell(earth_shield)

	# If using Glyph of Totemic Recall, assume that the player wants to use Totemic Recall
	# to regain mana by recalling Healing Stream Totem.
	#
	# Totemic Recall is suggested at 3s remaining on HST so that there is still time to cast
	# it after the current spellcast and GCD.  Take care not to recall other totems that have
	# long cooldowns.
	#
	if Glyph(glyph_of_totemic_recall) and TotemPresent(water totem=healing_stream_totem) and TotemExpires(water 3) and TotemExpires(fire) and TotemExpires(earth) and TotemExpires(air) Spell(totemic_recall)

	if Talent(elemental_blast_talent) and BuffRemaining(elemental_blast_spirit_buff) < CastTime(elemental_blast) Spell(elemental_blast)
	if BuffPresent(unleash_life_buff) Spell(healing_wave)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(healing_stream_totem)
	if Glyph(glyph_of_riptide no) Spell(riptide)
}

AddFunction RestorationAoeActions
{
	if BuffExpires(water_shield_buff) Spell(water_shield)
	if BuffCountOnAny(earth_shield_buff) == 0 Spell(earth_shield)

	if Talent(elemental_blast_talent) and BuffRemaining(elemental_blast_spirit_buff) < CastTime(elemental_blast) Spell(elemental_blast)
	if BuffPresent(unleash_life_buff) Spell(chain_heal)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(healing_stream_totem)
	Spell(healing_rain)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(cloudburst_totem)
	Spell(chain_heal)
}

AddFunction RestorationShortCdActions
{
	if Talent(primal_elementalist_talent) and pet.Present()
	{
		if TotemPresent(fire_elemental_totem) and BuffExpires(fire_elemental_totem_empower_buff any=1) Spell(fire_elemental_totem_empower)
		if TotemPresent(earth totem=earth_elemental_totem) and BuffExpires(earth_elemental_totem_reinforce_buff any=1) Spell(earth_elemental_totem_reinforce)
	}
	Spell(unleash_life)
}

AddFunction RestorationCdActions
{
	if IsFeared() Spell(tremor_totem)
	RestorationInterruptActions()
	if Speed(more 0) Spell(spiritwalkers_grace)
	Spell(blood_fury_apsp)
	Spell(berserking)
	if ManaPercent() < 90 Spell(arcane_torrent_mana)
	if Talent(totemic_persistence_talent) or TotemExpires(water) Spell(healing_tide_totem)
	Spell(ancestral_guidance)
	Spell(ascendance_heal)
	Spell(fire_elemental_totem)
	Spell(earth_elemental_totem)
}

### Restoration icons.

AddCheckBox(opt_shaman_restoration_aoe L(AOE) default specialization=restoration)

AddIcon help=shortcd specialization=restoration
{
	RestorationShortCdActions()
}

AddIcon help=main specialization=restoration
{
	RestorationMainActions()
}

AddIcon checkbox=opt_shaman_restoration_aoe help=aoe specialization=restoration
{
	RestorationAoeActions()
}

AddIcon help=cd specialization=restoration
{
	RestorationCdActions()
}
]]
	OvaleScripts:RegisterScript("SHAMAN", "restoration", name, desc, code, "script")
end
