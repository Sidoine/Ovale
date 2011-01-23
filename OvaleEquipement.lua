OvaleEquipement = LibStub("AceAddon-3.0"):NewAddon("OvaleEquipement", "AceEvent-3.0")

OvaleEquipement.nombre = {}

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