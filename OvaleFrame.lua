local AceGUI = LibStub("AceGUI-3.0")

----------------
-- Main Frame --
----------------
--[[
	Events :
		OnClose

]]
do
	local Type = "OvaleFrame"
	local Version = 7

	local FrameBackdrop = {
		bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
		tile = true, tileSize = 32, edgeSize = 32, 
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	}

	local function frameOnClose(this)
		this.obj:Fire("OnClose")
	end
	
	local function closeOnClick(this)
		this.obj:Hide()
	end
	
	local function frameOnMouseDown(this)
		this:StartMoving()
		AceGUI:ClearFocus()
	end
	
	local function titleOnMouseDown(this)
		AceGUI:ClearFocus()
	end
	
	local function frameOnMouseUp(this)
		this:StopMovingOrSizing()
		Ovale.db.profile.left = this:GetLeft()
		Ovale.db.profile.top = this:GetTop()
	end
	
	local function titleOnMouseUp(this)
		--[[ local frame = this:GetParent()
		frame:StopMovingOrSizing()
		local self = frame.obj
		local status = self.status or self.localstatus
		status.width = frame:GetWidth()
		status.height = frame:GetHeight()
		status.top = frame:GetTop()
		status.left = frame:GetLeft() ]]--
	end
	
	local function sizerseOnMouseDown(this)
		this:GetParent():StartSizing("BOTTOMRIGHT")
		AceGUI:ClearFocus()
	end
	
	local function sizersOnMouseDown(this)
		this:GetParent():StartSizing("BOTTOM")
		AceGUI:ClearFocus()
	end
	
	local function sizereOnMouseDown(this)
		this:GetParent():StartSizing("RIGHT")
		AceGUI:ClearFocus()
	end
	
	local function sizerOnMouseUp(this)
		this:GetParent():StopMovingOrSizing()
	end

	local function SetTitle(self,title)
		self.titletext:SetText(title)
	end
	
	local function SetStatusText(self,text)
		self.statustext:SetText(text)
	end
	
	local function Hide(self)
		self.frame:Hide()
	end
	
	local function Show(self)
		self.frame:Show()
	end
	
	local function OnAcquire(self)
		self.frame:SetParent(UIParent)
		self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
		self:ApplyStatus()
	end
	
	local function OnRelease(self)
		self.status = nil
		for k in pairs(self.localstatus) do
			self.localstatus[k] = nil
		end
	end
	
	-- called to set an external table to store status in
	local function SetStatusTable(self, status)
		assert(type(status) == "table")
		self.status = status
		self:ApplyStatus()
	end
	
	local function ApplyStatus(self)
		local status = self.status or self.localstatus
		local frame = self.frame
		self:SetWidth(status.width or 700)
		self:SetHeight(status.height or 500)
		if status.top and status.left then
			frame:SetPoint("TOP",UIParent,"BOTTOM",0,status.top)
			frame:SetPoint("LEFT",UIParent,"LEFT",status.left,0)
		else
			frame:SetPoint("CENTER",UIParent,"CENTER")
		end
	end
	
	local function OnWidthSet(self, width)
		local content = self.content
		local contentwidth = width - 34
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end
	
	
	local function OnHeightSet(self, height)
		local content = self.content
		local contentheight = height - 57
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = "Frame"
		
		self.Hide = Hide
		self.Show = Show
		self.SetTitle =  SetTitle
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetStatusText = SetStatusText
		self.SetStatusTable = SetStatusTable
		self.ApplyStatus = ApplyStatus
		self.OnWidthSet = OnWidthSet
		self.OnHeightSet = OnHeightSet
		
		self.localstatus = {}
		
		self.frame = frame
		frame.obj = self
		frame:SetWidth(100)
		frame:SetHeight(100)
		frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
		frame:EnableMouse()
		frame:SetMovable(true)
		frame:SetResizable(true)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame:SetScript("OnMouseDown", frameOnMouseDown)
		-- title:SetScript("OnMouseDown",titleOnMouseDown)
		frame:SetScript("OnMouseUp", frameOnMouseUp)
		
		--[[frame:SetBackdrop(FrameBackdrop)
		frame:SetBackdropColor(0,0,0,1)]]--
		frame:SetScript("OnHide",frameOnClose)
		frame:SetMinResize(400,200)
		frame:SetToplevel(true)

		self.icone = CreateFrame("Frame",nil,frame,"OvaleIcone");
		self.icone:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		self.icone:SetWidth(64)
		self.icone:SetHeight(64)
		self.icone:Show();
		
		--Container Support
		local content = CreateFrame("Frame",nil,frame)
		self.content = content
		content.obj = self
		content:SetPoint("TOPLEFT",frame,"TOPLEFT",64,0)
		content:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
		
		AceGUI:RegisterAsContainer(self)

		return self	
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end



--[[
function OvaleFrame_OnLoad(self)
	self.icone = CreateFrame("Frame",nil,self,"OvaleIcone");
	self.icone:SetAllPoints(self)
	self.icone:Show();
	
	--self.cases = {}
	--local case = CreateFrame("Button", "OvaleCheck", self)
	--case:SetPoint("TOPLEFT", 0, 0)
	--self.cases[#self.cases] = case
	self.checkBoxes = {}
	
	self.dropDowns = {};
	local tf = LibStub("AceGUI-3.0"):Create("Frame")
	tf:SetWidth(200)
	tf:SetHeight(200)
	local tl = LibStub("AceGUI-3.0"):Create("Label")
		tl:SetText("Anfangstext")
	local ti = LibStub("AceGUI-3.0"):Create("Icon")
		ti:SetHeight(50)
		ti:SetWidth(50)
		
	tf:AddChild(tl)
	tf:AddChild(ti)
end

function OvaleFrame_Update(self)
	for v,k in pairs(self.checkBoxes) do
		k:Hide()
	end
	
	for v,k in pairs(Ovale.casesACocher) do
		if (not self.checkBoxes[v]) then
			self.checkBoxes[v] = OvaleFrame_CreateCheckBox(self, v)
		end
		self.checkBoxes[v]:Show()
		self.checkBoxes[v].text:SetText(k)
	end
	
end


-- Idem. Liste déroulante





function OvaleFrame_OnUpdate(self)

end
function OvaleFrame_OnMouseDown(self,button)
	if ( button == "LeftButton") then
		self:StartMoving();
	end
end

function OvaleFrame_OnMouseUp(self, button)
	if ( button == "LeftButton" ) then	
		self:StopMovingOrSizing();
	end
end
]]--