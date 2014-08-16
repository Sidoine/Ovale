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

AddCheckBox(opt_potions "Use potions" default)

AddFunction UsePotionIntellect
{
	if CheckBoxOn(opt_potions) and target.Classification(worldboss) Item(jade_serpent_potion usable=1)
}

AddFunction UseItemActions
{
	Item(HandSlot usable=1)
	Item(Trinket0Slot usable=1)
	Item(Trinket1Slot usable=1)
}

AddFunction UseRacialActions
{
	Spell(berserking)
	Spell(blood_fury_sp)
}

AddFunction Interrupt
{
	if target.IsFriend(no) and target.IsInterruptible() 
	{
		if target.Classification(worldboss no)
		{
			Spell(arcane_torrent_mana)
		}
	}
}

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
