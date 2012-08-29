
Ovale = LibStub("AceAddon-3.0"):NewAddon("Ovale", "AceEvent-3.0", "AceConsole-3.0")

--<private-static-properties>
local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")
local Recount = Recount
local Skada = Skada
--</private-static-properties>

--<public-static-properties>
--Default scripts (see "defaut" directory)
Ovale.defaut = {}
--The table of check boxes definition
Ovale.casesACocher = {}
--allows to do some initialization the first time the addon is enabled
Ovale.firstInit = false
--the frame with the icons
Ovale.frame = nil
--check boxes GUI items
Ovale.checkBoxes = {}
--drop down GUI items
Ovale.dropDowns = {}
--master nodes of the current script (one node for each icon)
Ovale.masterNodes = nil
--set it if there was a bug, traces will be enabled on next frame
Ovale.bug = false
Ovale.traced = false
--trace next script function calls
Ovale.trace=false
--in combat?
Ovale.enCombat = false
--score in current combat
Ovale.score = 0
--maximal theoric score in current combat
Ovale.maxScore = 0
Ovale.refreshNeeded = {}
Ovale.compileOnItems = false
Ovale.combatStartTime = nil
Ovale.needCompile = false
Ovale.listes = {}
--</public-static-properties>

--Key bindings
BINDING_HEADER_OVALE = "Ovale"
BINDING_NAME_OVALE_CHECKBOX0 = L["Inverser la boîte à cocher "].."(1)"
BINDING_NAME_OVALE_CHECKBOX1 = L["Inverser la boîte à cocher "].."(2)"
BINDING_NAME_OVALE_CHECKBOX2 = L["Inverser la boîte à cocher "].."(3)"
BINDING_NAME_OVALE_CHECKBOX3 = L["Inverser la boîte à cocher "].."(4)"
BINDING_NAME_OVALE_CHECKBOX4 = L["Inverser la boîte à cocher "].."(5)"

--<public-static-methods>
function Ovale:Debug()
	self:Print(OvaleCompile:DebugNode(self.masterNodes[1]))
end

function Ovale:DebugListAura(target, filter)
	local i = 1
	while true do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId =  UnitAura(target, i, filter)
		if not name then
			break
		end
		Ovale:Print(name..": "..spellId)
		i = i + 1
	end
end

function Ovale:CompileAll()
	if OvaleOptions:GetProfile().code then
		self.masterNodes = OvaleCompile:Compile(OvaleOptions:GetProfile().code)
		self.refreshNeeded.player = true
		self:UpdateFrame()
		self.needCompile = false
	end
end


function Ovale:FirstInit()
	self.firstInit = true

	OvaleData:FirstInit()
	
	self.frame = LibStub("AceGUI-3.0"):Create("OvaleFrame")

	local profile = OvaleOptions:GetProfile()
	
	self.frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", profile.left, profile.top)
	self:UpdateFrame()
	if not profile.display then
		self.frame:Hide()
	end
end

function Ovale:OnEnable()
	if not self.firstInit then
		self:FirstInit()
	end

    -- Called when the addon is enabled
	RegisterAddonMessagePrefix("Ovale")
    self:RegisterEvent("PLAYER_REGEN_ENABLED");
    self:RegisterEvent("PLAYER_REGEN_DISABLED");
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("GLYPH_UPDATED")
	self:RegisterEvent("GLYPH_ADDED")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED")

	self:UpdateVisibility()
end

function Ovale:OnDisable()
    -- Called when the addon is disabled
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    self:UnregisterEvent("PLAYER_REGEN_DISABLED")
    self:UnregisterEvent("PLAYER_TARGET_CHANGED")
    self:UnregisterEvent("CHAT_MSG_ADDON")
    self:UnregisterEvent("GLYPH_UPDATED")	
    self:UnregisterEvent("GLYPH_ADDED")
	self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
    self.frame:Hide()
end

function Ovale:UNIT_INVENTORY_CHANGED()
	if self.compileOnItems then
		self.needCompile = true
	else
		self.refreshNeeded.player = true
	end
end

--Called when the player target change
--Used to update the visibility e.g. if the user chose
--to hide Ovale if a friendly unit is targeted
function Ovale:PLAYER_TARGET_CHANGED()
	self.refreshNeeded.target = true
	self:UpdateVisibility()
end

--Called when a glyph has been added
--The script needs to be compiled
function Ovale:GLYPH_ADDED(event)
	self.needCompile = true
end

--Called when a glyph has been updated
--The script needs to be compiled
function Ovale:GLYPH_UPDATED(event)
	self.needCompile = true
end

function Ovale:CHAT_MSG_ADDON(event, prefix, msg, type, author)
	if prefix ~= "Ovale" then return end
	if type ~= "RAID" and type~= "PARTY" then return end

	local value, maxValue, guid = strsplit(";", msg)
	self:SendScoreToDamageMeter(author, guid, value, maxValue)
end

function Ovale:PLAYER_REGEN_ENABLED()
	self.enCombat = false
	self:UpdateVisibility()
	-- if self.maxScore and self.maxScore > 0 then
	-- 	self:Print((self.score/self.maxScore*100).."%")
	-- end
end

function Ovale:PLAYER_REGEN_DISABLED()
	if self.maxScore>0 then
		SendAddonMessage("Ovale", self.score..";"..self.maxScore..";"..UnitGUID("player"), "RAID")
	end
	self.enCombat = true
	self.score = 0
	self.maxScore = 0
	self.combatStartTime = OvaleState.maintenant
	self:UpdateVisibility()
end

function Ovale:SendScoreToDamageMeter(name, guid, scored, scoreMax)
	if Recount then
		local source = Recount.db2.combatants[name]
		if source then
			Recount:AddAmount(source,"Ovale",scored)
			Recount:AddAmount(source,"OvaleMax",scoreMax)
		end
	end
	if Skada then
		if not guid or not Skada.current or not Skada.total then return end
		local player = Skada:get_player(Skada.current, guid, nil)
		if not player then return end
		if not player.ovale then player.ovale = 0 end
		if not player.ovaleMax then player.ovaleMax = 0 end
		player.ovale = player.ovale + scored
		player.ovaleMax = player.ovaleMax + scoreMax
		player = Skada:get_player(Skada.total, guid, nil)
		player.ovale = player.ovale + scored
		player.ovaleMax = player.ovaleMax + scoreMax
	end
end

function Ovale:Log(text)
	if self.trace then
		self:Print(text)
	end
end

local function OnCheckBoxValueChanged(widget)
	OvaleOptions:GetProfile().check[widget.userdata.k] = widget:GetValue()
	if Ovale.casesACocher[widget.userdata.k].compile then
		Ovale.needCompile = true
	end
end

local function OnDropDownValueChanged(widget)
	OvaleOptions:GetProfile().list[widget.userdata.k] = widget.value
	if Ovale.listes[widget.userdata.k].compile then
		Ovale.needCompile = true
	end
end

function Ovale:ToggleOptions()
	self.frame:ToggleOptions()
end

function Ovale:UpdateVisibility()
	if not OvaleOptions:GetProfile().display then
		self.frame:Hide()
		return
	end

	self.frame:Show()

	if OvaleOptions:GetApparence().hideVehicule and UnitInVehicle("player") then
		self.frame:Hide()
	end
	
	if OvaleOptions:GetApparence().avecCible and not UnitExists("target") then
		self.frame:Hide()
	end
	
	if OvaleOptions:GetApparence().enCombat and not Ovale.enCombat then
		self.frame:Hide()
	end	
	
	if OvaleOptions:GetApparence().targetHostileOnly and (UnitIsDead("target") or not UnitCanAttack("player", "target")) then
		self.frame:Hide()
	end
end

function Ovale:UpdateFrame()
	self.frame:ReleaseChildren()

	self.frame:UpdateIcons()
	
	self:UpdateVisibility()
	
	self.checkBoxes = {}
	
	local profile = OvaleOptions:GetProfile()
	
	for k,checkBox in pairs(self.casesACocher) do
		self.checkBoxes[k] = LibStub("AceGUI-3.0"):Create("CheckBox");
		self.frame:AddChild(self.checkBoxes[k])
		self.checkBoxes[k]:SetLabel(checkBox.text)
		if profile.check[k]==nil then
			profile.check[k] = checkBox.checked
		end
		if (profile.check[k]) then
			self.checkBoxes[k]:SetValue(profile.check[k]);
		end
		self.checkBoxes[k].userdata.k = k
		self.checkBoxes[k]:SetCallback("OnValueChanged",OnCheckBoxValueChanged)
	end
	
	self.dropDowns = {}
	
	if (self.listes) then
		for k,list in pairs(self.listes) do
			self.dropDowns[k] = LibStub("AceGUI-3.0"):Create("Dropdown");
			self.dropDowns[k]:SetList(list.items)
			if not profile.list[k] then
				profile.list[k] = list.default
			end
			if (profile.list[k]) then
				self.dropDowns[k]:SetValue(profile.list[k]);
			end
			self.dropDowns[k].userdata.k = k
			self.dropDowns[k]:SetCallback("OnValueChanged",OnDropDownValueChanged)
			self.frame:AddChild(self.dropDowns[k])
		end
	end
end

function Ovale:IsChecked(v)
	return self.checkBoxes[v] and self.checkBoxes[v]:GetValue()
end

function Ovale:GetListValue(v)
	return self.dropDowns[v] and self.dropDowns[v].value
end

function Ovale:SetCheckBox(v,on)
	for k,checkBox in pairs(self.casesACocher) do
		if v==0 then
			self.checkBoxes[k]:SetValue(on)
			OvaleOptions:GetProfile().check[k] = on
			break
		end
		v = v - 1
	end
end

function Ovale:ToggleCheckBox(v)
	for k,checkBox in pairs(self.casesACocher) do
		if v==0 then
			self.checkBoxes[k]:SetValue(not self.checkBoxes[k]:GetValue())
			OvaleOptions:GetProfile().check[k] = self.checkBoxes[k]:GetValue()
			break
		end
		v = v - 1
	end
end

function Ovale:Error(text)
	self:Print("Fatal error: " .. text)
	self.bug = true
end
--</public-static-methods>
