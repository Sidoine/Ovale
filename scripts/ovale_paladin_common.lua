local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_paladin_common"
	local desc = "[5.4.7] Ovale: Common paladin functions"
	local code = [[
# Common functions and UI elements for default paladin scripts.

Include(ovale_paladin_spells)

###
### Common functions for all specializations.
###

AddFunction Interrupt
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(rebuke) Spell(rebuke)
		if target.Classification(worldboss no)
		{
			if TalentPoints(fist_of_justice_talent) Spell(fist_of_justice)
			if not TalentPoints(fist_of_justice_talent) and target.InRange(hammer_of_justice) Spell(hammer_of_justice)
			#Spell(blinding_light)
		}
	}
}

AddFunction RaidBuffActions
{
	#blessing_of_kings,if=(!aura.str_agi_int.up)&(aura.mastery.up)
	if BuffExpires(str_agi_int any=1) and BuffPresent(mastery any=1) and BuffExpires(mastery) Spell(blessing_of_kings)
	#blessing_of_might,if=!aura.mastery.up
	if BuffExpires(mastery any=1) Spell(blessing_of_might)
}
]]

	OvaleScripts:RegisterScript("PALADIN", name, desc, code, "include")
end
