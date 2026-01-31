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
	-- Calculate border texture size (similar ratio to ToT: 164/134 = 1.22 width, 46/24 = 1.92 height)
	local borderWidth = width * 1.22
	local borderHeight = height * 2.3
	-- Create border texture
	local border = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
	border:SetSize(borderWidth, borderHeight)
	border:SetPoint("CENTER", frame, "CENTER", 0, 0)
	border:SetTexture(GetMedia("tot-diabolic"))
	border:SetVertexColor(.8, .8, .8)
	frame.__GP_Border = border
	frame.__GP_Styled = true
end

Castbar.OnInitialize = function(self)
	-- Style PlayerCastingBarFrame
	if PlayerCastingBarFrame then
		self:StyleCastbar(PlayerCastingBarFrame)
	end
	-- Style PetCastingBarFrame if it exists
	if PetCastingBarFrame then
		self:StyleCastbar(PetCastingBarFrame)
	end
end
