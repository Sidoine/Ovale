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
		if (Ovale.db.profile.left~=this:GetLeft() or Ovale.db.profile.top ~=this:GetTop()) then
			Ovale.db.profile.left = this:GetLeft()
			Ovale.db.profile.top = this:GetTop()
		else
			if (this.obj.content:IsShown()) then
				this.obj.content:Hide()
			else
				this.obj.content:Show()
			end
		end
	end
	
	local function frameOnEnter(this)
		--for i,child in ipairs(this.obj.children) do
		--	child.frame:Show()
		--end
	--	this.obj.content:Show()
	end
	
	
	local function frameOnLeave(this)
		--for i,child in ipairs(this.obj.children) do
		--	child.frame:Hide()
		--end
		--this.obj.content:Hide()
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
	
	local function OnLayoutFinished(self, width, height)
		-- self.content:SetWidth(width)
		-- self.content:SetHeight(height)
		if (not width) then
			width = self.content:GetWidth()
		end
		self.content:SetWidth(width)
		self.content:SetHeight(height+50)
	end
	
	local function UpdateIcons(self)
		for k, icon in pairs(self.icone) do
			icon:Hide()
		end
		
		for k,node in pairs(Ovale.masterNodes) do
			if (not self.icone[k]) then
				self.icone[k] = CreateFrame("Frame",nil,self.frame,"OvaleIcone");
			end
			self.icone[k].masterNode = node
			self.icone[k]:SetPoint("TOPLEFT",self.frame,"TOPLEFT",Ovale.db.profile.apparence.iconWidth*(k-1),0)
			self.icone[k]:SetWidth(Ovale.db.profile.apparence.iconWidth)
			self.icone[k]:SetHeight(Ovale.db.profile.apparence.iconHeight)
			self.icone[k]:Show();
		end
		
		self.frame:SetWidth(#Ovale.masterNodes * Ovale.db.profile.apparence.iconWidth)
		self.frame:SetHeight(Ovale.db.profile.apparence.iconHeight)
		self.content:SetPoint("TOPLEFT",self.frame,"TOPLEFT",#Ovale.masterNodes * Ovale.db.profile.apparence.iconWidth,0)
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		
		-- self.optionsVisible = false
		
		self.type = "Frame"
		
		self.Hide = Hide
		self.Show = Show
		self.SetTitle =  SetTitle
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetStatusText = SetStatusText
		self.SetStatusTable = SetStatusTable
		self.ApplyStatus = ApplyStatus
	--	self.OnWidthSet = OnWidthSet
	--	self.OnHeightSet = OnHeightSet
		self.LayoutFinished = OnLayoutFinished
		self.UpdateIcons = UpdateIcons
		
		self.localstatus = {}
		self.icone = {}
		
		self.frame = frame
		frame.obj = self
		frame:SetWidth(100)
		frame:SetHeight(100)
		frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
		frame:EnableMouse()
		frame:SetMovable(true)
		--frame:SetResizable(true)
		frame:SetFrameStrata("BACKGROUND")
		frame:SetScript("OnMouseDown", frameOnMouseDown)
		-- title:SetScript("OnMouseDown",titleOnMouseDown)
		frame:SetScript("OnMouseUp", frameOnMouseUp)
		frame:SetScript("OnEnter", frameOnEnter)
		frame:SetScript("OnLeave", frameOnLeave)
		
		frame:SetScript("OnHide",frameOnClose)
		
		--Container Support
		local content = CreateFrame("Frame",nil,frame)
		self.content = content
		content.obj = self
		content.test = "test"
		content:SetWidth(200)
		content:SetHeight(100)
		--content:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
		-- content:EnableMouse()
		content:Hide()
		
		AceGUI:RegisterAsContainer(self)

		return self	
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

