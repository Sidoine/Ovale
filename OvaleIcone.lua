local L = LibStub("AceLocale-3.0"):GetLocale("Ovale")

--inherits ActionButtonTemplate

--<public-methods>
local function SetValue(self, value, actionTexture)
	self.icone:Show()
	self.icone:SetTexture(actionTexture);
	self.icone:SetAlpha(1.0)
	self.cd:Hide()
	self.focusText:Hide()
	self.aPortee:Hide()	
	self.shortcut:Hide()
	if value then
		if value<10 then
			value = string.format("%.1f", value)
		else
			value = string.format("%d", value)
		end
		self.remains:SetText(value)
	else
		self.remains:SetText()
	end
	self.remains:Show()
	self:Show()
end

local function Update(self, element, minAttente, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration,
				actionUsable, actionShortcut, actionIsCurrent, actionEnable, spellId, actionTarget)
				
	self.spellId = spellId
	if (minAttente~=nil and actionTexture) then	
	
		if (actionTexture~=self.actionCourante or self.ancienneAttente==nil or 
			(minAttente~=OvaleState.maintenant and minAttente>self.ancienneAttente+0.01) or
			(minAttente < self.finAction-0.01)) then
			if (actionTexture~=self.actionCourante or self.ancienneAttente==nil or 
					(minAttente~=OvaleState.maintenant and minAttente>self.ancienneAttente+0.01)) then
				self.debutAction = OvaleState.maintenant
			end
			self.actionCourante = actionTexture
			self.finAction = minAttente
			if (minAttente == OvaleState.maintenant) then
				self.cd:Hide()
			else
				self.lastSound = nil
				if self.cdShown then
					self.cd:Show()
					self.cd:SetCooldown(self.debutAction, self.finAction - self.debutAction);
				end
			end
		end
		
		if not OvaleOptions:GetApparence().flashIcon and minAttente<=OvaleState.maintenant then
			self.cd:Hide()
		end
		
		self.ancienneAttente = minAttente
		
		-- L'icône avec le cooldown
		self.icone:Show()
		self.icone:SetTexture(actionTexture);
		
		if (actionUsable) then
			self.icone:SetAlpha(1.0)
		else
			self.icone:SetAlpha(0.33)
		end
		
		local red
		if (minAttente > actionCooldownStart + actionCooldownDuration + 0.01 and minAttente > OvaleState.maintenant
			and minAttente>OvaleState.attenteFinCast) then
			self.icone:SetVertexColor(0.75,0.2,0.2)
			red = true
		else
			self.icone:SetVertexColor(1,1,1)
		end 
		
		--if (minAttente==OvaleState.maintenant) then
			--self.cd:Hide()
		--end

		if element.params.sound and not self.lastSound then
			local delay = element.params.soundtime or 0.5
			if OvaleState.maintenant>=minAttente - delay then
				self.lastSound = element.params.sound
			--	print("Play" .. self.lastSound)
				PlaySoundFile(self.lastSound)
			end
		end
		
		-- La latence
		if minAttente>OvaleState.maintenant and OvaleOptions:GetApparence().highlightIcon and not red then
			local lag = 0.6
			local newShouldClick
			if minAttente<OvaleState.maintenant + lag then
				newShouldClick = true
			else
				newShouldClick = false
			end
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
		
		-- Le temps restant
		if ((OvaleOptions:GetApparence().numeric or self.params.text == "always") and minAttente > OvaleState.maintenant) then
			self.remains:SetText(string.format("%.1f", minAttente - OvaleState.maintenant))
			self.remains:Show()
		else
			self.remains:Hide()
		end
		
		-- Le raccourcis clavier 
		if (OvaleOptions:GetApparence().raccourcis) then
			self.shortcut:Show()
			self.shortcut:SetText(actionShortcut)
		else
			self.shortcut:Hide()
			self.shortcut:SetText("")
		end
		
		-- L'indicateur de portée
		self.aPortee:Show()
		if (actionInRange==1) then
			self.aPortee:SetVertexColor(0.6,0.6,0.6)
			self.aPortee:Show()
		elseif (actionInRange==0) then
			self.aPortee:SetVertexColor(1.0,0.1,0.1)
			self.aPortee:Show()
		else
			self.aPortee:Hide()
		end
		if actionTarget and actionTarget~="target" then
			self.focusText:SetText(actionTarget)
			self.focusText:Show()
		else
			self.focusText:Hide()
		end
		self:Show()
	else
		self.icone:Hide()
		self.aPortee:Hide()
		self.shortcut:Hide()
		self.remains:Hide()
		self.focusText:Hide()
		if OvaleOptions:GetApparence().hideEmpty then
			self:Hide()
		else
			self:Show()
		end
		if self.shouldClick then
			self:SetChecked(0)
			self.shouldClick = false
		end
	end
	
	
	return minAttente,element
end

local function SetHelp(self, help)
	self.help = help
end

local function SetParams(self, params, secure)
	self.params = params
	
	self.actionButton = false
	if secure then
		for k,v in pairs(params) do
			local f = string.find(k, "spell")
			if f then
				local prefix = string.sub(k, 1, f-1)
				local suffix = string.sub(k, f + 5)
				local param
				Ovale:Print(prefix.."type"..suffix)
				self:SetAttribute(prefix.."type"..suffix, "spell")
				self:SetAttribute("unit", self.params.target or "target")
				self:SetAttribute(k, OvaleData.spellList[v])
				self.actionButton = true
			end
		end
	end
end

local function SetFontScale(self, scale)
	self.fontScale = scale
	self.shortcut:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
	self.aPortee:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
end

local function SetRangeIndicator(self, text)
	self.aPortee:SetText(text)
end
--</public-methods>

function OvaleIcone_OnMouseUp(self)
	if not self.actionButton then
		Ovale:ToggleOptions()
	end
	self:SetChecked(1)
end

function OvaleIcone_OnEnter(self)
	if self.help or next(Ovale.casesACocher) or next(Ovale.listes) or self.spellId then
		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		if self.help then
			GameTooltip:SetText(L[self.help])
		end
		if self.spellId then
			GameTooltip:AddLine(GetSpellInfo(self.spellId),0.5,1,0.75)
		end
		if next(Ovale.casesACocher) or next(Ovale.listes) then
			GameTooltip:AddLine(L["Cliquer pour afficher/cacher les options"],1,1,1)
		end
		GameTooltip:Show()
	end
end

function OvaleIcone_OnLeave(self)
	if self.help  or next(Ovale.casesACocher) or next(Ovale.listes)  then
		GameTooltip:Hide()
	end
end

function OvaleIcone_OnLoad(self)
	local name = self:GetName()
	
--<public-properties>
	self.icone = _G[name.."Icon"]
	self.shortcut = _G[name.."HotKey"]
	self.remains = _G[name.."Name"]
	self.aPortee = _G[name.."Count"]
	self.aPortee:SetText(OvaleOptions:GetApparence().targetText)
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
	self.spellId = nil
	self.fontScale = nil
	self.lastSound = nil
	self.ancienneAttente = nil
	self.finAction = nil
	self.debutAction = nil
	self.actionCourante = nil
	self.params = nil
	self.actionButton = false
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
	if OvaleOptions:GetProfile().clickThru then
		self:EnableMouse(false)
	end
end

