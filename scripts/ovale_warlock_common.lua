local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_warlock_common"
	local desc = "[5.4.7] Ovale: Common warlock functions"
	local code = [[
# Common functions and UI elements for default warlock scripts.

Include(ovale_warlock_spells)

###
### Common functions for all specializations.
###

AddFunction SummonPet
{
	if pet.Present(no) Texture(spell_nature_removecurse help=SummonPet)
}

AddFunction ServicePet
{
	if TalentPoints(grimoire_of_service_talent) and Spell(grimoire_of_service) Texture(spell_nature_removecurse help=ServicePet)
}
]]

	OvaleScripts:RegisterScript("WARLOCK", name, desc, code, "include")
end
