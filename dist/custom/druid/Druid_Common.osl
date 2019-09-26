local __exports = LibStub:GetLibrary("ovale/scripts/ovale_druid")
if not __exports then return end
__exports.registerDruidCommonXeltor = function(OvaleScripts)
do
	local name = "druid_common_functions"
	local desc = "Druid: Common Functions"
	local code = [[
AddFunction SaveActions
{
	# if HealthPercent() <= 50 and ManaPercent() > 20 and { not InCombat() or target.istargetingplayer() } and not target.IsFriend() Spell(swiftmend)
	# if HealthPercent() <= 50 and ManaPercent() > 20 and { not InCombat() or target.istargetingplayer() } and not target.IsFriend() and not BuffPresent(rejuvenation_buff) Spell(rejuvenation)
	if { Speed() == 0 or CanMove() > 0 } and HealthPercent() <= 50 and ManaPercent() > 20 and { not InCombat() or target.istargetingplayer() } and not target.IsFriend() Spell(regrowth)
}

AddFunction MoveActions
{
	if not InCombat() and not Mounted() and not BuffPresent(travel_form) and not BuffPresent(dash) and Speed() > 0 and not InDoors() Spell(travel_form)
	if not InCombat() and not Mounted() and not BuffPresent(cat_form) and Speed() > 0 and InDoors() Spell(cat_form)
}

]]

		OvaleScripts:RegisterScript("DRUID", nil, name, desc, code, "include")
	end
end