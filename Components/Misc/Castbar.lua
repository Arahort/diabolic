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
	-- Border size multipliers
	local borderWidth = width * 1.1
	local borderHeight = height * 2.55
	-- Create a separate frame BEHIND the castbar with lower strata
	local borderFrame = CreateFrame("Frame", nil, UIParent)
	borderFrame:SetFrameStrata("LOW")
	borderFrame:SetSize(borderWidth, borderHeight)
	-- Create border texture
	local border = borderFrame:CreateTexture(nil, "ARTWORK")
	border:SetAllPoints()
	border:SetTexture(GetMedia("statusbar/Health-Bar-Border2"))
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
	-- WoW 12.0: SetStatusBarTexture on protected frames is ignored
	-- Alternative: hide original texture and overlay our own with proper texcoord
	local origTexture = frame:GetStatusBarTexture()
	if origTexture then
		origTexture:SetAlpha(0) -- Hide original
		-- Create overlay texture at full width, use texcoord to show progress
		local overlay = frame:CreateTexture(nil, "ARTWORK", nil, 1)
		overlay:SetTexture(GetMedia("statusbar/Heath-Bar"))
		overlay:SetPoint("TOPLEFT", frame, "TOPLEFT")
		overlay:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
		overlay:SetVertexColor(0.2, 0.5, 1.0) -- Blue color
		frame.__GP_BarOverlay = overlay
		-- Update overlay width and texcoord based on progress
		frame:HookScript("OnUpdate", function(self)
			local min, max = self:GetMinMaxValues()
			local value = self:GetValue()
			if max > min then
				local progress = (value - min) / (max - min)
				local fullWidth = self:GetWidth()
				overlay:SetWidth(fullWidth * progress)
				overlay:SetTexCoord(0, progress, 0, 1)
			end
		end)
	end
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
