local AceGUI = LibStub("AceGUI-3.0")
local LBF = LibStub("LibButtonFacade", true)
		
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
	
	local function ToggleOptions(this)
		if (this.content:IsShown()) then
			this.content:Hide()
		else
			this.content:Show()
		end
	end
	
	local function frameOnMouseUp(this)
		this:StopMovingOrSizing()
		
		if (Ovale.db.profile.left~=this:GetLeft() or Ovale.db.profile.top ~=this:GetTop()) then
			Ovale.db.profile.left = this:GetLeft()
			Ovale.db.profile.top = this:GetTop()
	--	else
	--		this.obj:ToggleOptions()
		end
	end
	
	local function frameOnEnter(this)
		--for i,child in ipairs(this.obj.children) do
		--	child.frame:Show()
		--end
	--	this.obj.content:Show()
		if (not Ovale.db.profile.apparence.verrouille) then
			this.obj.barre:Show()
		end
	end
	
	
	local function frameOnLeave(this)
		--for i,child in ipairs(this.obj.children) do
		--	child.frame:Hide()
		--end
		--this.obj.content:Hide()
		this.obj.barre:Hide()
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
	
	local function OnSkinChanged(self, skinID, gloss, backdrop, colors)
		-- for k, icon in pairs(self.icone) do
		--	icon:UpdateSkin(skinID, gloss, backdrop, colors)
		-- end
		Ovale.db.profile.SkinID = skinID
		Ovale.db.profile.Gloss = gloss
		Ovale.db.profile.Backdrop = backdrop
		Ovale.db.profile.Colors = colors
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
		
		local BARRE = 8
		
		local margin =  Ovale.db.profile.apparence.margin
			
		for k,node in pairs(Ovale.masterNodes) do
			if (not self.icone[k]) then
				-- self.icone[k] = CreateFrame("Frame", "Icon"..k,self.frame,"OvaleIcone");
				self.icone[k] = CreateFrame("CheckButton", "Icon"..k,self.frame,"OvaleIcone");
			end
			-- self.icone[k]:SetFrameLevel(1)
			self.icone[k].masterNode = node
			local width, height
			if (node.params.size == "small") then
				width = Ovale.db.profile.apparence.smallIconWidth + margin
				height = Ovale.db.profile.apparence.smallIconHeight + margin
			else
				width = Ovale.db.profile.apparence.iconWidth + margin
				height = Ovale.db.profile.apparence.iconHeight + margin
			end
			if (top + height > Ovale.db.profile.apparence.iconHeight + margin) then
				top = 0
				left = maxWidth
			end
			if (Ovale.db.profile.apparence.vertical) then
				self.icone[k]:SetPoint("TOPLEFT",self.frame,"TOPLEFT",top,-left-BARRE-margin)
			else
				self.icone[k]:SetPoint("TOPLEFT",self.frame,"TOPLEFT",left,-top-BARRE-margin)
			end
			self.icone[k]:SetWidth(width - margin)
			self.icone[k]:SetHeight(height - margin)
			if (not LBF) then
				self.icone[k].normalTexture:SetWidth((width - margin)*66/36)
				self.icone[k].normalTexture:SetHeight((height - margin)*66/36)
				self.icone[k].shortcut:SetWidth(width-margin)
				self.icone[k].remains:SetWidth(width-margin)
			end
			if LBF then
				self.icone[k]:SetSkinGroup(self.skinGroup)
			end
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
			self.barre:SetWidth(maxHeight - margin)
			self.barre:SetHeight(BARRE)
			self.frame:SetWidth(maxHeight)
			self.frame:SetHeight(maxWidth+BARRE+margin)
			self.content:SetPoint("TOPLEFT",self.frame,"TOPLEFT",maxHeight,0)
		else
			self.barre:SetWidth(maxWidth - margin)
			self.barre:SetHeight(BARRE)
			self.frame:SetWidth(maxWidth)
			self.frame:SetHeight(maxHeight+BARRE+margin)
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
		self.OnSkinChanged = OnSkinChanged
		self.ToggleOptions = ToggleOptions
		
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
		
		self.barre = self.frame:CreateTexture();
		self.barre:SetTexture(0,0.8,0)
		self.barre:SetPoint("TOPLEFT",0,0)
		self.barre:Hide()
			
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

		if LBF then
			self.skinGroup = LBF:Group("Ovale")
			self.skinGroup.SkinID = Ovale.db.profile.SkinID
			self.skinGroup.Gloss = Ovale.db.profile.Gloss
			self.skinGroup.Backdrop = Ovale.db.profile.Backdrop
			self.skinGroup.Colors = Ovale.db.profile.Colors
			LBF:RegisterSkinCallback("Ovale", self.OnSkinChanged, self)
		end

		return self	
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

