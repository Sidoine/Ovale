local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_shaman_common"
	local desc = "[5.4.7] Ovale: Common shaman functions"
	local code = [[
# Common functions and UI elements for default shaman scripts.

Include(ovale_shaman_spells)

###
### Common functions for all specializations.
###

AddFunction UseRacialActions
{
	Spell(berserking)
	Spell(blood_fury_apsp)
}

AddFunction Bloodlust
{
	if DebuffExpires(burst_haste_debuff any=1)
	{
		Spell(bloodlust)
		Spell(heroism)
	}
}

AddFunction Interrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		Spell(wind_shear)
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}
]]

	OvaleScripts:RegisterScript("SHAMAN", name, desc, code, "include")
end
