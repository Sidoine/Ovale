local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_priest_common"
	local desc = "[5.4.7] Ovale: Common priest functions"
	local code = [[
# Common functions and UI elements for default priest scripts.

Include(ovale_priest_spells)

###
### Common functions for all specializations.
###

AddFunction Interrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		Spell(silence)
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_mana)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}
]]

	OvaleScripts:RegisterScript("PRIEST", name, desc, code, "include")
end
