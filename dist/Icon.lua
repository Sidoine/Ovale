local __exports = LibStub:NewLibrary("ovale/Icon", 80000)
if not __exports then return end
local __class = LibStub:GetLibrary("tslib").newClass
local __Localization = LibStub:GetLibrary("ovale/Localization")
local L = __Localization.L
local __SpellBook = LibStub:GetLibrary("ovale/SpellBook")
local OvaleSpellBook = __SpellBook.OvaleSpellBook
local __Ovale = LibStub:GetLibrary("ovale/Ovale")
local Ovale = __Ovale.Ovale
local format = string.format
local find = string.find
local sub = string.sub
local next = next
local pairs = pairs
local tostring = tostring
local _G = _G
local GetTime = GetTime
local PlaySoundFile = PlaySoundFile
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local huge = math.huge
local INFINITY = huge
local COOLDOWN_THRESHOLD = 0.1
__exports.OvaleIcon = __class(nil, {
    HasScriptControls = function(self)
        return (next(self.parent.checkBoxWidget) ~= nil or next(self.parent.listWidget) ~= nil)
    end,
    constructor = function(self, name, parent, secure)
        self.name = name
        self.parent = parent
        if  not secure then
            self.frame = CreateFrame("CheckButton", name, parent.frame, "ActionButtonTemplate")
        else
            self.frame = CreateFrame("CheckButton", name, parent.frame, "SecureActionButtonTemplate, ActionButtonTemplate")
        end
        self:OvaleIcon_OnLoad()
    end,
    SetValue = function(self, value, actionTexture)
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
        self.frame:Show()
    end,
    Update = function(self, element, startTime, actionTexture, actionInRange, actionCooldownStart, actionCooldownDuration, actionUsable, actionShortcut, actionIsCurrent, actionEnable, actionType, actionId, actionTarget, actionResourceExtend)
        self.actionType = actionType
        self.actionId = actionId
        self.value = nil
        local now = GetTime()
        local profile = Ovale.db.profile
        if startTime and actionTexture then
            local cd = self.cd
            local resetCooldown = false
            if startTime > now then
                local duration = cd:GetCooldownDuration()
                if duration == 0 and self.texture == actionTexture and self.cooldownStart and self.cooldownEnd then
                    resetCooldown = true
                end
                if self.texture ~= actionTexture or  not self.cooldownStart or  not self.cooldownEnd then
                    self.cooldownStart = now
                    self.cooldownEnd = startTime
                    resetCooldown = true
                elseif startTime < self.cooldownEnd - COOLDOWN_THRESHOLD or startTime > self.cooldownEnd + COOLDOWN_THRESHOLD then
                    if startTime - self.cooldownEnd > 0.25 or startTime - self.cooldownEnd < -0.25 then
                        self.cooldownStart = now
                    else
                        local oldCooldownProgressPercent = (now - self.cooldownStart) / (self.cooldownEnd - self.cooldownStart)
                        self.cooldownStart = (now - oldCooldownProgressPercent * startTime) / (1 - oldCooldownProgressPercent)
                    end
                    self.cooldownEnd = startTime
                    resetCooldown = true
                end
                self.texture = actionTexture
            else
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
            self.icone:Show()
            self.icone:SetTexture(actionTexture)
            if actionUsable then
                self.icone:SetAlpha(1)
            else
                self.icone:SetAlpha(0.5)
            end
            if element.namedParams.nored ~= 1 and actionResourceExtend and actionResourceExtend > 0 then
                self.icone:SetVertexColor(0.75, 0.2, 0.2)
            else
                self.icone:SetVertexColor(1, 1, 1)
            end
            self.actionHelp = element.namedParams.help
            if  not (self.cooldownStart and self.cooldownEnd) then
                self.lastSound = nil
            end
            if element.namedParams.sound and  not self.lastSound then
                local delay = element.namedParams.soundtime or 0.5
                if now >= startTime - delay then
                    self.lastSound = element.namedParams.sound
                    PlaySoundFile(self.lastSound)
                end
            end
            local red = false
            if  not red and startTime > now and profile.apparence.highlightIcon then
                local lag = 0.6
                local newShouldClick = (startTime < now + lag)
                if self.shouldClick ~= newShouldClick then
                    if newShouldClick then
                        self.frame:SetChecked(true)
                    else
                        self.frame:SetChecked(false)
                    end
                    self.shouldClick = newShouldClick
                end
            elseif self.shouldClick then
                self.shouldClick = false
                self.frame:SetChecked(false)
            end
            if (profile.apparence.numeric or self.namedParams.text == "always") and startTime > now then
                self.remains:SetFormattedText("%.1f", startTime - now)
                self.remains:Show()
            else
                self.remains:Hide()
            end
            if profile.apparence.raccourcis then
                self.shortcut:Show()
                self.shortcut:SetText(actionShortcut)
            else
                self.shortcut:Hide()
            end
            if actionInRange == 1 then
                self.rangeIndicator:SetVertexColor(0.6, 0.6, 0.6)
                self.rangeIndicator:Show()
            elseif actionInRange == 0 then
                self.rangeIndicator:SetVertexColor(1, 0.1, 0.1)
                self.rangeIndicator:Show()
            else
                self.rangeIndicator:Hide()
            end
            if element.namedParams.text then
                self.focusText:SetText(tostring(element.namedParams.text))
                self.focusText:Show()
            elseif actionTarget and actionTarget ~= "target" then
                self.focusText:SetText(actionTarget)
                self.focusText:Show()
            else
                self.focusText:Hide()
            end
            self.frame:Show()
        else
            self.icone:Hide()
            self.rangeIndicator:Hide()
            self.shortcut:Hide()
            self.remains:Hide()
            self.focusText:Hide()
            if profile.apparence.hideEmpty then
                self.frame:Hide()
            else
                self.frame:Show()
            end
            if self.shouldClick then
                self.frame:SetChecked(false)
                self.shouldClick = false
            end
        end
        return startTime, element
    end,
    SetHelp = function(self, help)
        self.help = help
    end,
    SetParams = function(self, positionalParams, namedParams, secure)
        self.positionalParams = positionalParams
        self.namedParams = namedParams
        self.actionButton = false
        if secure then
            for k, v in pairs(namedParams) do
                local index = find(k, "spell")
                if index then
                    local prefix = sub(k, 1, index - 1)
                    local suffix = sub(k, index + 5)
                    self.frame:SetAttribute(prefix .. "type" .. suffix, "spell")
                    self.frame:SetAttribute("unit", self.namedParams.target or "target")
                    self.frame:SetAttribute(k, OvaleSpellBook:GetSpellName(v))
                    self.actionButton = true
                end
            end
        end
    end,
    SetRemainsFont = function(self, color)
        self.remains:SetTextColor(color.r, color.g, color.b, 1)
        self.remains:SetJustifyH("left")
        self.remains:SetPoint("BOTTOMLEFT", 2, 2)
    end,
    SetFontScale = function(self, scale)
        self.fontScale = scale
        self.remains:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
        self.shortcut:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
        self.rangeIndicator:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
        self.focusText:SetFont(self.fontName, self.fontHeight * self.fontScale, self.fontFlags)
    end,
    SetRangeIndicator = function(self, text)
        self.rangeIndicator:SetText(text)
    end,
    OvaleIcon_OnMouseUp = function(self)
        if  not self.actionButton then
            self.parent:ToggleOptions()
        end
        self.frame:SetChecked(true)
    end,
    OvaleIcon_OnEnter = function(self)
        if self.help or self.actionType or self:HasScriptControls() then
            GameTooltip:SetOwner(self.frame, "ANCHOR_BOTTOMLEFT")
            if self.help then
                GameTooltip:SetText(L[self.help])
            end
            if self.actionType then
                local actionHelp = self.actionHelp
                if  not actionHelp then
                    if self.actionType == "spell" then
                        actionHelp = OvaleSpellBook:GetSpellName(self.actionId)
                    elseif self.actionType == "value" then
                        actionHelp = (self.value < INFINITY) and tostring(self.value) or "infinity"
                    else
                        actionHelp = format("%s %s", self.actionType, tostring(self.actionId))
                    end
                end
                GameTooltip:AddLine(actionHelp, 0.5, 1, 0.75)
            end
            if self:HasScriptControls() then
                GameTooltip:AddLine(L["Cliquer pour afficher/cacher les options"], 1, 1, 1)
            end
            GameTooltip:Show()
        end
    end,
    OvaleIcon_OnLeave = function(self)
        if self.help or self:HasScriptControls() then
            GameTooltip:Hide()
        end
    end,
    OvaleIcon_OnLoad = function(self)
        local name = self.name
        local profile = Ovale.db.profile
        self.icone = _G[name .. "Icon"]
        self.shortcut = _G[name .. "HotKey"]
        self.remains = _G[name .. "Name"]
        self.rangeIndicator = _G[name .. "Count"]
        self.rangeIndicator:SetText(profile.apparence.targetText)
        self.cd = _G[name .. "Cooldown"]
        self.normalTexture = _G[name .. "NormalTexture"]
        local fontName, fontHeight, fontFlags = self.shortcut:GetFont()
        self.fontName = fontName
        self.fontHeight = fontHeight
        self.fontFlags = fontFlags
        self.focusText = self.frame:CreateFontString(nil, "OVERLAY")
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
        self.frame:SetScript("OnMouseUp", function()
            return self:OvaleIcon_OnMouseUp()
        end)
        self.frame:SetScript("OnEnter", function()
            return self:OvaleIcon_OnEnter()
        end)
        self.frame:SetScript("OnLeave", function()
            return self:OvaleIcon_OnLeave()
        end)
        self.focusText:SetFontObject("GameFontNormalSmall")
        self.focusText:SetAllPoints(self.frame)
        self.focusText:SetTextColor(1, 1, 1)
        self.focusText:SetText(L["Focus"])
        self.frame:RegisterForClicks("AnyUp")
        if profile.apparence.clickThru then
            self.frame:EnableMouse(false)
        end
    end,
    SetPoint = function(self, anchor, reference, refAnchor, x, y)
        self.frame:SetPoint(anchor, reference, refAnchor, x, y)
    end,
    Show = function(self)
        self.frame:Show()
    end,
    Hide = function(self)
        self.frame:Hide()
    end,
    SetScale = function(self, scale)
        self.frame:SetScale(scale)
    end,
    EnableMouse = function(self, enabled)
        self.frame:EnableMouse(enabled)
    end,
})
