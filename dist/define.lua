--[[ Methods used by the tstolua compiler ]]

local LibStub = LibStub
local ADDON_NAME, Addon = ...

if _G[ADDON_NAME] == nil then
  _G[ADDON_NAME] = Addon
end

local strsub = string.sub

-- Function used by define to call a factory that is ready
local function call(exports) 
    -- print("calling " .. exports.name)
    local parameters = {}
    local i = 1
    for _,v in ipairs(exports.imports) do
        -- print("   with " .. v.name)
        if v.exports == nil and not v.global then
          print("called but " .. v.name .. " has no export")
        end
        parameters[i] = v.exports
        i = i + 1
    end
    exports.exports = {}
    local result = exports.factory(exports.exports, unpack(parameters, 1, i))
    if result then
        exports.exports = result
    end

    -- If some modules were waiting for these modules,...
    if exports.wait then
        for _,v in ipairs(exports.wait) do
            print(v .. " is no more waiting for " .. exports.name)
            v.missing[exports.name] = nil
            -- This module is waiting for nothing, call the factory
            if not next(v.missing) and v.imports then
                call(v)
            end
        end
    end
end 

local addonlist = {}

-- Used by the AMD-like module system
Addon.require = function(mod, dependencies, factory)
    local exports

    -- print("Define " .. mod)

    if not Addon[mod] then
      exports = { missing = {}, name = mod, defined = true }
      Addon[mod] = exports
      addonlist[#addonlist + 1] = exports
    else
      exports = Addon[mod]
      exports.defined = true
    end

    exports.factory = factory
    
    local imports = {}

    -- Check dependencies
    for _,v in ipairs(dependencies) do
      local dependency = Addon[v]
      -- Dependency not found, register it 
      if not dependency then
        if strsub(v, 1, 1) ~= "." then
          -- It's a global dependency
        -- print("add global " .. v)
          dependency = { exports =  LibStub and LibStub.libs[v], name = v, missing = {}, defined = true, global = true }
        else
          -- Create the dependency, empty for now
          -- Register the fact that this module is waiting for this dependency
          -- print("Local " .. v)
          dependency = { wait = { exports }, name = v, missing = {}, defined = false }
          exports.missing[v] = dependency
        end
        Addon[v] = dependency 
      else
        if (not dependency.defined) or next(dependency.missing) then
          -- print(v .. " is not ready")
          if dependency.wait then
            dependency.wait[#dependency.wait + 1] = exports
          else
            dependency.wait = { exports }
          end
          exports.missing[v] = dependency
        end
      end
      imports[#imports + 1] = dependency
    end

    exports.imports = imports
    
    -- -- If missing nothing, call the factory
    -- if not next(exports.missing) then
    --   call(exports)
    -- else
    --   print(mod .. " has some missing dep")
    -- end    
end

-- Wait for ADDON_LOADED event to initialize the modules
local frame = CreateFrame("FRAME", ADDON_NAME .. "AddonFrame");
frame:RegisterEvent("ADDON_LOADED");
local function eventHandler(self, event, addon)
  if addon ~= ADDON_NAME then return end
  for k, v in ipairs(addonlist) do 
    call(v)
  end
end
frame:SetScript("OnEvent", eventHandler);

Addon.__class = function(base, prototype) 
  local class = prototype
  if base then
    if not base.constructor then base.constructor = function() end end
  else
    if not class.constructor then class.constructor = function()  end end
  end
  class.__index = class
  setmetatable(class, {
    __index = base,
    __call = function(cls, ...)
      local self = setmetatable({}, cls)
      self:constructor(...)
      return self
    end
  })
  return class
end

-- Emulate switch
-- __switch_return_break = 1
-- __switch_return_return = 2
-- switch = function(t)
-- 	t.case = function (self,x)
-- 		local startfunid = self[x] or self.default
-- 		if startfunid == nil then
-- 			return
-- 		end		
-- 		local len = #self.__codesegments
-- 		for fid=startfunid, len do
-- 			local f = self.__codesegments[fid]
-- 			if f ~= 0 then
-- 				local rtflag, rt = f(x, self)
-- 				if rtflag ~= nil then
-- 					return rtflag, rt 
-- 				end
-- 			end
-- 		end
-- 	end;
-- 	return t
-- end

function AceGUIRegisterAsContainer(widget)
		widget.children = {}
		widget.userdata = {}
		widget.events = {}
		widget.base = WidgetContainerBase
		widget.content.obj = widget
		widget.frame.obj = widget
		widget.content:SetScript("OnSizeChanged", ContentResize)
		widget.frame:SetScript("OnSizeChanged", FrameResize)
		widget:SetLayout("List")
	end
	
function AceGUIRegisterAsWidget(widget)
		widget.userdata = {}
		widget.events = {}
		widget.base = WidgetBase
		widget.frame.obj = widget
		widget.frame:SetScript("OnSizeChanged", FrameResize)
		return widget
end