DiabolicColorSwatchSettingMixin = {}
function DiabolicColorSwatchSettingMixin:OnLoad()
	SettingsListElementMixin.OnLoad(self)
end
function DiabolicColorSwatchSettingMixin:Init(initializer)
	local data = initializer:GetData()
	self.Text:SetText(data.name)
	local function GetColor()
		return data.getColor()
	end
	local function UpdateSwatch()
		local color = GetColor()
		self.ColorSwatch.Color:SetVertexColor(color.r, color.g, color.b)
	end
	UpdateSwatch()
	self.ColorSwatch:RegisterForClicks("AnyUp")
	self.ColorSwatch:SetScript("OnEnter", function()
		GameTooltip:SetOwner(self.ColorSwatch, "ANCHOR_RIGHT")
		GameTooltip:SetText(data.name, 1, 1, 1)
		if data.tooltip then
			GameTooltip:AddLine(data.tooltip, 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)
	self.ColorSwatch:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	self.ColorSwatch:SetScript("OnClick", function(_, button)
		local color = GetColor()
		local originalColor = {r = color.r, g = color.g, b = color.b}
		ColorPickerFrame:SetupColorPickerAndShow({
			r = color.r,
			g = color.g,
			b = color.b,
			hasOpacity = false,
			swatchFunc = function()
				local r, g, b = ColorPickerFrame:GetColorRGB()
				data.setColor(r, g, b)
				UpdateSwatch()
			end,
			cancelFunc = function()
				data.setColor(originalColor.r, originalColor.g, originalColor.b)
				UpdateSwatch()
			end,
		})
	end)
end
