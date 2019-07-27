local __exports = LibStub:GetLibrary("ovale/scripts/ovale_monk")
if not __exports then return end
__exports.registerMonkMistweaverXeltor = function(OvaleScripts)
do
	local name = "xeltor_mistweaver"
	local desc = "[Xel][7.3] Monk: Mistweaver"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)

#Define(leg_sweep 119381)

# Mistweaver
AddIcon specialization=2 help=main
{
	if InCombat() InterruptActions()
	
	if target.InRange(effuse) and target.IsFriend() and HasFullControl()
    {
		MistweaverDefaultCdActions()
		
		MistweaverDefaultShortCdActions()
		
		MistweaverDefaultMainActions()
    }
	
	if target.InRange(tiger_palm) and not target.IsFriend() and HasFullControl()
	{
		MistweaverDefaultShortCdPunchActions()
		
		MistweaverDefaultMainPunchActions()
	}
}
AddCheckBox(group "Group")

AddFunction InterruptActions
{
	if not target.IsFriend() and target.IsInterruptible() and { target.MustBeInterrupted() or Level() < 100 or target.IsPVP() }
	{
		if not target.Classification(worldboss)
		{
			if target.InRange(paralysis) Spell(paralysis)
			if target.InRange(spear_hand_strike) Spell(arcane_torrent_chi)
			if target.InRange(quaking_palm) Spell(quaking_palm)
			if target.InRange(spear_hand_strike) Spell(leg_sweep)
			if target.InRange(spear_hand_strike) Spell(war_stomp)
		}
	}
}

### actions.default

AddFunction MistweaverDefaultMainActions
{
	#keep up for healing boost, on targets we actively heal.
	if Speed() == 0 and target.HealthPercent() < 99 and target.BuffRemaining(enveloping_mist_buff) < CastTime(enveloping_mist) + GCD() Spell(enveloping_mist)
	if Speed() > 0 and target.HealthPercent() <= 60 and BuffPresent(thunder_focus_tea_buff) and target.BuffRemaining(enveloping_mist_buff) < CastTime(enveloping_mist) + GCD() Spell(enveloping_mist)
	#keep up on anything that even has a scratch.
    if not target.BuffPresent(renewing_mist_buff) and target.HealthPercent() < 99 and not BuffPresent(thunder_focus_tea_buff) Spell(renewing_mist)
	#Use when harder healing is needed or group healing is on.
	if CheckBoxOn(group) and target.HealthPercent() <= 75 and not BuffPresent(uplifting_trance_buff) Spell(essence_font)
	if Speed() == 0 and { target.HealthPercent() <= 60 or CheckBoxOn(group) and target.HealthPercent() < 90 } Spell(vivify)
	#backstop filler heal.
	if target.HealthPercent() < 90 and Speed() == 0 Spell(sheiluns_gift)
	if Speed() == 0 and target.HealthPercent() < 90 Spell(effuse)
}

AddFunction MistweaverDefaultShortCdActions
{
	if target.HealthPercent() <= 65 and Speed() == 0 Spell(chi_burst)
	if target.HealthPercent() <= 65 Spell(zen_pulse)
	if target.HealthPercent() <= 90 Spell(chi_wave)
	if target.HealthPercent() <= 60 and not BuffPresent(thunder_focus_tea_buff) and target.BuffRemaining(enveloping_mist_buff) > CastTime(vivify) * { Talent(focused_thunder_talent) + 1 } Spell(thunder_focus_tea)
}

AddFunction MistweaverDefaultCdActions
{
    if target.HealthPercent() <= 35 Spell(life_cocoon)
}

AddFunction MistweaverDefaultShortCdPunchActions
{
	if HealthPercent() <= 90 and Speed() == 0 Spell(chi_burst)
	if HealthPercent() <= 90 Spell(zen_pulse)
	if HealthPercent() <= 90 Spell(chi_wave)
}

AddFunction MistweaverDefaultMainPunchActions
{
	if BuffExpires(renewing_mist_buff) and InCombat() Spell(renewing_mist)
	if Talent(rising_thunder_talent) and SpellCooldown(thunder_focus_tea) > GCD() and not BuffPresent(thunder_focus_tea_buff) or not Talent(rising_thunder_talent) Spell(rising_sun_kick)
	if BuffStacks(teachings_of_the_monastery_buff) >= 3 Spell(blackout_kick)
	Spell(tiger_palm)
}
]]

		OvaleScripts:RegisterScript("MONK", "mistweaver", name, desc, code, "script")
	end
end