local Addon, ns = ...
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end
-- FocusTarget frame uses the exact same visual as Party frames.
if (UnitStyles["Party"]) then
	UnitStyles["FocusTarget"] = UnitStyles["Party"]
end
