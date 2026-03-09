local Addon, ns = ...
local API = ns.API or {}
ns.API = API

-- Lua API
local next = next
local tonumber = tonumber

-- WoW Objects
local UIParent = UIParent

-- Cache
local Scaled = {}
local ScaledToUIParent = {}
local MinimapScaled = {}
local UnitFramesScaled = {}
local TargetFrameScaled = {}
local EditModeUFScaled = {}
local EditModeMinimapScaled = {}

-- Scaling Functions
---------------------------------------------------------
-- Get the scale to set when ignoring parent scale
API.GetScale = function()
	return ns.UIScale
end

-- Return the default scale
API.GetDefaultScale = function()
	return ns.UIDefaultScale
end

-- Get the scale to use when slaved to UIParent
API.GetEffectiveScale = function()
	return API.GetScale() * 1/UIParent:GetScale()
end

-- Set the scale
API.SetScale = function(scale)
	ns.UIScale = tonumber(scale) or API.GetDefaultScale()
end

-- Set the scale as a factor of the default scale
API.SetRelativeScale = function(scale)
	ns.UIScale = (tonumber(scale) or 1) * API.GetDefaultScale()
end

-- Get minimap scale
API.GetMinimapScale = function()
	return ns.MinimapScale or ns.UIScale
end

-- Set minimap scale as a factor of the default scale
API.SetMinimapRelativeScale = function(scale)
	ns.MinimapScale = (tonumber(scale) or 1) * API.GetDefaultScale()
end

-- Get unitframes scale
API.GetUnitFramesScale = function()
	return ns.UnitFramesScale or ns.UIScale
end

-- Set unitframes scale as a factor of the default scale
API.SetUnitFramesRelativeScale = function(scale)
	ns.UnitFramesScale = (tonumber(scale) or 1) * API.GetDefaultScale()
end

-- Register an object to follow the main UIScale
-- *Optional second input is a scaling factor.
-- *Passes the input value as return value,
--  thus allowing method chaining.
API.SetObjectScale = function(object, factor)
	if (object and object.SetScale) then
		Scaled[object] = factor or 1
		object:SetIgnoreParentScale(true)
		object:SetScale(API.GetScale() * (factor or 1))
	end
	return object
end

API.SetEffectiveObjectScale = function(object, factor)
	if (object and object.SetScale) then
		ScaledToUIParent[object] = factor or 1
		object:SetIgnoreParentScale(true)
		object:SetScale(API.GetEffectiveScale() * (factor or 1))
	end
	return object
end

-- Register minimap object to follow minimap scale
API.SetMinimapObjectScale = function(object, factor)
	if (object and object.SetScale) then
		MinimapScaled[object] = factor or 1
		object:SetIgnoreParentScale(true)
		object:SetScale(API.GetMinimapScale() * (factor or 1))
	end
	return object
end

-- Register unitframes object to follow unitframes scale
API.SetUnitFramesObjectScale = function(object, factor)
	if (object and object.SetScale) then
		UnitFramesScaled[object] = factor or 1
		object:SetIgnoreParentScale(true)
		object:SetScale(API.GetUnitFramesScale() * (factor or 1))
	end
	return object
end

-- EditMode-compatible scaling (without SetIgnoreParentScale)
-- Used for frames registered with LibEditMode
API.SetEditModeObjectScale = function(object, factor)
	if (object and object.SetScale) then
		Scaled[object] = nil
		UnitFramesScaled[object] = nil
		EditModeUFScaled[object] = nil
		TargetFrameScaled[object] = factor or 1
		object:SetIgnoreParentScale(false)
		object:SetScale(API.GetEffectiveScale() * (factor or 1))
	end
	return object
end
API.SetTargetFrameObjectScale = API.SetEditModeObjectScale
-- EditMode-compatible scaling based on UnitFramesScale
-- Same visual size as SetUnitFramesObjectScale but without SetIgnoreParentScale
API.GetUnitFramesEffectiveScale = function()
	return API.GetUnitFramesScale() * 1/UIParent:GetScale()
end
-- EditMode-compatible scaling based on MinimapScale
API.GetMinimapEffectiveScale = function()
	return API.GetMinimapScale() * 1/UIParent:GetScale()
end
API.SetEditModeMinimapObjectScale = function(object, factor)
	if (object and object.SetScale) then
		MinimapScaled[object] = nil
		EditModeMinimapScaled[object] = factor or 1
		object:SetIgnoreParentScale(false)
		object:SetScale(API.GetMinimapEffectiveScale() * (factor or 1))
	end
	return object
end
API.SetEditModeUFObjectScale = function(object, factor)
	if (object and object.SetScale) then
		Scaled[object] = nil
		UnitFramesScaled[object] = nil
		TargetFrameScaled[object] = nil
		EditModeUFScaled[object] = factor or 1
		object:SetIgnoreParentScale(false)
		object:SetScale(API.GetUnitFramesEffectiveScale() * (factor or 1))
	end
	return object
end

-- Updates the scale of all objects
-- registered with the above commands.
API.UpdateObjectScales = function()
	-- Update independent objects
	local scale = API.GetScale()
	for object, factor in next,Scaled do
		object:SetIgnoreParentScale(true)
		object:SetScale(scale * factor)
	end
	-- Update frames that can't ignore parent scales
	local effectiveScale = API.GetEffectiveScale()
	for object, factor in next,ScaledToUIParent do
		object:SetScale(effectiveScale * factor)
	end
	-- Update minimap objects
	local minimapScale = API.GetMinimapScale()
	for object, factor in next,MinimapScaled do
		object:SetIgnoreParentScale(true)
		object:SetScale(minimapScale * factor)
	end
	-- Update unitframes objects
	local unitframesScale = API.GetUnitFramesScale()
	for object, factor in next,UnitFramesScaled do
		object:SetIgnoreParentScale(true)
		object:SetScale(unitframesScale * factor)
	end
	-- Update EditMode minimap objects
	local minimapEffective = API.GetMinimapEffectiveScale()
	for object, factor in next,EditModeMinimapScaled do
		object:SetIgnoreParentScale(false)
		object:SetScale(minimapEffective * factor)
	end
	-- Update EditMode UnitFrames objects (PetBar etc.)
	-- Same visual as UnitFramesScaled but without SetIgnoreParentScale for LibEditMode
	local ufEffectiveScale = API.GetUnitFramesEffectiveScale()
	for object, factor in next,EditModeUFScaled do
		object:SetIgnoreParentScale(false)
		object:SetScale(ufEffectiveScale * factor)
	end
	-- Update target frame objects (independent from unitframes scale)
	-- Uses effective scale (without SetIgnoreParentScale) for LibEditMode compatibility
	local targetScale = API.GetEffectiveScale()
	for object, factor in next,TargetFrameScaled do
		object:SetIgnoreParentScale(false)
		object:SetScale(targetScale * factor)
	end
end
