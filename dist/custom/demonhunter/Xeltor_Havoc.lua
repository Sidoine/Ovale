local __exports = LibStub:GetLibrary("ovale/scripts/ovale_demonhunter")
if not __exports then return end
__exports.registerDemonHunterHavocXeltor = function(OvaleScripts)
do
	local name = "xeltor_havoc"
	local desc = "[Xel][8.2] Demon Hunter: Havoc"
	local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_demonhunter_spells)

AddIcon specialization=1 help=main
{
	# if InCombat() InterruptActions()
	
	if target.InRange(chaos_strike) and HasFullControl()
	{
		# Cooldowns
		# if Boss() HavocCooldownCdActions()
		
		# Short Cooldowns
		# HavocDefaultShortCdActions()
		
		# Default Actions
		# HavocDefaultMainActions()
	}
	
	# if InCombat() and not target.InRange(chaos_strike) and Falling() and not BuffPresent(glide_buff) Spell(glide)
}


]]

		OvaleScripts:RegisterScript("DEMONHUNTER", "havoc", name, desc, code, "script")
	end
end