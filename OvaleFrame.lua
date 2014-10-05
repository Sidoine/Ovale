--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local addonName, Ovale = ...

--<class name="OvaleFrame" inherits="Frame" />
do
--<private-static-properties>
	local AceGUI = LibStub("AceGUI-3.0")
	local Masque = LibStub("Masque", true)
	local OvaleBestAction = Ovale.OvaleBestAction
	local OvaleCompile = Ovale.OvaleCompile
	local OvaleCondition = Ovale.OvaleCondition
	local OvaleCooldown = Ovale.OvaleCooldown
	local OvaleGUID = Ovale.OvaleGUID
	local OvaleOptions = Ovale.OvaleOptions
	local OvaleState = Ovale.OvaleState
	local OvaleTimeSpan = Ovale.OvaleTimeSpan

	local Type = addonName .. "Frame"
	local Version = 7

	local pairs = pairs
	local tostring = tostring
	local wipe = table.wipe
	local API_CreateFrame = CreateFrame
	local API_GetSpellInfo = GetSpellInfo
	local API_GetSpellTexture = GetSpellTexture
	local API_GetTime = GetTime
	local API_RegisterStateDriver = RegisterStateDriver
	local NextTime = OvaleTimeSpan.NextTime
--</private-static-properties>

--<public-methods>
	local function frameOnClose(self)
		self.obj:Fire("OnClose")
	end
	
	local function closeOnClick(self)
		self.obj:Hide()
	end
	
	local function frameOnMouseDown(self)
		if (not OvaleOptions:GetProfile().apparence.verrouille) then
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
		if (not OvaleOptions:GetProfile().apparence.verrouille) then
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
					local now = API_GetTime()
					local lag = now - action.waitStart
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
		-- Update current time.
		local now = API_GetTime()

		local profile = OvaleOptions:GetProfile()
		-- Force a refresh if we've exceeded the minimum update interval since the last refresh.
		local forceRefresh = not self.lastUpdate or (now > self.lastUpdate + profile.apparence.updateInterval)
		-- Refresh the icons if we're forcing a refresh or if one of the units the script is tracking needs a refresh.
		local refresh = forceRefresh or next(Ovale.refreshNeeded)
		if not refresh then return end

		self.lastUpdate = now

		local state = OvaleState.state
		state:Initialize()

		if OvaleCompile:EvaluateScript() then
			Ovale:UpdateFrame()
		end

		local iconNodes = OvaleCompile:GetIconNodes()
		for k, node in ipairs(iconNodes) do
			-- Set the true target of "target" references in the icon's body.
			if node.params and node.params.target then
				OvaleCondition.defaultTarget = node.params.target
			else
				OvaleCondition.defaultTarget = "target"
			end
			-- Set the number of enemies on the battlefield, if given via "enemies=N".
			if node.params and node.params.enemies then
				state.enemies = node.params.enemies
			else
				state.enemies = nil
			end

			if refresh then
				Ovale:Logf("+++ Icon %d", k)
				OvaleBestAction:StartNewAction(state)
				local timeSpan, _, element = OvaleBestAction:GetAction(node, state)
				local start = NextTime(timeSpan, state.currentTime)
				if start then
					Ovale:Logf("Compute start = %f", start)
				end
				local action = self.actions[k]
				local icons = action.secure and action.secureIcons or action.icons
				if element and element.type == "value" then
					local actionTexture
					if node.params and node.params.texture then
						actionTexture = API_GetSpellTexture(node.params.texture)
					end
					local value
					if element.value and element.origin and element.rate then
						value = element.value + (now - element.origin) * element.rate
					end
					icons[1]:SetValue(value, actionTexture)
					if #icons > 1 then
						icons[2]:Update(element, nil)
					end
				else
					local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
						actionUsable, actionShortcut, actionIsCurrent, actionEnable,
						actionType, actionId, actionTarget = OvaleBestAction:GetActionInfo(element, state)

					-- Use the start time of the best action instead of the intersection of its start time
					-- with any conditions used to determine the best action.
					if element and element.params and element.params.nored == 1 then
						start = actionCooldownStart + actionCooldownDuration
						if start < state.currentTime then
							start = state.currentTime
						end
					end
					-- Dans le cas de canStopChannelling, on risque de demander d'interrompre le channelling courant, ce qui est stupide
					if start and state.currentSpellId and state.nextCast and actionType == "spell" and actionId == state.currentSpellId and start < state.nextCast then
						start = state.nextCast
					end
					if start and node.params.nocd and now < start - node.params.nocd then
						icons[1]:Update(element, nil)
					else
						icons[1]:Update(element, start, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
							actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget)
					end

					-- TODO: Scoring should allow for other actions besides spells.
					if actionType == "spell" then
						action.spellId = actionId
					else
						action.spellId = nil
					end
					if start and start <= now and actionUsable then
						action.waitStart = action.waitStart or now
					else
						action.waitStart = nil
					end

					if profile.apparence.moving and icons[1].cooldownStart and icons[1].cooldownEnd then
						local top=1-(now - icons[1].cooldownStart)/(icons[1].cooldownEnd-icons[1].cooldownStart)
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

					if (node.params.size ~= "small" and not node.params.nocd and profile.apparence.predictif) then
						if start then
							Ovale:Logf("****Second icon %f", start)
							local spellTarget
							if element then
								spellTarget = element.params.target
							end
							if not spellTarget or spellTarget == "target" then
								spellTarget = OvaleCondition.defaultTarget
							end
							state:ApplySpell(spellId, OvaleGUID:GetGUID(spellTarget))
							timeSpan, _, element = OvaleBestAction:GetAction(node, state)
							start = NextTime(timeSpan, state.currentTime)
							icons[2]:Update(element, start, OvaleBestAction:GetActionInfo(element, state))
						else
							icons[2]:Update(element, nil)
						end
					end
				end
			end
		end

		wipe(Ovale.refreshNeeded)
		Ovale:UpdateTrace()
		Ovale:PrintOneTimeMessages()
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
		local profile = OvaleOptions:GetProfile()
		self.frame:EnableMouse(not profile.apparence.clickThru)
		
		local left = 0
		local maxHeight = 0
		local maxWidth = 0
		local top = 0
		local BARRE = 8
		local margin = profile.apparence.margin

		local iconNodes = OvaleCompile:GetIconNodes()
		for k, node in ipairs(iconNodes) do
			if not self.actions[k] then
				self.actions[k] = {icons={}, secureIcons={}}
			end
			local action = self.actions[k]

			local width, height, newScale
			local nbIcons
			if (node.params.size == "small") then
				newScale = profile.apparence.smallIconScale
				width = newScale * 36 + margin
				height = newScale * 36 + margin
				nbIcons = 1
			else
				newScale = profile.apparence.iconScale
				width =newScale * 36 + margin
				height = newScale * 36 + margin
				if profile.apparence.predictif and node.params.type ~= "value" then
					nbIcons = 2
				else
					nbIcons = 1
				end
			end
			if (top + height > profile.apparence.iconScale * 36 + margin) then
				top = 0
				left = maxWidth
			end

			action.scale = newScale
			if (profile.apparence.vertical) then
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
						action.icons[l] = API_CreateFrame("CheckButton", "Icon"..k.."n"..l, self.frame, addonName .. "IconTemplate");
					end
					icon = action.icons[l]
				else
					if not action.secureIcons[l] then
						action.secureIcons[l] = API_CreateFrame("CheckButton", "SecureIcon"..k.."n"..l, self.frame, "Secure" .. addonName .. "IconTemplate");
					end
					icon = action.secureIcons[l]
				end
				local scale = action.scale
				if l> 1 then
					scale = scale * profile.apparence.secondIconScale
				end
				icon:SetPoint("TOPLEFT",self.frame,"TOPLEFT",(action.left + (l-1)*action.dx)/scale,(action.top - (l-1)*action.dy)/scale)
				icon:SetScale(scale)
				icon:SetFontScale(profile.apparence.fontScale)
				icon:SetParams(node.params)
				icon:SetHelp(node.params.help)
				icon:SetRangeIndicator(profile.apparence.targetText)
				icon:EnableMouse(not profile.apparence.clickThru)
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
		
		if (profile.apparence.vertical) then
			self.barre:SetWidth(maxHeight - margin)
			self.barre:SetHeight(BARRE)
			self.frame:SetWidth(maxHeight + profile.apparence.iconShiftY)
			self.frame:SetHeight(maxWidth+BARRE+margin + profile.apparence.iconShiftX)
			self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", maxHeight + profile.apparence.iconShiftX, profile.apparence.iconShiftY)
		else
			self.barre:SetWidth(maxWidth - margin)
			self.barre:SetHeight(BARRE)
			self.frame:SetWidth(maxWidth) -- + profile.apparence.iconShiftX
			self.frame:SetHeight(maxHeight+BARRE+margin) -- + profile.apparence.iconShiftY
			self.content:SetPoint("TOPLEFT", self.frame, "TOPLEFT", maxWidth + profile.apparence.iconShiftX, profile.apparence.iconShiftY)
		end
	end
	
	local function Constructor()
		-- Create parent frame for Ovale that auto-hides/shows based on whether the Pet Battle UI is active.
		local hider = API_CreateFrame("Frame", addonName .. "PetBattleFrameHider", UIParent, "SecureHandlerStateTemplate")
		hider:SetAllPoints(true)
		API_RegisterStateDriver(hider, "visibility", "[petbattle] hide; show")

		local frame = API_CreateFrame("Frame", nil, hider)
		local self = {}
		local profile = OvaleOptions:GetProfile()
		
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
		self.hider = hider
		self.updateFrame = API_CreateFrame("Frame")
		self.barre = self.frame:CreateTexture();
		self.content = API_CreateFrame("Frame",nil,frame)
		if Masque then
			self.skinGroup = Masque:Group(addonName)
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
		if not profile.apparence.clickThru then
			frame:EnableMouse()
		end
		frame:SetMovable(true)
		frame:SetFrameStrata("MEDIUM")
		frame:SetScript("OnMouseDown", frameOnMouseDown)
		frame:SetScript("OnMouseUp", frameOnMouseUp)
		frame:SetScript("OnEnter", frameOnEnter)
		frame:SetScript("OnLeave", frameOnLeave)
	--	frame:SetScript("OnUpdate", frameOnUpdate)		
		frame:SetScript("OnHide",frameOnClose)
		frame:SetAlpha(profile.apparence.alpha)
		
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
		content:SetAlpha(profile.apparence.optionsAlpha)
		
		AceGUI:RegisterAsContainer(self)

		return self	
	end
--</public-methods>
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

