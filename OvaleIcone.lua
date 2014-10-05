--[[--------------------------------------------------------------------
    Copyright (C) 2009, 2010, 2011, 2012 Sidoine De Wispelaere.
    Copyright (C) 2012, 2013, 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local _, Ovale = ...

--<class name="OvaleIcone" inherits="ActionButtonTemplate" />

--<private-static-properties>
local L = Ovale.L
local OvaleOptions = Ovale.OvaleOptions
local OvaleSpellBook = Ovale.OvaleSpellBook
local OvaleState = Ovale.OvaleState

local format = string.format
local next = next
local pairs = pairs
local strfind = string.find
local strsub = string.sub
local tostring = tostring
local API_GetTime = GetTime
--</private-static-properties>

local function HasScriptControls()
	return (next(Ovale.checkBoxWidget) ~= nil or next(Ovale.listWidget) ~= nil)
end

--<public-methods>
local function SetValue(self, value, actionTexture)
	self.icone:Show()
	self.icone:SetTexture(actionTexture);
	self.icone:SetAlpha(1.0)
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
		elseif value == math.huge then
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
				actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget)
	self.actionType = actionType
	self.actionId = actionId
	self.value = nil

	local now = API_GetTime()
	local state = OvaleState.state
	local profile = OvaleOptions:GetProfile()

	if startTime and actionTexture then
		-- Cooldown text.
		if actionTexture ~= self.texture
				or not self.startTime
				or (startTime ~= now and startTime > self.startTime + 0.01)
				or (startTime < self.cooldownEnd - 0.01) then

			if actionTexture ~= self.texture
					or not self.startTime
					or (startTime ~= now and startTime > self.startTime + 0.01) then
				self.cooldownStart = now
			end

			self.texture = actionTexture
			self.cooldownEnd = startTime
			if startTime == now then
				self.cd:Hide()
			else
				self.lastSound = nil
				if self.cdShown then
					self.cd:Show()
					self.cd:SetCooldown(self.cooldownStart, self.cooldownEnd - self.cooldownStart);
				end
			end
		end
		if not profile.apparence.flashIcon and startTime <= now then
			self.cd:Hide()
		end

		self.startTime = startTime

		-- L'icône avec le cooldown
		self.icone:Show()
		self.icone:SetTexture(actionTexture)

		if actionUsable then
			self.icone:SetAlpha(1.0)
		else
			self.icone:SetAlpha(0.33)
		end

		-- Icon color overlay (red or not red).
		local red = false
		if startTime > actionCooldownStart + actionCooldownDuration + 0.01
				and startTime > now
				and startTime > state.nextCast then
			red = true
		end
		if red then
			self.icone:SetVertexColor(0.75, 0.2, 0.2)
		else
			self.icone:SetVertexColor(1, 1, 1)
		end

		-- Action help text.
		self.actionHelp = element.params.help

		-- Sound file.
		if element.params.sound and not self.lastSound then
			local delay = element.params.soundtime or 0.5
			if now >= startTime - delay then
				self.lastSound = element.params.sound
			--	print("Play" .. self.lastSound)
				PlaySoundFile(self.lastSound)
			end
		end

		if not red and startTime > now and profile.apparence.highlightIcon then
			local lag = 0.6
			local newShouldClick = (startTime < now + lag)
			if self.shouldClick ~= newShouldClick then
				if newShouldClick then
					self:SetChecked(1)
				else
					self:SetChecked(0)
				end
				self.shouldClick = newShouldClick
			end
		elseif self.shouldClick then
			self.shouldClick = false
			self:SetChecked(0)
		end

		-- Remaining time.
		if (profile.apparence.numeric or self.params.text == "always") and startTime > now then
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
		if element.params.text then
			self.focusText:SetText(tostring(element.params.text))
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
			self:SetChecked(0)
			self.shouldClick = false
		end
	end

	return startTime, element
end

local function SetHelp(self, help)
	self.help = help
end

local function SetParams(self, params, secure)
	self.params = params

	self.actionButton = false
	if secure then
		for k,v in pairs(params) do
			local f = strfind(k, "spell")
			if f then
				local prefix = strsub(k, 1, f-1)
				local suffix = strsub(k, f + 5)
				local param
				Ovale:FormatPrint("%stype%s", prefix, suffix)
				self:SetAttribute(prefix .. "type" .. suffix, "spell")
				self:SetAttribute("unit", self.params.target or "target")
				self:SetAttribute(k, OvaleSpellBook:GetSpellName(v))
				self.actionButton = true
			end
		end
	end
end

local function SetFontScale(self, scale)
	self.fontScale = scale
	self.shortcut:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
	self.rangeIndicator:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
end

local function SetRangeIndicator(self, text)
	self.rangeIndicator:SetText(text)
end
--</public-methods>

function OvaleIcone_OnMouseUp(self)
	if not self.actionButton then
		Ovale:ToggleOptions()
	end
	self:SetChecked(1)
end

function OvaleIcone_OnEnter(self)
	if self.help or self.actionType or HasScriptControls() then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		if self.help then
			GameTooltip:SetText(L[self.help])
		end
		if self.actionType then
			local actionHelp = self.actionHelp
			if not actionHelp then
				if self.actionType == "spell" then
					actionHelp = OvaleSpellBook:GetSpellName(self.actionId)
				elseif self.actionType == "value" then
					actionHelp = (self.value < math.huge) and tostring(self.value) or "infinity"
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

function OvaleIcone_OnLeave(self)
	if self.help or HasScriptControls() then
		GameTooltip:Hide()
	end
end

function OvaleIcone_OnLoad(self)
	local name = self:GetName()
	local profile = OvaleOptions:GetProfile()

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
	self.startTime = nil
	self.cooldownEnd = nil
	self.cooldownStart = nil
	self.texture = nil
	self.params = nil
	self.actionButton = false
	self.actionType = nil
	self.actionId = nil
	self.actionHelp = nil
--</public-properties>

	self:SetScript("OnMouseUp", OvaleIcone_OnMouseUp)

	self.focusText:SetFontObject("GameFontNormalSmall");
	self.focusText:SetAllPoints(self);
	self.focusText:SetTextColor(1,1,1);
	self.focusText:SetText(L["Focus"])

	--self:RegisterForClicks("LeftButtonUp")
	self:RegisterForClicks("AnyUp")
	self.SetSkinGroup = SetSkinGroup
	self.Update = Update
	self.SetHelp = SetHelp
	self.SetParams = SetParams
	self.SetFontScale = SetFontScale
	self.SetRangeIndicator = SetRangeIndicator
	self.SetValue = SetValue
	if profile.clickThru then
		self:EnableMouse(false)
	end
end

