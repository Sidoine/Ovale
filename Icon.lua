--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...

--<class name="OvaleIcon" inherits="ActionButtonTemplate" />

--<private-static-properties>
local L = Ovale.L
local OvaleSpellBook = Ovale.OvaleSpellBook
local OvaleState = Ovale.OvaleState

local format = string.format
local next = next
local pairs = pairs
local strfind = string.find
local strsub = string.sub
local tostring = tostring
local API_GetTime = GetTime
local API_PlaySoundFile = PlaySoundFile
local INFINITY = math.huge
-- GLOBALS: _G
-- GLOBALS: GameTooltip

-- Threshold for resetting the cooldown animation.
-- This should be more than OvaleFuture's SIMULATOR_LAG.
local COOLDOWN_THRESHOLD = 0.1
--</private-static-properties>

local function HasScriptControls()
	return (next(Ovale.checkBoxWidget) ~= nil or next(Ovale.listWidget) ~= nil)
end

--<public-methods>
local function SetValue(self, value, actionTexture)
	self.icone:Show()
	self.icone:SetTexture(actionTexture)
	self.icone:SetAlpha(Ovale.db.profile.apparence.alpha)
	self.cd:Hide()
	self.focusText:Hide()
	self.rangeIndicator:Hide()
	self.shortcut:Hide()
	if value then
		self.actionType = "value"
		self.actionHelp = nil
		self.value = value
		if value < 10 then
			self.remains:SetFormattedText("%.1f", value)
		elseif value == INFINITY then
			self.remains:SetFormattedText("inf")
		else
			self.remains:SetFormattedText("%d", value)
		end
		self.remains:Show()
	else
		self.remains:Hide()
	end
	self:Show()
end

local function Update(self, element, startTime, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend)
	self.actionType = actionType
	self.actionId = actionId
	self.value = nil

	local now = API_GetTime()
	local state = OvaleState.state
	local profile = Ovale.db.profile

	if startTime and actionTexture then
		-- Cooldown.
		local cd = self.cd
		local resetCooldown = false
		if startTime > now then
			--[[
				Check for the cooldown duration mysteriously being reset to zero while an active
				cooldown animation is in effect, and force the cooldown information to be reset
				to the existing information.
			--]]
			local duration = cd:GetCooldownDuration()
			if duration == 0 and self.texture == actionTexture and self.cooldownStart and self.cooldownEnd then
				resetCooldown = true
			end
			if self.texture ~= actionTexture or not self.cooldownStart or not self.cooldownEnd then
				-- Update the cooldown if this is a new action
				self.cooldownStart = now
				self.cooldownEnd = startTime
				resetCooldown = true
			elseif startTime < self.cooldownEnd - COOLDOWN_THRESHOLD
					or startTime > self.cooldownEnd + COOLDOWN_THRESHOLD then
				-- Update the cooldown if the new end time would exceed the tolerance threshold.
				if startTime - self.cooldownEnd > 0.25 or startTime - self.cooldownEnd < -0.25 then 
					self.cooldownStart = now
				else
					--[[ 
						Modify the start and end time of the cooldown swipe so that it maintains the same 
						percent progress and only accelerates/decelerates the swipe.
					]]--
					local oldCooldownProgressPercent = (now - self.cooldownStart) / (self.cooldownEnd - self.cooldownStart)
					self.cooldownStart = (now - oldCooldownProgressPercent * startTime) / (1 - oldCooldownProgressPercent)
				end
				self.cooldownEnd = startTime
				resetCooldown = true
			end
			self.texture = actionTexture
		else
			-- The cooldown is finished.
			self.cooldownStart = nil
			self.cooldownEnd = nil
		end
		if self.cdShown and profile.apparence.flashIcon and self.cooldownStart and self.cooldownEnd then
			local start, ending = self.cooldownStart, self.cooldownEnd
			local duration = ending - start
			if resetCooldown and duration > COOLDOWN_THRESHOLD then
				cd:SetDrawEdge(false)
				cd:SetSwipeColor(0, 0, 0, 0.8)
				cd:SetCooldown(start, duration)
				cd:Show()
			end
		else
			self.cd:Hide()
		end

		-- Icon texture and cooldown
		self.icone:Show()
		self.icone:SetTexture(actionTexture)

		local alpha = profile.apparence.alpha
		if actionUsable then
			self.icone:SetAlpha(alpha)
		else
			-- Unusable actions are displayed at half the normal alpha.
			alpha = alpha / 2
			self.icone:SetAlpha(alpha)
		end

		-- Icon color overlay (red or not red).
		if element.namedParams.nored ~= 1 and actionResourceExtend and actionResourceExtend > 0 then
			self.icone:SetVertexColor(0.75, 0.2, 0.2)
		else
			self.icone:SetVertexColor(1, 1, 1)
		end

		-- Action help text.
		self.actionHelp = element.namedParams.help

		-- Sound file.
		if not (self.cooldownStart and self.cooldownEnd) then
			self.lastSound = nil
		end
		if element.namedParams.sound and not self.lastSound then
			local delay = element.namedParams.soundtime or 0.5
			if now >= startTime - delay then
				self.lastSound = element.namedParams.sound
			--	print("Play" .. self.lastSound)
				API_PlaySoundFile(self.lastSound)
			end
		end

		if not red and startTime > now and profile.apparence.highlightIcon then
			local lag = 0.6
			local newShouldClick = (startTime < now + lag)
			if self.shouldClick ~= newShouldClick then
				if newShouldClick then
					self:SetChecked(true)
				else
					self:SetChecked(false)
				end
				self.shouldClick = newShouldClick
			end
		elseif self.shouldClick then
			self.shouldClick = false
			self:SetChecked(false)
		end

		-- Remaining time.
		if (profile.apparence.numeric or self.namedParams.text == "always") and startTime > now then
			self.remains:SetFormattedText("%.1f", startTime - now)
			self.remains:Show()
		else
			self.remains:Hide()
		end

		-- Keyboard shortcut.
		if profile.apparence.raccourcis then
			self.shortcut:Show()
			self.shortcut:SetText(actionShortcut)
		else
			self.shortcut:Hide()
		end

		-- Range indicator.
		if actionInRange == 1 then
			self.rangeIndicator:SetVertexColor(0.6,0.6,0.6)
			self.rangeIndicator:Show()
		elseif actionInRange == 0 then
			self.rangeIndicator:SetVertexColor(1.0,0.1,0.1)
			self.rangeIndicator:Show()
		else
			self.rangeIndicator:Hide()
		end

		-- Focus text.
		if element.namedParams.text then
			self.focusText:SetText(tostring(element.namedParams.text))
			self.focusText:Show()
		elseif actionTarget and actionTarget ~= "target" then
			self.focusText:SetText(actionTarget)
			self.focusText:Show()
		else
			self.focusText:Hide()
		end

		self:Show()
	else
		self.icone:Hide()
		self.rangeIndicator:Hide()
		self.shortcut:Hide()
		self.remains:Hide()
		self.focusText:Hide()
		if profile.apparence.hideEmpty then
			self:Hide()
		else
			self:Show()
		end
		if self.shouldClick then
			self:SetChecked(false)
			self.shouldClick = false
		end
	end

	return startTime, element
end

local function SetHelp(self, help)
	self.help = help
end

local function SetParams(self, positionalParams, namedParams, secure)
	self.positionalParams = positionalParams
	self.namedParams = namedParams

	self.actionButton = false
	if secure then
		for k, v in pairs(namedParams) do
			local index = strfind(k, "spell")
			if index then
				local prefix = strsub(k, 1, index - 1)
				local suffix = strsub(k, index + 5)
				self:SetAttribute(prefix .. "type" .. suffix, "spell")
				self:SetAttribute("unit", self.namedParams.target or "target")
				self:SetAttribute(k, OvaleSpellBook:GetSpellName(v))
				self.actionButton = true
			end
		end
	end
end

local function SetRemainsFont(self, color)
	self.remains:SetTextColor(color.r, color.g, color.b, 1.0)
	self.remains:SetJustifyH("left")
	self.remains:SetPoint("BOTTOMLEFT", 2, 2)	
end

local function SetFontScale(self, scale)
	self.fontScale = scale
	self.remains:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
	self.shortcut:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
	self.rangeIndicator:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
	self.focusText:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
end

local function SetRangeIndicator(self, text)
	self.rangeIndicator:SetText(text)
end
--</public-methods>

local function OvaleIcon_OnMouseUp(self)
	if not self.actionButton then
		Ovale:ToggleOptions()
	end
	self:SetChecked(true)
end

-- GLOBALS: OvaleIcon_OnEnter
function OvaleIcon_OnEnter(self)
	if self.help or self.actionType or HasScriptControls() then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		if self.help then
			GameTooltip:SetText(L[self.help])
		end
		if self.actionType then
			local actionHelp = self.actionHelp
			if not actionHelp then
				if self.actionType == "spell" then
					actionHelp = OvaleSpellBook:GetSpellName(self.actionId) -- .. " (" .. self.actionId .. ")"
				elseif self.actionType == "value" then
					actionHelp = (self.value < INFINITY) and tostring(self.value) or "infinity"
				else
					actionHelp = format("%s %s", self.actionType, tostring(self.actionId))
				end
			end
			GameTooltip:AddLine(actionHelp, 0.5, 1, 0.75)
		end
		if HasScriptControls() then
			GameTooltip:AddLine(L["Cliquer pour afficher/cacher les options"], 1, 1, 1)
		end
		GameTooltip:Show()
	end
end

-- GLOBALS: OvaleIcon_OnLeave
function OvaleIcon_OnLeave(self)
	if self.help or HasScriptControls() then
		GameTooltip:Hide()
	end
end

-- GLOBALS: OvaleIcon_OnLoad
function OvaleIcon_OnLoad(self)
	local name = self:GetName()
	local profile = Ovale.db.profile

--<public-properties>
	self.icone = _G[name.."Icon"]
	self.shortcut = _G[name.."HotKey"]
	self.remains = _G[name.."Name"]
	self.rangeIndicator = _G[name.."Count"]
	self.rangeIndicator:SetText(profile.apparence.targetText)
	self.cd = _G[name.."Cooldown"]
	self.normalTexture = _G[name.."NormalTexture"]
	local fontName, fontHeight, fontFlags = self.shortcut:GetFont()
	self.fontName = fontName
	self.fontHeight = fontHeight
	self.fontFlags = fontFlags
	self.focusText = self:CreateFontString(nil, "OVERLAY");
	self.cdShown = true
	self.shouldClick = false
	self.help = nil
	self.value = nil
	self.fontScale = nil
	self.lastSound = nil
	self.cooldownEnd = nil
	self.cooldownStart = nil
	self.texture = nil
	self.positionalParams = nil
	self.namedParams = nil
	self.actionButton = false
	self.actionType = nil
	self.actionId = nil
	self.actionHelp = nil
--</public-properties>

	self:SetScript("OnMouseUp", OvaleIcon_OnMouseUp)

	self.focusText:SetFontObject("GameFontNormalSmall");
	self.focusText:SetAllPoints(self);
	self.focusText:SetTextColor(1,1,1);
	self.focusText:SetText(L["Focus"])

	--self:RegisterForClicks("LeftButtonUp")
	self:RegisterForClicks("AnyUp")
	self.Update = Update
	self.SetHelp = SetHelp
	self.SetParams = SetParams
	self.SetRemainsFont = SetRemainsFont
	self.SetFontScale = SetFontScale
	self.SetRangeIndicator = SetRangeIndicator
	self.SetValue = SetValue
	if profile.clickThru then
		self:EnableMouse(false)
	end
end

