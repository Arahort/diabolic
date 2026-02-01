local Addon, ns = ...
local ActionBars = ns:NewModule("ActionBars", "LibMoreEvents-1.0")

---------------------------------------------
-- Proxy Calls
---------------------------------------------
-- Returns 'true' if the secondary bar is currently visible.
ActionBars.HasSecondaryBar = function(self)
	local Bars = self:GetModule("Bars", true)
	return Bars and Bars:HasSecondaryBar()
end

-- Returns the secondary action bar.
ActionBars.GetSecondaryBar = function(self)
	local Bars = self:GetModule("Bars", true)
	return Bars and Bars:GetSecondaryBar()
end

-- Returns the currently valid vertical offset
-- for items positioned above the action bars.
ActionBars.GetBarOffset = function(self)
	local Bars = self:GetModule("Bars", true)
	return Bars and Bars:GetBarOffset()
end

-- Returns the value used in the GetBarOffset
-- when the secondary bar is visible.
ActionBars.GetSecondaryBarOffset = function(self)
	local Bars = self:GetModule("Bars", true)
	return Bars and Bars:GetSecondaryBarOffset()
end

-- Returns 'true' if the third bar is currently visible.
ActionBars.HasThirdBar = function(self)
	local Bars = self:GetModule("Bars", true)
	return Bars and Bars:HasThirdBar()
end

-- Returns the third action bar.
ActionBars.GetThirdBar = function(self)
	local Bars = self:GetModule("Bars", true)
	return Bars and Bars:GetThirdBar()
end

-- Returns the value used in the GetBarOffset
-- when the third bar is visible.
ActionBars.GetThirdBarOffset = function(self)
	local Bars = self:GetModule("Bars", true)
	return Bars and Bars:GetThirdBarOffset()
end
