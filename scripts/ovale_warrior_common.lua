local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_warrior_common"
	local desc = "[5.4.7] Ovale: Common warrior functions"
	local code = [[
# Common functions and UI elements for default warrior scripts.

Include(ovale_warrior_spells)

###
### Common functions for all specializations.
###

AddFunction Interrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(pummel) Spell(pummel)
		if Glyph(glyph_of_gag_order) and target.InRange(heroic_throw) Spell(heroic_throw)
		Spell(disrupting_shout)
	}
}

AddCheckBox(opt_heroic_leap_dps SpellName(heroic_leap) specialization=!protection)
AddFunction HeroicLeap
{
	if CheckBoxOn(opt_heroic_leap_dps) Spell(heroic_leap)
}

AddFunction RagingBlow
{
	if BuffPresent(raging_blow_buff) Spell(raging_blow)
}
]]

	OvaleScripts:RegisterScript("WARRIOR", name, desc, code, "include")
end
