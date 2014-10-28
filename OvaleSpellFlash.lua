--[[--------------------------------------------------------------------
    Copyright (C) 2014 Johnny C. Lam.
    See the file LICENSE.txt for copying permission.
--]]--------------------------------------------------------------------

local OVALE, Ovale = ...
local OvaleSpellFlash = Ovale:NewModule("OvaleSpellFlash", "AceEvent-3.0")
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

-- Flash colors.
local colorMain = {}
local colorShortCd = {}
local colorCd = {}
local colorInterrupt = {}
local FLASH_COLOR = {
	main = colorMain,
	cd = colorCd,
	shortcd = colorCd,
}
local COLORTABLE = {
	aqua	= { r = 0, g = 1, b = 1 },
	blue	= { r = 0, g = 0, b = 1 },
	gray	= { r = 0.5, g = 0.5, b = 0.5 },
	green	= { r = 0.1, g = 1, b = 0.1 },
	orange	= { r = 1, g = 0.5, b = 0.25 },
	pink	= { r = 0.9, g = 0.4, b = 0.4 },
	purple	= { r = 1, g = 0, b = 1 },
	red		= { r = 1, g = 0.1, b = 0.1 },
	white	= { r = 1, g = 1, b = 1 },
	yellow	= { r = 1, g = 1, b = 0 },
}
--</private-static-properties>

--<public-static-methods>
function OvaleSpellFlash:OnInitialize()
	-- Resolve module dependencies.
	OvaleData = Ovale.OvaleData
end

function OvaleSpellFlash:OnEnable()
	SpellFlashCore = _G["SpellFlashCore"]
	self:RegisterMessage("Ovale_OptionChanged")
	self:Ovale_OptionChanged()
end

function OvaleSpellFlash:OnDisable()
	SpellFlashCore = _G["SpellFlashCore"]
	self:UnregisterMessage("Ovale_OptionChanged")
end

function OvaleSpellFlash:Ovale_OptionChanged()
	local db = Ovale.db.profile.apparence.spellFlash
	-- Main attack.
	colorMain.r = db.colorMain.r
	colorMain.g = db.colorMain.g
	colorMain.b = db.colorMain.b
	-- Long cooldown abilities.
	colorCd.r = db.colorCd.r
	colorCd.g = db.colorCd.g
	colorCd.b = db.colorCd.b
	-- Short cooldown abilities.
	colorShortCd.r = db.colorShortCd.r
	colorShortCd.g = db.colorShortCd.g
	colorShortCd.b = db.colorShortCd.b
	-- Interrupts.
	colorInterrupt.r = db.colorInterrupt.r
	colorInterrupt.g = db.colorInterrupt.g
	colorInterrupt.b = db.colorInterrupt.b
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
			-- SpellInfo data if the action is a spell.
			local si
			if element.lowername == "spell" then
				local spellId = element.params[1]
				si = OvaleData.spellInfo[spellId]
			end
			-- SpellFlash settings.
			local db = Ovale.db.profile.apparence.spellFlash

			-- Flash color.
			local color = COLORTABLE["white"]
			local flash = element.params and element.params.flash
			local iconFlash = node.params.flash
			local iconHelp = node.params.help
			if flash and COLORTABLE[flash] then
				-- Highest priority is known flash color set in the action parameters.
				color = COLORTABLE[flash]
			elseif iconFlash and COLORTABLE[iconFlash] then
				-- Next highest priority is known flash color set in the icon parameters.
				color = COLORTABLE[iconFlash]
			elseif iconHelp and FLASH_COLOR[iconHelp] then
				-- Fall back to color based on the help set in the icon parameters.
				color = FLASH_COLOR[iconHelp]
				-- Adjust color if it's a "cd" ability that is showing an interrupt.
				if si and si.interrupt == 1 and iconHelp == "cd" then
					color = colorInterrupt
				end
			end

			-- Flash size (percent).
			local size = db.size * 100
			if iconHelp == "cd" then
				-- Adjust to half size for "cd" abilities.
				if not (si and si.interrupt == 1) then
					size = size * 0.5
				end
			end

			-- Flash brightness (percent).
			local brightness = db.brightness * 100

			if element.lowername == "spell" then
				local spellId = element.params[1]
				if si and si.to_stance then
					SpellFlashCore.FlashForm(spellId, color, size, brightness)
				end
				SpellFlashCore.FlashAction(spellId, color, size, brightness)
			elseif element.lowername == "item" then
				-- Item ID.
				local itemId = element.params[1]
				SpellFlashCore.FlashItem(itemId, color, size, brightness)
			end
		end
	end
end
--</public-static-methods>
