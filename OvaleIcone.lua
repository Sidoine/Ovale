function OvaleIcone_OnUpdate(self)
	Ovale.maintenant = GetTime();
	
	if (not Ovale.bug) then
		Ovale.traced = false
	end
		
	Ovale:InitCalculerMeilleureAction()
	local minAttente = Ovale:CalculerMeilleureAction(self.masterNode)
	local meilleureAction = Ovale.retourAction
	
	if (Ovale.trace) then
		Ovale.trace=false
		Ovale.traced = true
	end
	
	if (Ovale.bug and not Ovale.traced) then
		Ovale.trace = true
	end
	
	if (Ovale.db.profile.apparence.avecCible and not UnitExists("target")) then
		minAttente = nil
	end
	
	if (Ovale.db.profile.apparence.enCombat and not Ovale.enCombat) then
		minAttente = nil
	end
	
	if (self.masterNode.params.nocd and 
		self.masterNode.params.nocd == 1 and minAttente~=nil and minAttente>1.5) then
		minAttente = nil
	end
		
	if (minAttente~=nil and meilleureAction) then	
	
		if (meilleureAction~=self.actionCourante or self.ancienneAttente==nil or 
			(minAttente~=0 and minAttente>self.ancienneAttente+0.01) or
			(Ovale.maintenant + minAttente < self.finAction-0.01)) then
			if (meilleureAction~=self.actionCourante or self.ancienneAttente==nil or 
					(minAttente~=0 and minAttente>self.ancienneAttente+0.01)) then
				self.debutAction = Ovale.maintenant
			end
			self.actionCourante = meilleureAction
			self.finAction = minAttente + Ovale.maintenant
			if (minAttente == 0) then
				self.cd:Hide()
			else
				self.cd:Show()
				self.cd:SetCooldown(self.debutAction, self.finAction - self.debutAction);
			end
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
		
		local start, duration, enable = GetActionCooldown(meilleureAction)
		if (Ovale.maintenant + minAttente > start + duration + 0.01 and minAttente > 0
			and minAttente>Ovale.attenteFinCast) then
			self.icone:SetVertexColor(0.75,0,0)
		else
			self.icone:SetVertexColor(1,1,1)
		end 
		
		if (minAttente==0) then
			self.cd:Hide()
		end
		
		-- Le temps restant
		if (Ovale.db.profile.apparence.numeric) then
			self.remains:SetText(string.format("%.1f", minAttente))
			self.remains:Show()
		else
			self.remains:Hide()
		end
		
		-- Le raccourcis clavier 
		if (Ovale.db.profile.apparence.raccourcis) then
			self.shortcut:Show()
			self.shortcut:SetText(Ovale.shortCut[meilleureAction])
		else
			self.shortcut:Hide()
		end
		
		-- L'indicateur de portée
		self.aPortee:Show()
		if (IsActionInRange(meilleureAction,"target")==1) then
			self.aPortee:SetVertexColor(0.6,0.6,0.6)
			self.aPortee:Show()
		elseif (IsActionInRange(meilleureAction,"target")==0) then
			self.aPortee:SetVertexColor(1.0,0.1,0.1)
			self.aPortee:Show()
		else
			self.aPortee:Hide()
		end
	else
		self.icone:Hide()
		self.aPortee:Hide()
		self.shortcut:Hide()
		self.remains:Hide()
	end
end

local function SetSkinGroup(self, _skinGroup)
	Ovale:Print("SetSkinGroup")
	self.skinGroup = _skinGroup
	self.skinGroup:AddButton(self)
end

function OvaleIcone_OnClick(self)
	Ovale:ToggleOptions()
	self:SetChecked(0)
end

function OvaleIcone_OnLoad(self)
	local name = self:GetName()
	self.icone = _G[name.."Icon"]
	self.shortcut = _G[name.."HotKey"]
	self.remains = _G[name.."Name"]
	self.aPortee = _G[name.."Count"]
	self.aPortee:SetText(RANGE_INDICATOR)
	self.cd = _G[name.."Cooldown"]
	self.normalTexture = _G[name.."NormalTexture"]
	
	self:RegisterForClicks("LeftButtonUp")
	self.SetSkinGroup = SetSkinGroup
	self.UpdateSkin = UpdateSkin
end
