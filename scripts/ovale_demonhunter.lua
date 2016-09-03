local OVALE, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "icyveins_demonhunter_vengeance"
	local desc = "[7.0] Icy-Veins: DemonHunter Vengeance"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=vengeance)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=vengeance)

AddFunction VengeanceDefaultShortCDActions
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(shear) Texture(misc_arrowlup help=L(not_in_melee_range))
	if Pain() >= 20 Spell(demon_spikes)
}

AddFunction VengeanceDefaultMainActions
{
	Spell(soul_carver)
	if (Pain() > 75 or (HealthPercent() < 50 and Pain() >= 30)) Spell(soul_cleave)
	Spell(immolation_aura)
	Spell(felblade)
	Spell(fel_eruption)
	Spell(sigil_of_flame)
	Spell(shear)
}

AddFunction VengeanceDefaultAoEActions
{
	Spell(soul_carver)
	if (Pain() > 75 or (HealthPercent() < 50 and Pain() >= 30)) Spell(soul_cleave)
	Spell(immolation_aura)
	Spell(felblade)
	if Talent(burning_alive_talent) Spell(fiery_brand)
	Spell(sigil_of_flame)
	Spell(fel_eruption)
	Spell(shear)
}

AddFunction VengeanceDefaultCdActions
{
	VengeanceInterruptActions()
	Spell(metamorphosis_veng)
	Spell(fiery_brand)
}

AddFunction VengeanceInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(consume_magic) Spell(consume_magic)
		if not target.Classification(worldboss) Spell(arcane_torrent_dh)
	}
}

AddIcon help=shortcd specialization=vengeance
{
	VengeanceDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=vengeance
{
	VengeanceDefaultMainActions()
}

AddIcon help=aoe specialization=vengeance
{
	VengeanceDefaultAoEActions()
}

AddIcon help=cd specialization=vengeance
{
	#if not InCombat() VengeancePrecombatCdActions()
	VengeanceDefaultCdActions()
}
	]]
	OvaleScripts:RegisterScript("DEMONHUNTER", "vengeance", name, desc, code, "script")
end

do
	local name = "icyveins_demonhunter_havoc"
	local desc = "[7.0] Icy-Veins: DemonHunter Havoc"
	local code = [[

Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=havoc)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=havoc)

AddFunction HavocDefaultShortCDActions
{
	if CheckBoxOn(opt_melee_range) and not target.InRange(chaos_strike) {
		if Charges(fel_rush)>=1 Spell(fel_rush)
		Spell(throw_glaive)
		Texture(misc_arrowlup help=L(not_in_melee_range))
	}
	if Charges(fel_rush)==2 Spell(fel_rush)
}

AddFunction HavocDefaultMainActions
{
	if Talent(prepared_talent) and target.InRange(chaos_strike) Spell(vengeful_retreat)
	if Talent(fel_mastery_talent) and Fury() <= 70 Spell(fel_rush)
	if Fury() > 70 Spell(chaos_strike)
	if not Talent(demon_blades_talent) Spell(demons_bite)
	Spell(throw_glaive)
}

AddFunction HavocDefaultAoEActions
{
	if Enemies() > 3 and Talent(fel_mastery_talent) and Fury() <= 70 Spell(fel_rush)
	if Talent(prepared_talent) and target.InRange(chaos_strike) Spell(vengeful_retreat)
	Spell(eye_beam)
	if Talent(chaos_cleave_talent) and Enemies() <= 3 Spell(chaos_strike)
	if Enemies() >= 3 Spell(blade_dance)
	if Talent(fel_mastery_talent) and Fury() <= 70 Spell(fel_rush)
	if ((Talent(demon_blades_talent) and Fury() > 60) or Fury() > 70) Spell(chaos_strike)
	if not Talent(demon_blades_talent) Spell(demons_bite)
	Spell(throw_glaive)
}

AddFunction HavocDefaultCdActions
{
	HavocInterruptActions()
	Spell(metamorphosis_havoc)
}


AddFunction HavocInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(consume_magic) Spell(consume_magic)
		if not target.Classification(worldboss) Spell(arcane_torrent_dh)
	}
}
	
AddIcon help=shortcd specialization=havoc
{
	HavocDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=havoc
{
	HavocDefaultMainActions()
}

AddIcon help=aoe specialization=havoc
{
	HavocDefaultAoEActions()
}

AddIcon help=cd specialization=havoc
{
	#if not InCombat() VengeancePrecombatCdActions()
	HavocDefaultCdActions()
}

	]]
	OvaleScripts:RegisterScript("DEMONHUNTER", "havoc", name, desc, code, "script")
end