--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014, 2015 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...

--<class name="OvaleFrame" inherits="Frame" />
do
--<private-static-properties>
	local AceGUI = LibStub("AceGUI-3.0")
	local Masque = LibStub("Masque", true)
	local OvaleBestAction = Ovale.OvaleBestAction
	local OvaleCompile = Ovale.OvaleCompile
	local OvaleCooldown = Ovale.OvaleCooldown
	local OvaleDebug = Ovale.OvaleDebug
	local OvaleFuture = Ovale.OvaleFuture
	local OvaleGUID = Ovale.OvaleGUID
	local OvaleSpellFlash = Ovale.OvaleSpellFlash
	local OvaleState = Ovale.OvaleState
	local OvaleTimeSpan = Ovale.OvaleTimeSpan

	local Type = OVALE .. "Frame"
	local Version = 7

	local ipairs = ipairs
	local next = next
	local pairs = pairs
	local tostring = tostring
	local wipe = wipe
	local API_CreateFrame = CreateFrame
	local API_GetTime = GetTime
	local API_RegisterStateDriver = RegisterStateDriver
	local NextTime = OvaleTimeSpan.NextTime
	local INFINITY = math.huge
	-- GLOBALS: UIParent

	-- Mininum time in seconds for refreshing the best action.
	local MIN_REFRESH_TIME = 0.05
--</private-static-properties>

--<public-methods>
	local function frameOnClose(self)
		self.obj:Fire("OnClose")
	end
	
	local function closeOnClick(self)
		self.obj:Hide()
	end
	
	local function frameOnMouseDown(self)
		if (not Ovale.db.profile.apparence.verrouille) then
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
		local profile = Ovale.db.profile
		local x, y = self:GetCenter()
		local parentX, parentY = self:GetParent():GetCenter()
		profile.apparence.offsetX = x - parentX
		profile.apparence.offsetY = y - parentY
	end
	
	local function frameOnEnter(self)
		local profile = Ovale.db.profile
		if not (profile.apparence.enableIcons and profile.apparence.verrouille) then
			self.obj.barre:Show()
        end
	end
	
	local function frameOnLeave(self)
		self.obj.barre:Hide()

	end
	
	local function frameOnUpdate(self, elapsed)
		self.obj:OnUpdate(elapsed)
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
	
	local function OnUpdate(self, elapsed)
		--[[
			Refresh the best action if we've exceeded the minimum update interval since the last refresh,
			or if one of the units the script is tracking needs a refresh.

			If the target or focus exists, then the unit needs a refresh, even if out of combat.
		--]]
		local guid = OvaleGUID:UnitGUID("target") or OvaleGUID:UnitGUID("focus")
		if guid then
			Ovale.refreshNeeded[guid] = true
		end
		self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
		local refresh = OvaleDebug.trace or self.timeSinceLastUpdate > MIN_REFRESH_TIME and next(Ovale.refreshNeeded)
		if refresh then
			-- Accumulate refresh interval statistics.
			Ovale:AddRefreshInterval(self.timeSinceLastUpdate * 1000)

			local state = OvaleState.state
			state:Initialize()

			if OvaleCompile:EvaluateScript() then
				Ovale:UpdateFrame()
			end

			local profile = Ovale.db.profile
			local iconNodes = OvaleCompile:GetIconNodes()
			for k, node in ipairs(iconNodes) do
				-- Set the true target of "target" references in the icon's body.
				if node.namedParams and node.namedParams.target then
					state.defaultTarget = node.namedParams.target
				else
					state.defaultTarget = "target"
				end
				-- Set the number of enemies on the battlefield, if given via "enemies=N".
				if node.namedParams and node.namedParams.enemies then
					state.enemies = node.namedParams.enemies
				else
					state.enemies = nil
				end
				-- Get the best action for this icon node.
				state:Log("+++ Icon %d", k)
				OvaleBestAction:StartNewAction(state)
				local atTime = state.nextCast
				if state.lastSpellId ~= state.lastGCDSpellId then
					-- The previous spell cast did not trigger the GCD, so compute the next action at the current time.
					atTime = state.currentTime
				end
				local timeSpan, element = OvaleBestAction:GetAction(node, state, atTime)
				local start
				if element and element.offgcd then
					start = NextTime(timeSpan, state.currentTime)
				else
					start = NextTime(timeSpan, atTime)
				end
				-- Refresh the action button for the node.
				if profile.apparence.enableIcons then
					self:UpdateActionIcon(state, node, self.actions[k], element, start)
				end
				if profile.apparence.spellFlash.enabled then
					OvaleSpellFlash:Flash(state, node, element, start)
				end
			end

			wipe(Ovale.refreshNeeded)
			OvaleDebug:UpdateTrace()
			Ovale:PrintOneTimeMessages()
			self.timeSinceLastUpdate = 0
		end
	end

	local function UpdateActionIcon(self, state, node, action, element, start, now)
		local profile = Ovale.db.profile
		local icons = action.secure and action.secureIcons or action.icons

		now = now or API_GetTime()
		if element and element.type == "value" then
			local value
			if element.value and element.origin and element.rate then
				value = element.value + (now - element.origin) * element.rate
			end
			state:Log("GetAction: start=%s, value=%f", start, value)
			local actionTexture
			if node.namedParams and node.namedParams.texture then
				actionTexture = node.namedParams.texture
			end
			icons[1]:SetValue(value, actionTexture)
			if #icons > 1 then
				icons[2]:Update(element, nil)
			end
		else
			local actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut, actionIsCurrent, actionEnable,
				actionType, actionId, actionTarget, actionResourceExtend = OvaleBestAction:GetActionInfo(element, state)
			-- Add any extra time needed to pool resources.
			if actionResourceExtend and actionResourceExtend > 0 then
				if actionCooldownDuration > 0 then
					state:Log("Extending cooldown of spell ID '%s' for primary resource by %fs.", actionId, actionResourceExtend)
					actionCooldownDuration = actionCooldownDuration + actionResourceExtend
				elseif element.namedParams.pool_resource and element.namedParams.pool_resource == 1 then
					state:Log("Delaying spell ID '%s' for primary resource by %fs.", actionId, actionResourceExtend)
					start = start + actionResourceExtend
				end
			end
			state:Log("GetAction: start=%s, id=%s", start, actionId)
			
			-- If this action is the same as the spell currently casting in the simulator, then start after the previous cast has finished.
			if actionType == "spell" and actionId == state.currentSpellId and start and state.nextCast and start < state.nextCast then
				start = state.nextCast
			end
			if start and node.namedParams.nocd and now < start - node.namedParams.nocd then
				icons[1]:Update(element, nil)
			else
				icons[1]:Update(element, start, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
					actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend)
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

			if (node.namedParams.size ~= "small" and not node.namedParams.nocd and profile.apparence.predictif) then
				if start then
					state:Log("****Second icon %s", start)
					state:ApplySpell(actionId, OvaleGUID:UnitGUID(actionTarget), start)
					local atTime = state.nextCast
					if actionId ~= state.lastGCDSpellId then
						-- The previous spell cast did not trigger the GCD, so compute the next action at the current time.
						atTime = state.currentTime
					end
					local timeSpan, nextElement = OvaleBestAction:GetAction(node, state, atTime)
					local start
					if nextElement and nextElement.offgcd then
						start = NextTime(timeSpan, state.currentTime)
					else
						start = NextTime(timeSpan, atTime)
					end
					icons[2]:Update(nextElement, start, OvaleBestAction:GetActionInfo(nextElement, state))
				else
					icons[2]:Update(element, nil)
				end
			end
		end
	end

	local function UpdateFrame(self)
		local profile = Ovale.db.profile
		self.frame:SetPoint("CENTER", self.hider, "CENTER", profile.apparence.offsetX, profile.apparence.offsetY)
		self.frame:EnableMouse(not profile.apparence.clickThru)
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
		local profile = Ovale.db.profile
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
			if (node.namedParams ~= nil and node.namedParams.size == "small") then
				newScale = profile.apparence.smallIconScale
				width = newScale * 36 + margin
				height = newScale * 36 + margin
				nbIcons = 1
			else
				newScale = profile.apparence.iconScale
				width =newScale * 36 + margin
				height = newScale * 36 + margin
				if profile.apparence.predictif and node.namedParams.type ~= "value" then
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
						action.icons[l] = API_CreateFrame("CheckButton", "Icon"..k.."n"..l, self.frame, OVALE .. "IconTemplate");
					end
					icon = action.icons[l]
				else
					if not action.secureIcons[l] then
						action.secureIcons[l] = API_CreateFrame("CheckButton", "SecureIcon"..k.."n"..l, self.frame, "Secure" .. OVALE .. "IconTemplate");
					end
					icon = action.secureIcons[l]
				end
				local scale = action.scale
				if l> 1 then
					scale = scale * profile.apparence.secondIconScale
				end
				icon:SetPoint("TOPLEFT",self.frame,"TOPLEFT",(action.left + (l-1)*action.dx)/scale,(action.top - (l-1)*action.dy)/scale)
				icon:SetScale(scale)
				icon:SetRemainsFont(profile.apparence.remainsFontColor)
				icon:SetFontScale(profile.apparence.fontScale)
				icon:SetParams(node.positionalParams, node.namedParams)
				icon:SetHelp((node.namedParams ~= nil and node.namedParams.help) or nil)
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
		local hider = API_CreateFrame("Frame", OVALE .. "PetBattleFrameHider", UIParent, "SecureHandlerStateTemplate")
		hider:SetAllPoints(true)
		API_RegisterStateDriver(hider, "visibility", "[petbattle] hide; show")

		local frame = API_CreateFrame("Frame", nil, hider)
		local self = {}
		local profile = Ovale.db.profile

		self.Hide = Hide
		self.Show = Show
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.LayoutFinished = OnLayoutFinished
		self.UpdateActionIcon = UpdateActionIcon
		self.UpdateFrame = UpdateFrame
		self.UpdateIcons = UpdateIcons
		self.ToggleOptions = ToggleOptions
		self.OnUpdate = OnUpdate
		self.GetScore = GetScore

--<public-properties>		
		self.type = "Frame"
		self.localstatus = {}
		self.actions = {}
		self.frame = frame
		self.hider = hider
		self.updateFrame = API_CreateFrame("Frame", OVALE .. "UpdateFrame")
		self.barre = self.frame:CreateTexture();
		self.content = API_CreateFrame("Frame", nil, self.updateFrame)
		if Masque then
			self.skinGroup = Masque:Group(OVALE)
		end
		self.timeSinceLastUpdate = INFINITY
		--Cheating with frame object which has an obj property
		--TODO: Frame Class
		self.obj = nil
--</public-properties>		
		
		frame.obj = self
		frame:SetWidth(100)
		frame:SetHeight(100)
		self:UpdateFrame()
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
