local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_hunter_common"
	local desc = "[5.4.7] Ovale: Common hunter functions"
	local code = [[
# Common functions and UI elements for default hunter scripts.

Include(ovale_hunter_spells)

###
### Common functions for all specializations.
###

AddFunction UseRacialActions
{
	Spell(berserking)
	Spell(blood_fury_ap)
}

AddFunction Interrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		Spell(silencing_shot)
		Spell(counter_shot)
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_focus)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

AddFunction SummonPet
{
	if pet.Present(no) Texture(ability_hunter_beastcall help=SummonPet)
	if pet.IsDead() Spell(revive_pet)
}

AddFunction KillCommand
{
	# Only suggest Kill Command if the pet can attack.
	if pet.Present() and pet.IsIncapacitated(no) and pet.IsFeared(no) and pet.IsStunned(no) Spell(kill_command)
}
]]

	OvaleScripts:RegisterScript("HUNTER", name, desc, code, "include")
end
