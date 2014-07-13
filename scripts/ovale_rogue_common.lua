local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_rogue_common"
	local desc = "[5.4.7] Ovale: Common rogue functions"
	local code = [[
# Common functions and UI elements for default rogue scripts.

Include(ovale_rogue_spells)

###
### Common functions for all specializations.
###

AddFunction ApplyPoisons
{
	if InCombat(no)
	{
		if BuffExpires(lethal_poison_buff 600) Spell(deadly_poison)
		if BuffExpires(non_lethal_poison_buff 600)
		{
			if TalentPoints(leeching_poison_talent) Spell(leeching_poison)
			Spell(mind_numbing_poison)
		}
	}
	if BuffExpires(lethal_poison_buff) Spell(deadly_poison)
}

AddFunction IsStealthed
{
	Stealthed() or BuffPresent(vanish_buff) or BuffPresent(shadow_dance_buff)
}

AddCheckBox(opt_tricks_of_the_trade SpellName(tricks_of_the_trade) default)
AddFunction TricksOfTheTrade
{
	#tricks_of_the_trade
	if CheckBoxOn(opt_tricks_of_the_trade) and Glyph(glyph_of_tricks_of_the_trade no) Spell(tricks_of_the_trade)
}

AddFunction Interrupt
{
	if not target.IsFriend() and target.IsInterruptible()
	{
		if IsStealthed() and target.InRange(cheap_shot) Spell(cheap_shot)
		if target.InRange(kick) Spell(kick)
		if not target.Classification(worldboss) and target.InRange(kidney_shot) Spell(kidney_shot)
	}
}
]]

	OvaleScripts:RegisterScript("ROGUE", name, desc, code, "include")
end
