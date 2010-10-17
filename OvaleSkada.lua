local Skada = Skada

if Skada then
	local module = Skada:NewModule("Ovale Spell Priority")

	local function getValue(set)
		if set.ovaleMax and set.ovaleMax>0 then
			return math.floor(1000*set.ovale/set.ovaleMax)
		else
			return nil
		end
	end

	function module:Update(win, set)
		local max = 0
		local nr = 1
		
		for i, player in ipairs(set.players) do
			if player.ovaleMax > 0 then
			
				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.value = getValue(player)
				d.label = player.name
				d.class = player.class
				d.id = player.id
				d.valuetext = tostring(getValue(player))
				if d.value > max then
					max = d.value
				end
				nr = nr + 1
			end
		end
		
		win.metadata.maxvalue = max
	end

	function module:OnEnable()
		module.metadata = {showspots = true}
		
		Skada:AddMode(self)
	end

	function module:OnDisable()
		Skada:RemoveMode(self)
	end

	function module:AddToTooltip(set, tooltip)
		GameTooltip:AddDoubleLine("Ovale", getValue(set), 1,1,1)
	end

	-- Called by Skada when a new player is added to a set.
	function module:AddPlayerAttributes(player)
		if not player.ovale then
			player.ovale = 0
		end
		if not player.ovaleMax then
			player.ovaleMax = 0
		end
	end

	-- Called by Skada when a new set is created.
	function module:AddSetAttributes(set)
		if not set.ovale then
			set.ovale = 0
		end
		if not set.ovaleMax then
			set.ovaleMax = 0
		end
	end

	function module:GetSetSummary(set)
		return getValue(set)
	end
end