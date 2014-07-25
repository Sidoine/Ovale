local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_monk_common"
	local desc = "[5.4.7] Ovale: Common monk functions"
	local code = [[
# Common functions and UI elements for default monk scripts.

Include(ovale_monk_spells)

###
### Common functions for all specializations.
###

AddFunction UseRacialActions
{
	Spell(berserking)
	Spell(blood_fury_apsp)
}

AddFunction Interrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(spear_hand_strike) Spell(spear_hand_strike)
		if target.Classification(worldboss no)
		{
			if target.InRange(paralysis) Spell(paralysis)
			Spell(arcane_torrent_chi)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}
]]

	OvaleScripts:RegisterScript("MONK", name, desc, code, "include")
end
