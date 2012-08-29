--inherits Frame
do
--<private-static-properties>
	local AceGUI = LibStub("AceGUI-3.0")
	local Masque = LibStub("Masque", true)
	local GetTime = GetTime		

	local Type = "OvaleFrame"
	local Version = 7
--</private-static-properties>

--<public-methods>
	local function frameOnClose(self)
		self.obj:Fire("OnClose")
	end
	
	local function closeOnClick(self)
		self.obj:Hide()
	end
	
	local function frameOnMouseDown(self)
		if (not OvaleOptions:GetApparence().verrouille) then
			self:StartMoving()
			AceGUI:ClearFocus()
		end
	end
	
	local function ToggleOptions(self)
		if (self.content:IsShown()) then
			self.content:Hide()
		else
			self.content:Show()
		end
	end
	
	local function frameOnMouseUp(self)
		self:StopMovingOrSizing()
		local profile = OvaleOptions:GetProfile()
		
		if (profile.left~=self:GetLeft() or profile.top ~=self:GetTop()) then
			profile.left = self:GetLeft()
			profile.top = self:GetTop()
		end
	end
	
	local function frameOnEnter(self)
		if (not OvaleOptions:GetApparence().verrouille) then
			self.obj.barre:Show()
        end
	end
	
	local function frameOnLeave(self)
		self.obj.barre:Hide()

	end
	
	local function frameOnUpdate(self)
		self.obj:OnUpdate()
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
		if (not width) then
			width = self.content:GetWidth()
		end
		self.content:SetWidth(width)
		self.content:SetHeight(height+50)
	end
		
	local function GetScore(self, spellId)
		for k,action in pairs(self.actions) do
			if action.spellId == spellId then
				if not action.waitStart then
					-- print("sort "..spellId.." parfait")
					return 1
				else
					local lag = OvaleState.maintenant - action.waitStart
					if lag>5 then
					-- 	print("sort "..spellId.." ignoré (>5s)")
						return nil
					elseif lag>1.5 then
					-- 	print("sort "..spellId.." trop lent !")
						return 0
					elseif lag>0 then
					-- 	print("sort "..spellId.." un peu lent "..lag)
						return 1-lag/1.5
					else
					-- 	print("sort "..spellId.." juste bon")
						return 1
					end
				end
			end
		end
--		print("sort "..spellId.." incorrect")
		return 0
	end
	
	local function OnUpdate(self)
		if not OvaleData.listeTalentsRemplie then
			OvaleData:RemplirListeTalents()
		end
		if Ovale.needCompile then
			Ovale:CompileAll()
			return
		end
		
		local now = GetTime()
		local forceRefresh = not self.lastUpdate or (now > self.lastUpdate + OvaleOptions:GetApparence().updateInterval)
		
		if not next(Ovale.refreshNeeded) and not forceRefresh then
			return
		end
		if not Ovale.masterNodes then return end
		
		self.lastUpdate = now

		OvaleState:StartNewFrame()
		for k,node in pairs(Ovale.masterNodes) do
			local target = node.params.target or "target"
			OvaleCondition.defaultTarget = target
			
			if forceRefresh or Ovale.refreshNeeded[target] or Ovale.refreshNeeded["player"] or Ovale.refreshNeeded["pet"] then
				if Ovale.trace then
					Ovale:Print("****Master Node "..k)
				end
				OvaleBestAction:StartNewAction()
				local start, ending, priorite, element = OvaleBestAction:Compute(node)
				if start then
					Ovale:Log("Compute start = "..start)
				end
				local action = self.actions[k]
				local icons
				if action.secure then
					icons = action.secureIcons
				else
					icons = action.icons
				end
				if element and element.type == "value" then
					local actionTexture
					if node.params.texture then
						actionTexture = GetSpellTexture(node.params.texture)
					end
					local value
					if element.value and element.origin and element.rate then
						value = element.value + (OvaleState.maintenant - element.origin) * element.rate
					end
					icons[1]:SetValue(value, actionTexture)
					if #icons > 1 then
						icons[2]:Update(element, nil)
					end
				else
					local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
							actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId, actionTarget, noRed = OvaleBestAction:GetActionInfo(element)
					if noRed then
						start = actionCooldownStart + actionCooldownDuration
						if start < OvaleState.currentTime then
							start = OvaleState.currentTime
						end
					end
					
					-- Dans le cas de canStopChannelling, on risque de demander d'interrompre le channelling courant, ce qui est stupide
					if start and OvaleState.currentSpellId and OvaleState.attenteFinCast and spellId == OvaleState.currentSpellId and start<OvaleState.attenteFinCast then
						start = OvaleState.attenteFinCast
					end
					
					if (node.params.nocd and start~=nil and OvaleState.maintenant<start-node.params.nocd) then
						icons[1]:Update(element, nil)
					else
						icons[1]:Update(element, start, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
							actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId, actionTarget)
					end
					
					action.spellId = spellId
					
					if start == OvaleState.maintenant and actionUsable then
						if not action.waitStart then
							action.waitStart = OvaleState.maintenant
						end
					else
						action.waitStart = nil
					end
					
					if OvaleOptions:GetApparence().moving and icons[1].debutAction and icons[1].finAction then
						local top=1-(OvaleState.maintenant - icons[1].debutAction)/(icons[1].finAction-icons[1].debutAction)
						if top<0 then
							top = 0
						elseif top>1 then
							top = 1
						end
						icons[1]:SetPoint("TOPLEFT",self.frame,"TOPLEFT",(action.left + top*action.dx)/action.scale,(action.top - top*action.dy)/action.scale)
						if icons[2] then
							icons[2]:SetPoint("TOPLEFT",self.frame,"TOPLEFT",(action.left + (top+1)*action.dx)/action.scale,(action.top - (top+1)*action.dy)/action.scale)
						end
					end
									
					if (node.params.size ~= "small" and not node.params.nocd and OvaleOptions:GetApparence().predictif) then
						if start then
							local castTime=0
							if spellId then
								local _, _, _, _, _, _, _castTime = GetSpellInfo(spellId)
								if _castTime and _castTime>0 then
									castTime = _castTime/1000
								end
							end
							local gcd = OvaleData:GetGCD(spellId)
							local nextCast
							if (castTime>gcd) then
								nextCast = start + castTime 
							else
								nextCast = start + gcd
							end					
							if Ovale.trace then
								Ovale:Print("****Second icon " .. start)
							end
							local spellTarget = element.params.target
							if spellTarget == "target" or not spellTarget then
								spellTarget = target
							end
							OvaleState:AddSpellToStack(spellId, start, start + castTime, nextCast, false, UnitGUID(spellTarget))
							start, ending, priorite, element = OvaleBestAction:Compute(node)
							icons[2]:Update(element, start, OvaleBestAction:GetActionInfo(element))
						else
							icons[2]:Update(element, nil)
						end
					end
				end
			end
		end

		Ovale.refreshNeeded = {}
		
		if (not Ovale.bug) then
			Ovale.traced = false
		end
		
		if (Ovale.trace) then
			Ovale.trace=false
			Ovale.traced = true
		end
		
		if (Ovale.bug and not Ovale.traced) then
			Ovale.trace = true
		end	
	end
	
	local function UpdateIcons(self)
		for k, action in pairs(self.actions) do
			for i, icon in pairs(action.icons) do
				icon:Hide()
			end
			for i, icon in pairs(action.secureIcons) do
				icon:Hide()
			end
		end
		
		self.frame:EnableMouse(not OvaleOptions:GetApparence().clickThru)
		
		local left = 0
		local maxHeight = 0
		local maxWidth = 0
		local top = 0
		
		if (not Ovale.masterNodes) then
			return;
		end
		
		local BARRE = 8
		
		local margin =  OvaleOptions:GetApparence().margin
			
		for k,node in pairs(Ovale.masterNodes) do
			if not self.actions[k] then
				self.actions[k] = {icons={}, secureIcons={}}
			end
			local action = self.actions[k]

			local width, height, newScale
			local nbIcons
			if (node.params.size == "small") then
				newScale = OvaleOptions:GetApparence().smallIconScale
				width = newScale * 36 + margin
				height = newScale * 36 + margin
				nbIcons = 1
			else
				newScale = OvaleOptions:GetApparence().iconScale
				width =newScale * 36 + margin
				height = newScale * 36 + margin
				if OvaleOptions:GetApparence().predictif and node.params.type ~= "value" then
					nbIcons = 2
				else
					nbIcons = 1
				end
			end
			if (top + height > OvaleOptions:GetApparence().iconScale * 36 + margin) then
				top = 0
				left = maxWidth
			end
			
			action.scale = newScale
			if (OvaleOptions:GetApparence().vertical) then
				action.left = top
				action.top = -left-BARRE-margin
				action.dx = width
				action.dy = 0
			else
				action.left = left
				action.top = -top-BARRE-margin
				action.dx = 0
				action.dy = height
			end
			action.secure = node.secure
					
			for l=1,nbIcons do
				local icon
				if not node.secure then
					if not action.icons[l] then
						action.icons[l] = CreateFrame("CheckButton", "Icon"..k.."n"..l,self.frame,"OvaleIconTemplate");
					end			
					icon = action.icons[l]
				else
					if not action.secureIcons[l] then
						action.secureIcons[l] = CreateFrame("CheckButton", "SecureIcon"..k.."n"..l,self.frame,"SecureOvaleIconTemplate");
					end			
					icon = action.secureIcons[l]
				end
				local scale = action.scale
				if l> 1 then
					scale = scale  * OvaleOptions:GetApparence().secondIconScale
				end
				icon:SetPoint("TOPLEFT",self.frame,"TOPLEFT",(action.left + (l-1)*action.dx)/scale,(action.top - (l-1)*action.dy)/scale)
				icon:SetScale(scale)
				icon:SetFontScale(OvaleOptions:GetApparence().fontScale)
				icon:SetParams(node.params)
				icon:SetHelp(node.params.help)
				icon:SetRangeIndicator(OvaleOptions:GetApparence().targetText)
				icon:EnableMouse(not OvaleOptions:GetApparence().clickThru)
				icon.cdShown = (l == 1)
				if Masque then
					self.skinGroup:AddButton(icon)
				end
				if l==1 then
					icon:Show();
				end
			end
			
			top = top + height
			if (top> maxHeight) then
				maxHeight = top
			end
			if (left + width > maxWidth) then
				maxWidth = left + width
			end
		end
		
		if (OvaleOptions:GetApparence().vertical) then
			self.barre:SetWidth(maxHeight - margin)
			self.barre:SetHeight(BARRE)
			self.frame:SetWidth(maxHeight + OvaleOptions:GetApparence().iconShiftY)
			self.frame:SetHeight(maxWidth+BARRE+margin + OvaleOptions:GetApparence().iconShiftX)
			self.content:SetPoint("TOPLEFT",self.frame,"TOPLEFT",maxHeight + OvaleOptions:GetApparence().iconShiftX,OvaleOptions:GetApparence().iconShiftY)
		else
			self.barre:SetWidth(maxWidth - margin)
			self.barre:SetHeight(BARRE)
			self.frame:SetWidth(maxWidth) -- + OvaleOptions:GetApparence().iconShiftX
			self.frame:SetHeight(maxHeight+BARRE+margin) -- + OvaleOptions:GetApparence().iconShiftY
			self.content:SetPoint("TOPLEFT",self.frame,"TOPLEFT",maxWidth + OvaleOptions:GetApparence().iconShiftX,OvaleOptions:GetApparence().iconShiftY)
		end
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		
		
		self.Hide = Hide
		self.Show = Show
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.ApplyStatus = ApplyStatus
		self.LayoutFinished = OnLayoutFinished
		self.UpdateIcons = UpdateIcons
		self.OnSkinChanged = OnSkinChanged
		self.ToggleOptions = ToggleOptions
		self.OnUpdate = OnUpdate
		self.GetScore = GetScore

--<public-properties>		
		self.type = "Frame"
		self.localstatus = {}
		self.actions = {}
		self.frame = frame
		self.updateFrame = CreateFrame("Frame")
		self.barre = self.frame:CreateTexture();
		self.content = CreateFrame("Frame",nil,frame)
		if Masque then
			self.skinGroup = Masque:Group("Ovale")
		end
		self.lastUpdate = nil
		--Cheating with frame object which has an obj property
		--TODO: Frame Class
		self.obj = nil
--</public-properties>		
		
		frame.obj = self
		frame:SetWidth(100)
		frame:SetHeight(100)
		frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
		if not OvaleOptions:GetApparence().clickThru then
			frame:EnableMouse()
		end
		frame:SetMovable(true)
		frame:SetFrameStrata("BACKGROUND")
		frame:SetScript("OnMouseDown", frameOnMouseDown)
		frame:SetScript("OnMouseUp", frameOnMouseUp)
		frame:SetScript("OnEnter", frameOnEnter)
		frame:SetScript("OnLeave", frameOnLeave)
	--	frame:SetScript("OnUpdate", frameOnUpdate)		
		frame:SetScript("OnHide",frameOnClose)
		frame:SetAlpha(OvaleOptions:GetApparence().alpha)
		
		self.updateFrame:SetScript("OnUpdate", frameOnUpdate)
		self.updateFrame.obj = self
		
		self.barre:SetTexture(0,0.8,0)
		self.barre:SetPoint("TOPLEFT",0,0)
		self.barre:Hide()
			
		--Container Support
		local content = self.content 
		content.obj = self
		content:SetWidth(200)
		content:SetHeight(100)
		content:Hide()
		content:SetAlpha(OvaleOptions:GetApparence().optionsAlpha)
		
		AceGUI:RegisterAsContainer(self)


		return self	
	end
--</public-methods>
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

