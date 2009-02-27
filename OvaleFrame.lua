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
		if (not Ovale.db.profile.apparence.verrouille) then
			this:StartMoving()
			AceGUI:ClearFocus()
		end
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
	
	local function Hide(self)
		self.frame:Hide()
	end
	
	local function Show(self)
		self.frame:Show()
	end
	
	local function OnAcquire(self)
		self.frame:SetParent(UIParent)
	end
	
	local function OnRelease(self)
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
		
		local left = 0
		local maxHeight = 0
		local maxWidth = 0
		local top = 0
		
		if (not Ovale.masterNodes) then
			return;
		end
		
		for k,node in pairs(Ovale.masterNodes) do
			if (not self.icone[k]) then
				self.icone[k] = CreateFrame("Frame",nil,self.frame,"OvaleIcone");
			end
			self.icone[k].masterNode = node
			local width, height
			if (node.params.size == "small") then
				width = Ovale.db.profile.apparence.smallIconWidth
				height = Ovale.db.profile.apparence.smallIconHeight
			else
				width = Ovale.db.profile.apparence.iconWidth
				height = Ovale.db.profile.apparence.iconHeight
			end
			if (top + height > Ovale.db.profile.apparence.iconHeight) then
				top = 0
				left = maxWidth
			end
			if (Ovale.db.profile.apparence.vertical) then
				self.icone[k]:SetPoint("TOPLEFT",self.frame,"TOPLEFT",top,-left)
			else
				self.icone[k]:SetPoint("TOPLEFT",self.frame,"TOPLEFT",left,-top)
			end
			self.icone[k]:SetWidth(width)
			self.icone[k]:SetHeight(height)
			self.icone[k]:Show();
			top = top + height
			if (top> maxHeight) then
				maxHeight = top
			end
			if (left + width > maxWidth) then
				maxWidth = left + width
			end
		end
		if (Ovale.db.profile.apparence.vertical) then
			self.frame:SetWidth(maxHeight)
			self.frame:SetHeight(maxWidth)
			self.content:SetPoint("TOPLEFT",self.frame,"TOPLEFT",maxHeight,0)
		else
			self.frame:SetWidth(maxWidth)
			self.frame:SetHeight(maxHeight)
			self.content:SetPoint("TOPLEFT",self.frame,"TOPLEFT",maxWidth,0)
		end
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		
		-- self.optionsVisible = false
		
		self.type = "Frame"
		
		self.Hide = Hide
		self.Show = Show
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.ApplyStatus = ApplyStatus
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

