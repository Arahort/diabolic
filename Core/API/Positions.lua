local Addon, ns = ...
local API = ns.API or {}
ns.API = API

-- Convert a coordinate within a frame to a usable position
API.GetParsedPosition = function(parentWidth, parentHeight, x, y, bottomOffset, leftOffset, topOffset, rightOffset)
	if (y < parentHeight * 1/3) then
		if (x < parentWidth * 1/3) then
			return "BOTTOMLEFT", leftOffset, bottomOffset
		elseif (x > parentWidth * 2/3) then
			return "BOTTOMRIGHT", rightOffset, bottomOffset
		else
			return "BOTTOM", x - parentWidth/2, bottomOffset
		end
	elseif (y > parentHeight * 2/3) then
		if (x < parentWidth * 1/3) then
			return "TOPLEFT", leftOffset, topOffset
		elseif x > parentWidth * 2/3 then
			return "TOPRIGHT", rightOffset, topOffset
		else
			return "TOP", x - parentWidth/2, topOffset
		end
	else
		if (x < parentWidth * 1/3) then
			return "LEFT", leftOffset, y - parentHeight/2
		elseif (x > parentWidth * 2/3) then
			return "RIGHT", rightOffset, y - parentHeight/2
		else
			return "CENTER", x - parentWidth/2, y - parentHeight/2
		end
	end
end

-- Retrieve a properly scaled position of a frame.
API.GetPosition = function(frame)

	-- Retrieve UI coordinates, convert to unscaled screen coordinates
	local worldHeight = 768 -- WorldFrame:GetHeight()
	local worldWidth = WorldFrame:GetWidth()
	local uiScale = UIParent:GetEffectiveScale()
	local uiWidth = UIParent:GetWidth() * uiScale
	local uiHeight = UIParent:GetHeight() * uiScale
	local uiBottom = UIParent:GetBottom() * uiScale
	local uiLeft = UIParent:GetLeft() * uiScale
	local uiTop = UIParent:GetTop() * uiScale - worldHeight -- use values relative to edges, not origin
	local uiRight = UIParent:GetRight() * uiScale - worldWidth -- use values relative to edges, not origin

	-- Retrieve frame coordinates, convert to unscaled screen coordinates
	local frameScale = frame:GetEffectiveScale()
	local x, y = frame:GetCenter(); x = x * frameScale; y = y * frameScale
	local bottom = frame:GetBottom() * frameScale
	local left = frame:GetLeft() * frameScale
	local top = frame:GetTop() * frameScale - worldHeight -- use values relative to edges, not origin
	local right = frame:GetRight() * frameScale - worldWidth -- use values relative to edges, not origin

	-- Figure out the frame position relative to UIParent
	left = left - uiLeft
	bottom = bottom - uiBottom
	right = right - uiRight
	top = top - uiTop

	-- Figure out the point within the given coordinate space
	local point, offsetX, offsetY = API.GetParsedPosition(uiWidth, uiHeight, x, y, bottom, left, top, right)

	-- Convert coordinates to the frame's scale.
	return point, offsetX / frameScale, offsetY / frameScale
end
