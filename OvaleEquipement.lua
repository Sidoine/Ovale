OvaleEquipement = LibStub("AceAddon-3.0"):NewAddon("OvaleEquipement", "AceEvent-3.0")

--<public-static-properties>
OvaleEquipement.nombre = {}
--</public-static-properties>

--<public-static-methods>

function OvaleEquipement:OnEnable()
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function OvaleEquipement:OnDisable()
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function OvaleEquipement:GetItemId(slot)
	local link = GetInventoryItemLink("player", GetInventorySlotInfo(slot))
	if not link then return nil end
	local a, b, itemId = string.find(link, "item:(%d+)");
	return tonumber(itemId);
end

local itemTier = 
{
	--Feral druid
	[60286] = "T11",
	[60288] = "T11",
	[60287] = "T11",
	[60289] = "T11",
	[60290] = "T11",
	[65189] = "T11",
	[65190] = "T11",
	[65191] = "T11",
	[65192] = "T11",
	[65193] = "T11",
	[78789] = "T13",
	[78779] = "T13",
	[78808] = "T13",
	[78760] = "T13",
	[78838] = "T13",
	[77015] = "T13",
	[77014] = "T13",
	[77016] = "T13",
	[77013] = "T13",
	[77017] = "T13",
	[78694] = "T13",
	[78684] = "T13",
	[78713] = "T13",
	[78665] = "T13",
	[78743] = "T13",
	--Balance druid
	[60284] = "T11",
	[60281] = "T11",
	[60283] = "T11",
	[60282] = "T11",
	[60285] = "T11",
	[65203] = "T11",
	[65202] = "T11",
	[65201] = "T11",
	[65200] = "T11",
	[65199] = "T11",
	-- Hunter
	[77028] = "T13",
	[77029] = "T13",
	[77030] = "T13",
	[77031] = "T13",
	[77032] = "T13",
	[78661] = "T13",
	[78674] = "T13",
	[78698] = "T13",
	[78709] = "T13",
	[78737] = "T13",
	[78756] = "T13",
	[78769] = "T13",
	[78793] = "T13",
	[78804] = "T13",
	[78832] = "T13",
	-- Mage
	[76212] = "T13",
	[76213] = "T13",
	[76214] = "T13",
	[76215] = "T13",
	[76216] = "T13",
	[78671] = "T13",
	[78701] = "T13",
	[78720] = "T13",
	[78729] = "T13",
	[78748] = "T13",
	[78766] = "T13",
	[78796] = "T13",
	[78815] = "T13",
	[78824] = "T13",
	[78843] = "T13",
	-- Retribution paladin
	[76874] = "T13",
	[76875] = "T13",
	[76876] = "T13",
	[76877] = "T13",
	[76878] = "T13",
	[78675] = "T13",
	[78693] = "T13",
	[78712] = "T13",
	[78727] = "T13",
	[78742] = "T13",
	[78770] = "T13",
	[78788] = "T13",
	[78807] = "T13",
	[78822] = "T13",
	[78837] = "T13",
	-- Rogue
	[71045] = "T12",
	[71046] = "T12",
	[71047] = "T12",
	[71048] = "T12",
	[71049] = "T12",
	[71537] = "T12",
	[71538] = "T12",
	[71539] = "T12",
	[71540] = "T12",
	[71541] = "T12",
	[77023] = "T13",
	[77024] = "T13",
	[77025] = "T13",
	[77026] = "T13",
	[77027] = "T13",
	[78664] = "T13",
	[78679] = "T13",
	[78699] = "T13",
	[78708] = "T13",
	[78738] = "T13",
	[78759] = "T13",
	[78774] = "T13",
	[78794] = "T13",
	[78803] = "T13",
	[78833] = "T13",
	-- Elemental shaman
	[71291] = "T12",
	[71292] = "T12",
	[71293] = "T12",
	[71294] = "T12",
	[71295] = "T12",
	[71552] = "T12",
	[71553] = "T12",
	[71554] = "T12",
	[71555] = "T12",
	[71556] = "T12",
	[77035] = "T13",
	[77036] = "T13",
	[77037] = "T13",
	[77038] = "T13",
	[77039] = "T13",
	[78666] = "T13",
	[78685] = "T13",
	[78711] = "T13",
	[78723] = "T13",
	[78741] = "T13",
	[78761] = "T13",
	[78780] = "T13",
	[78806] = "T13",
	[78818] = "T13",
	[78836] = "T13",
	-- Enhancement shaman
	[78819] = "T13",
	[77040] = "T13",
	[78724] = "T13",
	[78762] = "T13",
	[77041] = "T13",
	[78667] = "T13",
	[78781] = "T13",
	[77042] = "T13",
	[78686] = "T13",
	[78799] = "T13",
	[77043] = "T13",
	[78704] = "T13",
	[78828] = "T13",
	[77044] = "T13",
	[78733] = "T13",
	--Fury/Arm warrior
	[60323] = "T11",
	[60324] = "T11",
	[60325] = "T11",
	[60326] = "T11",
	[60327] = "T11",
	[65264] = "T11",
	[65265] = "T11",
	[65266] = "T11",
	[65267] = "T11",
	[65268] = "T11",
	[71070] = "T12",
	[71599] = "T12",
	[71068] = "T12",
	[71600] = "T12",
	[71072] = "T12",
	[71603] = "T12",
	[71071] = "T12",
	[71602] = "T12",
	[71069] = "T12",
	[71601] = "T12",
	[76983] = "T13",
	[76984] = "T13",
	[76985] = "T13",
	[76986] = "T13",
	[76987] = "T13",
	[78657] = "T13",
	[78668] = "T13",
	[78688] = "T13",
	[78706] = "T13",
	[78735] = "T13",
	[78752] = "T13",
	[78763] = "T13",
	[78783] = "T13",
	[78801] = "T13",
	[78830] = "T13",
	--Warlock
	[65263] = "T11",
	[65262] = "T11",
	[65261] = "T11",
	[65260] = "T11",
	[65259] = "T11",
	[65252] = "T11",
	[65251] = "T11",
	[65250] = "T11",
	[65249] = "T11",
	[65248] = "T11",
	[78776] = "T13",
	[76343] = "T13",
	[78681] = "T13",
	[78797] = "T13",
	[76342] = "T13",
	[78702] = "T13",
	[78816] = "T13",
	[76341] = "T13",
	[78721] = "T13",
	[78825] = "T13",
	[76340] = "T13",
	[78730] = "T13",
	[78844] = "T13",
	[76339] = "T13",
	[78749] = "T13",
}

local itemSlots = {"HeadSlot", "ShoulderSlot", "ChestSlot", "HandsSlot", "LegsSlot"}

function OvaleEquipement:Refresh()
	self.nombre = {}
	for i=1,#itemSlots do
		local itemId = self:GetItemId(itemSlots[i])
		if itemId then
			local tier = itemTier[itemId]
			if tier~=nil then
				if not self.nombre[tier] then
					self.nombre[tier] = 1
				else
					self.nombre[tier] = self.nombre[tier] + 1
				end
			end
		end
	end	
end

function OvaleEquipement:UNIT_INVENTORY_CHANGED(event, arg1)
	if (arg1 == "player") then
		self:Refresh()
	end
end

function OvaleEquipement:PLAYER_ENTERING_WORLD(event)
	self:Refresh()
end

--</public-static-methods>

