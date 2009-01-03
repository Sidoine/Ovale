function OvaleIcone_OnUpdate(self)
	Ovale.maintenant = GetTime();
	
	if (not Ovale.bug) then
		Ovale.traced = false
	end
		
	local minAttente = Ovale:CalculerMeilleureAction(Ovale.masterNode)
	local meilleureAction = Ovale.retourAction
	
	if (Ovale.trace) then
		Ovale.trace=false
		Ovale.traced = true
	end
	
	if (Ovale.bug and not Ovale.traced) then
		Ovale.trace = true
	end
		
	if (minAttente~=nil and meilleureAction) then	
	
		-- On attend que le sort courant soit fini
		local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo("player")
		if (spell) then
			local attenteFinCast = endTime/1000 - Ovale.maintenant
			if (attenteFinCast > minAttente) then
				minAttente = attenteFinCast
			end
		end
		
		local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo("player")
		if (spell) then
			local attenteFinCast = endTime/1000 - Ovale.maintenant
			if (attenteFinCast > minAttente) then
				minAttente = attenteFinCast
			end
		end

		if (meilleureAction~=self.actionCourante or self.ancienneAttente==nil or 
			(minAttente~=0 and minAttente>self.ancienneAttente+0.01)) then
			self.actionCourante = meilleureAction
			self.debutAction = Ovale.maintenant
		end
		
		self.ancienneAttente = minAttente
		
		-- L'icône avec le cooldown
		self.icone:Show()
		self.icone:SetTexture(GetActionTexture(meilleureAction));
		
		if (IsUsableAction(meilleureAction)) then
			self.icone:SetAlpha(1.0)
		else
			self.icone:SetAlpha(0.25)
		end
		
		if (minAttente~=0) then
			self.cd:SetCooldown(self.debutAction, minAttente+(Ovale.maintenant-self.debutAction));
		end
		
		-- Le raccourcis clavier 
		self.shortcut:Show()
		self.shortcut:SetText(Ovale.shortCut[meilleureAction])
		
		-- L'indicateur de portée
		self.aPortee:Show()
		if (IsActionInRange(meilleureAction,"target")==1) then
			self.aPortee:SetTexture(1,1,1)
			self.aPortee:Show()
		elseif (IsActionInRange(meilleureAction,"target")==0) then
			self.aPortee:SetTexture(1,0,0)
			self.aPortee:Show()
		else
			self.aPortee:Hide()
		end
	else
		self.icone:Hide()
		self.aPortee:Hide()
		self.shortcut:Hide()
	end
end


function OvaleIcone_OnLoad(self)
	self.icone = self:CreateTexture();
	self.icone:SetDrawLayer("ARTWORK");
	self.icone:SetAllPoints(self);
	self.icone:Show();
		
	self.shortcut = self:CreateFontString(nil, "OVERLAY");
	self.shortcut:SetFontObject("GameFontHighlightLarge");
	self.shortcut:SetPoint("BOTTOMLEFT",0,0);
	self.shortcut:SetText("A");
	self.shortcut:SetTextColor(1,1,1);
	self.shortcut:Show();
	
	self.aPortee = self:CreateTexture();
	self.aPortee:SetDrawLayer("OVERLAY")
	self.aPortee:SetPoint("TOPRIGHT",self,"TOPRIGHT",-4,-4);
	self.aPortee:SetHeight(self:GetHeight()/6);
	self.aPortee:SetWidth(self:GetWidth()/6);
	self.aPortee:SetTexture(0,0,1);
	
	self.cd = CreateFrame("Cooldown",nil,self,nil);
	self.cd:SetAllPoints(self);
end
