local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_deathknight_common"
	local desc = "[5.4.7] Ovale: Common death knight functions"
	local code = [[
# Common functions and UI elements for default death knight scripts.

Include(ovale_deathknight_spells)

###
### Common functions for all specializations.
###

AddFunction Interrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(mind_freeze) Spell(mind_freeze)
		if target.Classification(worldboss no)
		{
			if TalentPoints(asphyxiate_talent) and target.InRange(asphyxiate) Spell(asphyxiate)
			if target.InRange(strangulate) Spell(strangulate)
		}
	}
}

AddFunction BloodTap
{
	# Blood Tap requires a minimum of five stacks of Blood Charge to be on the player.
	if TalentPoints(blood_tap_talent) and BuffStacks(blood_charge_buff) >= 5 Spell(blood_tap)
}

AddFunction PlagueLeech
{
	# Plague Leech requires both Blood Plague and Frost Fever to exist on the target.
	if TalentPoints(plague_leech_talent) and target.DebuffPresent(blood_plague_debuff) and target.DebuffPresent(frost_fever_debuff) Spell(plague_leech)
}

]]
	OvaleScripts:RegisterScript("DEATHKNIGHT", name, desc, code, "include")
end
