DiabolicInfoBlockMixin = {}
function DiabolicInfoBlockMixin:Init(initializer)
	local data = initializer:GetData()
	self.Text:SetNonSpaceWrap(true)
	self.Text:SetText(data.text)
end
