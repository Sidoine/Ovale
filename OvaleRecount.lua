local Recount = Recount
local RL = LibStub("AceLocale-3.0"):GetLocale("Recount")

local function DataModes(self,data, num)
	if not data then return 0, 0 end
	if num == 1 then
		return (data.Fights[Recount.db.profile.CurDataSet].Ovale or 0)
	end
	return (data.Fights[Recount.db.profile.CurDataSet].Ovale or 0), nil --{{}}
end

local function TooltipFuncs(self,name,data)
	local SortedData,total
	GameTooltip:ClearLines()
	GameTooltip:AddLine(name)
	-- Recount:AddSortedTooltipData(RL["Top 3"].." Ovale",data and data.Fights[Recount.db.profile.CurDataSet] and data.Fights[Recount.db.profile.CurDataSet].Ovale,3)
	-- GameTooltip:AddLine("<"..RL["Click for more Details"]..">",0,0.9,0)
end

if Recount then
	Recount:AddModeTooltip("Ovale",DataModes,TooltipFuncs,nil,nil,nil,nil)
end