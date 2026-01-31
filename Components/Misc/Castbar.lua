local Addon, ns = ...
local Castbar = ns:NewModule("Castbar", "AceEvent-3.0")

-- Addon API
local GetMedia = ns.API.GetMedia

Castbar.StyleCastbar = function(self, frame)
	if not frame then return end
	if frame.__GP_Styled then return end
	-- Get castbar dimensions
	local width, height = frame:GetSize()
	if width == 0 or height == 0 then
		width, height = 195, 20 -- default size fallback
	end
	-- ToT texture is 164x46 for a 134x24 frame
	-- Castbar is much wider, increase multipliers
	local borderWidth = width * 1.45
	local borderHeight = height * 5.0
	-- Create a separate frame BEHIND the castbar with lower strata
	local borderFrame = CreateFrame("Frame", nil, UIParent)
	borderFrame:SetFrameStrata("LOW")
	borderFrame:SetSize(borderWidth, borderHeight)
	-- Create border texture
	local border = borderFrame:CreateTexture(nil, "ARTWORK")
	border:SetAllPoints()
	border:SetTexture(GetMedia("tot-diabolic"))
	border:SetVertexColor(.8, .8, .8)
	-- Position and show/hide with castbar
	local function UpdatePosition()
		if frame:IsShown() then
			borderFrame:ClearAllPoints()
			borderFrame:SetPoint("CENTER", frame, "CENTER", 0, 0)
			borderFrame:Show()
		else
			borderFrame:Hide()
		end
	end
	frame:HookScript("OnShow", UpdatePosition)
	frame:HookScript("OnHide", function() borderFrame:Hide() end)
	-- Initial state
	borderFrame:Hide()
	frame.__GP_BorderFrame = borderFrame
	frame.__GP_Border = border
	frame.__GP_Styled = true
end

Castbar.OnInitialize = function(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEvent")
end

Castbar.OnEvent = function(self, event)
	if event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(0.5, function()
			if PlayerCastingBarFrame then
				self:StyleCastbar(PlayerCastingBarFrame)
			end
			if PetCastingBarFrame then
				self:StyleCastbar(PetCastingBarFrame)
			end
		end)
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end
