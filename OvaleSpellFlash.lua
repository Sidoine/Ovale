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

function OvaleSpellFlash:Flash(node, element, start, now)
	if SpellFlashCore and start and start - now < FLASH_THRESHOLD then
		-- Check that element is an action.
		if element and element.type == "action" then
			-- Flash color.
			local color = DEFAULT_FLASH_COLOR
			local help = node.params.help
			if help and FLASH_COLOR[help] then
				color = FLASH_COLOR[help]
			end
			if element.lowername == "spell" then
				-- Spell ID.
				local spellId = element.params[1]
				-- Adjust color if it's a "cd" ability that is showing an interrupt.
				local si = OvaleData.spellInfo[spellId]
				if si and si.interrupt == 1 and help == "cd" then
					color = INTERRUPT_FLASH_COLOR
				end
				if si and si.to_stance then
					SpellFlashCore.FlashForm(spellId, color)
				else
					SpellFlashCore.FlashAction(spellId, color)
				end
			elseif element.lowername == "item" then
				-- Item ID.
				local itemId = element.params[1]
				SpellFlashCore.FlashItem(itemId, color)
			end
		end
	end
end
--</public-static-methods>
