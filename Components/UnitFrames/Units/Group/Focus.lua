local Addon, ns = ...
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end
-- Focus frame uses the exact same visual as Party frames.
-- Party.lua is loaded before this file (see UnitFrames.xml),
-- so UnitStyles["Party"] is guaranteed to exist here.
if (UnitStyles["Party"]) then
	UnitStyles["Focus"] = UnitStyles["Party"]
end
