-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

-- Functions
local date = _G.date
local error = _G.error
local type = _G.type

-- Libraries
local table = _G.table

-----------------------------------------------------------------------
-- Library namespace.
-----------------------------------------------------------------------
local LibStub = _G.LibStub
local MAJOR = "LibTextDump-1.0"

_G.assert(LibStub, MAJOR .. " requires LibStub")

local MINOR = 2 -- Should be manually increased
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then
	return
end -- No upgrade needed

-----------------------------------------------------------------------
-- Migrations.
-----------------------------------------------------------------------
lib.prototype = lib.prototype or {}
lib.metatable = lib.metatable or { __index = lib.prototype }

lib.buffers = lib.buffers or {}
lib.frames = lib.frames or {}

lib.num_frames = lib.num_frames or 0

-----------------------------------------------------------------------
-- Constants and upvalues.
-----------------------------------------------------------------------
local prototype = lib.prototype
local metatable = lib.metatable

local buffers = lib.buffers
local frames = lib.frames

local METHOD_USAGE_FORMAT = MAJOR .. ":%s() - %s."

local DEFAULT_FRAME_WIDTH = 750
local DEFAULT_FRAME_HEIGHT = 600

-----------------------------------------------------------------------
-- Helper functions.
-----------------------------------------------------------------------
local function CreateBorder(parent, width, height, left, right, top, bottom)
	local border = parent:CreateTexture(nil, "BORDER")
	border:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Border]])
	border:SetWidth(width)
	border:SetHeight(height)
	border:SetTexCoord(left, right, top, bottom)

	return border
end

local function NewInstance(width, height)
	lib.num_frames = lib.num_frames + 1

	local frameName = ("%s_CopyFrame%d"):format(MAJOR, lib.num_frames)
	local copyFrame = _G.CreateFrame("Frame", frameName, _G.UIParent)
	copyFrame:SetSize(width, height)
	copyFrame:SetPoint("CENTER", _G.UIParent, "CENTER")
	copyFrame:SetFrameStrata("DIALOG")
	copyFrame:EnableMouse(true)
	copyFrame:SetMovable(true)

	table.insert(_G.UISpecialFrames, frameName)
	_G.HideUIPanel(copyFrame)

	local titleBackground = copyFrame:CreateTexture(nil, "BACKGROUND")
	titleBackground:SetTexture([[Interface\PaperDollInfoFrame\UI-GearManager-Title-Background]])
	titleBackground:SetPoint("TOPLEFT", 9, -6)
	titleBackground:SetPoint("BOTTOMRIGHT", copyFrame, "TOPRIGHT", -28, -24)

	local dialogBackground = copyFrame:CreateTexture(nil, "BACKGROUND")
	dialogBackground:SetTexture([[Interface\Tooltips\UI-Tooltip-Background]])
	dialogBackground:SetVertexColor(0, 0, 0, 0.75)
	dialogBackground:SetPoint("TOPLEFT", 8, -24)
	dialogBackground:SetPoint("BOTTOMRIGHT", -6, 8)

	local topLeftBorder = CreateBorder(copyFrame, 64, 64, 0.501953125, 0.625, 0, 1)
	topLeftBorder:SetPoint("TOPLEFT")

	local topRightBorder = CreateBorder(copyFrame, 64, 64, 0.625, 0.75, 0, 1)
	topRightBorder:SetPoint("TOPRIGHT")

	local topBorder = CreateBorder(copyFrame, 0, 64, 0.25, 0.369140625, 0, 1)
	topBorder:SetPoint("TOPLEFT", topLeftBorder, "TOPRIGHT", 0, 0)
	topBorder:SetPoint("TOPRIGHT", topRightBorder, "TOPLEFT", 0, 0)

	local bottomLeftBorder = CreateBorder(copyFrame, 64, 64, 0.751953125, 0.875, 0, 1)
	bottomLeftBorder:SetPoint("BOTTOMLEFT")

	local bottomRightBorder = CreateBorder(copyFrame, 64, 64, 0.875, 1, 0, 1)
	bottomRightBorder:SetPoint("BOTTOMRIGHT")

	local bottomBorder = CreateBorder(copyFrame, 0, 64, 0.37695312, 0.498046875, 0, 1)
	bottomBorder:SetPoint("BOTTOMLEFT", bottomLeftBorder, "BOTTOMRIGHT", 0, 0)
	bottomBorder:SetPoint("BOTTOMRIGHT", bottomRightBorder, "BOTTOMLEFT", 0, 0)

	local leftBorder = CreateBorder(copyFrame, 64, 0, 0.001953125, 0.125, 0, 1)
	leftBorder:SetPoint("TOPLEFT", topLeftBorder, "BOTTOMLEFT", 0, 0)
	leftBorder:SetPoint("BOTTOMLEFT", bottomLeftBorder, "TOPLEFT", 0, 0)

	local rightBorder = CreateBorder(copyFrame, 64, 0, 0.1171875, 0.2421875, 0, 1)
	rightBorder:SetPoint("TOPRIGHT", topRightBorder, "BOTTOMRIGHT", 0, 0)
	rightBorder:SetPoint("BOTTOMRIGHT", bottomRightBorder, "TOPRIGHT", 0, 0)

	local titleFontString = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	titleFontString:SetPoint("TOPLEFT", 12, -8)
	titleFontString:SetPoint("TOPRIGHT", -32, -8)

	copyFrame.title = titleFontString

	local dragFrame = _G.CreateFrame("Frame", nil, copyFrame)
	dragFrame:SetPoint("TOPLEFT", titleFontString)
	dragFrame:SetPoint("BOTTOMRIGHT", titleFontString)
	dragFrame:EnableMouse(true)

	dragFrame:SetScript("OnMouseDown", function(self, button)
		copyFrame:StartMoving()
	end)

	dragFrame:SetScript("OnMouseUp", function(self, button)
		copyFrame:StopMovingOrSizing()
	end)

	local closeButton = _G.CreateFrame("Button", nil, copyFrame, "UIPanelCloseButton")
	closeButton:SetSize(32, 32)
	closeButton:SetPoint("TOPRIGHT", 2, 1)

	local footerFrame = _G.CreateFrame("Frame", nil, copyFrame, "InsetFrameTemplate")
	footerFrame:SetHeight(23)
	footerFrame:SetPoint("BOTTOMLEFT", copyFrame, "BOTTOMLEFT", 8, 8)
	footerFrame:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -5, 8)

	local footerFontString = footerFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	footerFontString:SetPoint("CENTER", footerFrame, "CENTER", 0, 0)

	local scrollArea = _G.CreateFrame("ScrollFrame", ("%sScroll"):format(frameName), copyFrame, "UIPanelScrollFrameTemplate")
	scrollArea:SetPoint("TOPLEFT", copyFrame, "TOPLEFT", 10, -28)
	scrollArea:SetPoint("BOTTOMRIGHT", copyFrame, "BOTTOMRIGHT", -28, 31)

	scrollArea:SetScript("OnMouseWheel", function(self, delta)
		_G.ScrollFrameTemplate_OnMouseWheel(self, delta, self.ScrollBar)
	end)

	scrollArea.ScrollBar:SetScript("OnMouseWheel", function(self, delta)
		_G.ScrollFrameTemplate_OnMouseWheel(self, delta, self)
	end)

	local editBox = _G.CreateFrame("EditBox", nil, copyFrame)
	editBox:SetMultiLine(true)
	editBox:SetMaxLetters(0)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetFontObject("ChatFontNormal")
	editBox:SetSize(650, 270)

	editBox:SetScript("OnEscapePressed", function()
		_G.HideUIPanel(copyFrame)
	end)

	copyFrame.edit_box = editBox
	scrollArea:SetScrollChild(editBox)

	local highlightButton = _G.CreateFrame("Button", nil, copyFrame)
	highlightButton:SetSize(16, 16)
	highlightButton:SetPoint("BOTTOMRIGHT", -10, 10)

	highlightButton:SetScript("OnMouseUp", function(self, button)
		self.texture:ClearAllPoints()
		self.texture:SetAllPoints(self)

		editBox:HighlightText(0)
		editBox:SetFocus()
	end)

	highlightButton:SetScript("OnMouseDown", function(self, button)
		self.texture:ClearAllPoints()
		self.texture:SetPoint("RIGHT", self, "RIGHT", 1, -1)
	end)

	highlightButton:SetScript("OnEnter", function(self)
		self.texture:SetVertexColor(0.75, 0.75, 0.75)
	end)

	highlightButton:SetScript("OnLeave", function(self)
		self.texture:SetVertexColor(1, 1, 1)
	end)

	local highlightIcon = highlightButton:CreateTexture()
	highlightIcon:SetAllPoints()
	highlightIcon:SetTexture([[Interface\BUTTONS\UI-GuildButton-PublicNote-Up]])
	highlightButton.texture = highlightIcon

	local instance = _G.setmetatable({}, metatable)
	frames[instance] = copyFrame
	buffers[instance] = {}

	return instance
end


-----------------------------------------------------------------------
-- Library methods.
-----------------------------------------------------------------------
function lib:New(frameTitle, width, height)
	local titleType = type(frameTitle)

	if titleType ~= "nil" and titleType ~= "string" then
		error(METHOD_USAGE_FORMAT:format("New", "frame title must be nil or a string."), 2)
	end

	local widthType = type(width)

	if widthType ~= "nil" and widthType ~= "number" then
		error(METHOD_USAGE_FORMAT:format("New", "frame width must be nil or a number."))
	end

	local heightType = type(height)

	if heightType ~= "nil" and heightType ~= "number" then
		error(METHOD_USAGE_FORMAT:format("New", "frame height must be nil or a number."))
	end

	local instance = NewInstance(width or DEFAULT_FRAME_WIDTH, height or DEFAULT_FRAME_HEIGHT)
	frames[instance].title:SetText(frameTitle)

	return instance
end


-----------------------------------------------------------------------
-- Instance methods.
-----------------------------------------------------------------------
function prototype:AddLine(text, dateFormat)
	self:InsertLine(#buffers[self] + 1, text, dateFormat)

	if lib.frames[self]:IsVisible() then
		self:Display()
	end
end

function prototype:Clear()
	table.wipe(buffers[self])
end

function prototype:Display(separator)
	local display_text = self:String(separator)

	if display_text == "" then
		error(METHOD_USAGE_FORMAT:format("Display", "buffer must be non-empty"), 2)
	end
	local frame = frames[self]
	frame.edit_box:SetText(display_text)
	frame.edit_box:SetCursorPosition(0)
	_G.ShowUIPanel(frame)
end

function prototype:InsertLine(position, text, dateFormat)
	if type(position) ~= "number" then
		error(METHOD_USAGE_FORMAT:format("InsertLine", "position must be a number."))
	end

	if type(text) ~= "string" or text == "" then
		error(METHOD_USAGE_FORMAT:format("InsertLine", "text must be a non-empty string."), 2)
	end

	if dateFormat and dateFormat ~= "" then
		table.insert(buffers[self], position, ("[%s] %s"):format(date(dateFormat), text))
	else
		table.insert(buffers[self], position, text)
	end
end

function prototype:Lines()
	return #buffers[self]
end

function prototype:String(separator)
	local sep_type = type(separator)

	if sep_type ~= "nil" and sep_type ~= "string" then
		error(METHOD_USAGE_FORMAT:format("String", "separator must be nil or a string."), 2)
	end
	return table.concat(buffers[self], separator or "\n")
end
