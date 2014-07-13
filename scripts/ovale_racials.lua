local _, Ovale = ...
local OvaleScripts = Ovale.OvaleScripts

do
	local name = "ovale_racials"
	local desc = "[5.4.7] Ovale: Racial spells"
	local code = [[
# Racials
Define(arcane_torrent_chi 129597)
	SpellInfo(arcane_torrent_chi cd=120 chi=1)
Define(arcane_torrent_energy 25046)
	SpellInfo(arcane_torrent_energy cd=120 energy=-15)
Define(arcane_torrent_focus 80483)
	SpellInfo(arcane_torrent_focus cd=120 focus=-15)
Define(arcane_torrent_mana 28730)
	SpellInfo(arcane_torrent_mana cd=120)
Define(arcane_torrent_rage 69179)
	SpellInfo(arcane_torrent_rage cd=120 rage=-15)
Define(arcane_torrent_runicpower 50613)
	SpellInfo(arcane_torrent_runicpower cd=120 runicpower=-15)
Define(berserking 26297)
	SpellInfo(berserking cd=180)
	SpellAddBuff(berserking berserking_buff=1)
Define(berserking_buff 26297)
	SpellInfo(berserking_buff duration=10)
Define(blood_fury 20572)
	SpellInfo(blood_fury cd=120)
	SpellAddBuff(blood_fury blood_fury_buff=1)
Define(blood_fury_buff 20572)
	SpellInfo(blood_fury_buff duration=15)
Define(quaking_palm 107079)
	SpellInfo(quaking_palm cd=120)
Define(stoneform 20594)
	SpellInfo(stoneform cd=120)
	SpellAddBuff(stoneform stoneform_buff=1)
Define(stoneform_buff 20594)
	SpellInfo(stoneform_buff duration=8)
]]

	OvaleScripts:RegisterScript(nil, name, desc, code, "include")
end
