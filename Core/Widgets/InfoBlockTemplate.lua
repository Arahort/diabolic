DiabolicInfoBlockMixin = {}
function DiabolicInfoBlockMixin:Init(initializer)
	local data = initializer:GetData()
	self.Text:SetNonSpaceWrap(true)
	self.Text:SetTextColor(1, 1, 1)
	self.Text:SetText(data.text)
	if data.height then
		self:SetHeight(data.height)
	end
end
