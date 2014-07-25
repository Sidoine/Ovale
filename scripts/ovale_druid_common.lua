local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_druid_common"
	local desc = "[5.4.7] Ovale: Common druid functions"
	local code = [[
# Common functions and UI elements for default druid scripts.

Include(ovale_druid_spells)

###
### Common functions for all specializations.
###

AddFunction FaerieFire
{
	if TalentPoints(faerie_swarm_talent) Spell(faerie_swarm)
	if not TalentPoints(faerie_swarm_talent) Spell(faerie_fire)
}

AddFunction SavageRoar
{
    if Glyph(glyph_of_savagery) Spell(savage_roar_glyphed)
    if Glyph(glyph_of_savagery no) and ComboPoints() >0 Spell(savage_roar)
}

###
### Interrupt actions for each specialization.
###

AddFunction BalanceInterrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.Classification(worldboss no)
		{
			if TalentPoints(typhoon_talent) Spell(typhoon)
			if TalentPoints(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
			Spell(solar_beam)
		}
	}
}

AddFunction FeralInterrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(skull_bash_cat) Spell(skull_bash_cat)
		if target.Classification(worldboss no)
		{
			if TalentPoints(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
			if TalentPoints(typhoon_talent) and target.InRange(skull_bash_cat) Spell(typhoon)
			if ComboPoints() > 0 and target.InRange(maim) Spell(maim)
		}
	}
}

AddFunction GuardianInterrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.InRange(skull_bash_bear) Spell(skull_bash_bear)
		if target.Classification(worldboss no)
		{
			if TalentPoints(typhoon_talent) and target.InRange(skull_bash_bear) Spell(typhoon)
			if TalentPoints(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
		}
	}
}

AddFunction RestorationInterrupt
{
	if target.IsFriend(no) and target.IsInterruptible()
	{
		if target.Classification(worldboss no)
		{
			if TalentPoints(typhoon_talent) Spell(typhoon)
			if TalentPoints(mighty_bash_talent) and target.InRange(mighty_bash) Spell(mighty_bash)
		}
	}
}
]]

	OvaleScripts:RegisterScript("DRUID", name, desc, code, "include")
end
