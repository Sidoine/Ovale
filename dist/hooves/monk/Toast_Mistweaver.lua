local __exports = LibStub:GetLibrary("ovale/scripts/ovale_monk")
if not __exports then return end
__exports.registerMonkMistweaverToast = function(OvaleScripts)
do
	local name = "toast_mistweaver"
	local desc = "[Toast][8.3] Monk: Mistweaver"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_monk_spells)
Define(ring_of_peace 116844)
Define(leg_sweep 119381)
# Brewmaster
AddIcon specialization=2 help=main
{
	if not Mounted()
	{
		if target.InRange(tiger_palm) and HasFullControl()
		{
			MistweaverDefaultMainActions()
		}
	}
}
### actions.default
AddFunction MistweaverDefaultMainActions
{
    Spell(rising_sun_kick)
    if BuffStacks(teachings_of_the_monastery_buff) < 3 Spell(tiger_palm)
    if BuffStacks(teachings_of_the_monastery_buff) > 2 Spell(blackout_kick_windwalker)
}
]]

		OvaleScripts:RegisterScript("MONK", "mistweaver", name, desc, code, "script")
	end
end
