--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleSpellFlash = Ovale:NewModule("OvaleSpellFlash")
Ovale.OvaleSpellFlash = OvaleSpellFlash

--<private-static-properties>
-- Forward declarations for module dependencies.
local OvaleData = nil

local API_UnitHasVehicleUI = UnitHasVehicleUI
local API_UnitExists = UnitExists
local API_UnitIsDead = UnitIsDead
local API_UnitCanAttack = UnitCanAttack

-- Local reference to SpellFlashCore addon.
local SpellFlashCore = nil

-- Time in seconds to start flashing the spell to use before it is ready.
local FLASH_THRESHOLD = 0.5
-- Table mapping icon "help" text to the flash color.
local FLASH_COLOR = {
	main = "white",
	cd = "yellow",
	shortcd = "yellow"
}
-- Default flash color if no help text is found.
local DEFAULT_FLASH_COLOR = "white"
-- Flash color for an interrupt ability.
local INTERRUPT_FLASH_COLOR = "aqua"
--</private-static-properties>

--<public-static-methods>
function OvaleSpellFlash:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
end

function OvaleSpellFlash:OnEnable()
	SpellFlashCore = _G["SpellFlashCore"]
end

function OvaleSpellFlash:IsSpellFlashEnabled()
	local enabled = (SpellFlashCore ~= nil)
	local db = Ovale.db.profile.apparence.spellFlash
	if enabled and not db.enabled then
		enabled = false
	end
	if enabled and db.inCombat and not Ovale.enCombat then
		enabled = false
	end
	if enabled and db.hideInVehicle and API_UnitHasVehicleUI("player") then
		enabled = false
	end
	if enabled and db.hasTarget and not API_UnitExists("target") then
		enabled = false
	end
	if enabled and db.hasHostileTarget and (API_UnitIsDead("target") or not API_UnitCanAttack("player", "target")) then
		enabled = false
	end
	return enabled
end

function OvaleSpellFlash:Flash(node, element, start, now)
	if self:IsSpellFlashEnabled() and start and start - now < FLASH_THRESHOLD then
		-- Check that element is an action.
		if element and element.type == "action" then
			-- Flash color.
			local color = DEFAULT_FLASH_COLOR
			local help = node.params.help
			if help and FLASH_COLOR[help] then
				color = FLASH_COLOR[help]
			end
			local db = Ovale.db.profile.apparence.spellFlash
			-- Flash size (percent).
			local size = db.size * 100
			-- Flash brightness (percent).
			local brightness = db.brightness * 100
			if element.lowername == "spell" then
				-- Spell ID.
				local spellId = element.params[1]
				-- Adjust color if it's a "cd" ability that is showing an interrupt.
				local si = OvaleData.spellInfo[spellId]
				if si and si.interrupt == 1 and help == "cd" then
					color = INTERRUPT_FLASH_COLOR
				end
				if si and si.to_stance then
					SpellFlashCore.FlashForm(spellId, color, size, brightness)
				else
					SpellFlashCore.FlashAction(spellId, color, size, brightness)
				end
			elseif element.lowername == "item" then
				-- Item ID.
				local itemId = element.params[1]
				SpellFlashCore.FlashItem(itemId, color, size, brightness)
			end
		end
	end
end
--</public-static-methods>
