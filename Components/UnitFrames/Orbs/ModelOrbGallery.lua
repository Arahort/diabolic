local Addon, ns = ...
-- Visual model picker for the 3D orbs: a centered window with a paged grid of live
-- 3D previews. Clicking a preview selects that model. Built on the ported
-- DiabolicUI3ModelOrb template (oUF_Diablo style, MIT (c) zork).
local MODEL_SIZE = 128
local COLS = 6
local ROWS = 4
local PER_PAGE = COLS * ROWS
local PAD = 16
local TOP = 44
local BOTTOM = 44
local sortedModels = {}
local function BuildSortedModels()
	if (#sortedModels > 0) then return end
	local data = ns.ModelOrb and ns.ModelOrb.DB and ns.ModelOrb.DB.modelData
	if (not data) then return end
	for id, m in pairs(data) do
		sortedModels[#sortedModels + 1] = {id = id, name = m.name or tostring(id)}
	end
	table.sort(sortedModels, function(a, b) return a.name:lower() < b.name:lower() end)
end
local Gallery = CreateFrame("Frame", "DiabolicUI3ModelOrbGallery", UIParent, "BackdropTemplate")
ns.ModelOrbGallery = Gallery
Gallery:Hide()
Gallery:SetFrameStrata("DIALOG")
Gallery:SetToplevel(true)
Gallery:SetSize(COLS * MODEL_SIZE + PAD * 2, ROWS * MODEL_SIZE + TOP + BOTTOM)
Gallery:SetPoint("CENTER")
Gallery:EnableMouse(true)
Gallery:SetMovable(true)
Gallery:RegisterForDrag("LeftButton")
Gallery:SetScript("OnDragStart", Gallery.StartMoving)
Gallery:SetScript("OnDragStop", Gallery.StopMovingOrSizing)
Gallery:SetBackdrop({
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
Gallery:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
Gallery.title = Gallery:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
Gallery.title:SetPoint("TOP", 0, -14)
Gallery.close = CreateFrame("Button", nil, Gallery, "UIPanelCloseButton")
Gallery.close:SetPoint("TOPRIGHT", -6, -6)
Gallery.cells = {}
local function CreatePreviewCell(index)
	local cell = CreateFrame("Button", nil, Gallery)
	cell:SetSize(MODEL_SIZE, MODEL_SIZE)
	local orb = CreateFrame("Frame", nil, cell, "DiabolicUI3ModelOrb")
	orb:SetSize(256, 256)
	orb:SetScale(MODEL_SIZE / 256)
	orb:SetPoint("CENTER")
	orb.FillingStatusBar:SetFrameLevel(orb:GetFrameLevel() + 1)
	orb.ClipFrame:SetFrameLevel(orb:GetFrameLevel() + 2)
	orb.OverlayFrame:SetFrameLevel(orb:GetFrameLevel() + 3)
	cell.orb = orb
	cell.sel = cell:CreateTexture(nil, "BACKGROUND")
	cell.sel:SetPoint("TOPLEFT", 4, -4)
	cell.sel:SetPoint("BOTTOMRIGHT", -4, 4)
	cell.sel:SetColorTexture(1, 0.82, 0, 0.18)
	cell.sel:Hide()
	cell:SetScript("OnClick", function(self)
		if (Gallery.onSelect and self.modelID) then
			Gallery.onSelect(self.modelID)
		end
		Gallery:Hide()
	end)
	cell:SetScript("OnEnter", function(self)
		self.sel:Show()
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self.modelName or "")
		GameTooltip:AddLine("model-id: " .. tostring(self.modelID), 0.7, 0.7, 0.7)
		GameTooltip:AddLine("Click to select", 1, 1, 1)
		GameTooltip:Show()
	end)
	cell:SetScript("OnLeave", function(self)
		if (self.modelID ~= Gallery.currentID) then self.sel:Hide() end
		GameTooltip:Hide()
	end)
	return cell
end
function Gallery:UpdatePage()
	local pages = math.max(1, math.ceil(#sortedModels / PER_PAGE))
	if (self.page < 1) then self.page = 1 end
	if (self.page > pages) then self.page = pages end
	local startIndex = (self.page - 1) * PER_PAGE
	for i = 1, PER_PAGE do
		local cell = self.cells[i]
		if (not cell) then
			cell = CreatePreviewCell(i)
			local row = math.floor((i - 1) / COLS)
			local col = (i - 1) % COLS
			cell:SetPoint("TOPLEFT", self, "TOPLEFT", PAD + col * MODEL_SIZE, -(TOP + row * MODEL_SIZE))
			self.cells[i] = cell
		end
		local model = sortedModels[startIndex + i]
		if (model) then
			cell:Show()
			cell.modelID = model.id
			cell.modelName = model.name
			cell.orb:LoadModelDataByID(model.id, false)
			cell.orb.FillingStatusBar:SetValue(1)
			if (model.id == self.currentID) then cell.sel:Show() else cell.sel:Hide() end
		else
			cell:Hide()
			cell.modelID = nil
		end
	end
	self.title:SetText(string.format("%s  (%d/%d)", self.headerText or "Select model", self.page, pages))
end
function Gallery:Open(headerText, currentID, onSelect)
	BuildSortedModels()
	self.headerText = headerText
	self.currentID = currentID
	self.onSelect = onSelect
	self.page = 1
	-- jump to the page containing the current model
	for i, m in ipairs(sortedModels) do
		if (m.id == currentID) then
			self.page = math.floor((i - 1) / PER_PAGE) + 1
			break
		end
	end
	self:Show()
	self:Raise()
	self:UpdatePage()
end
Gallery.prev = CreateFrame("Button", nil, Gallery, "UIPanelButtonTemplate")
Gallery.prev:SetSize(80, 22)
Gallery.prev:SetPoint("BOTTOMLEFT", PAD, 12)
Gallery.prev:SetText("< Prev")
Gallery.prev:SetScript("OnClick", function() Gallery.page = Gallery.page - 1; Gallery:UpdatePage() end)
Gallery.next = CreateFrame("Button", nil, Gallery, "UIPanelButtonTemplate")
Gallery.next:SetSize(80, 22)
Gallery.next:SetPoint("BOTTOMRIGHT", -PAD, 12)
Gallery.next:SetText("Next >")
Gallery.next:SetScript("OnClick", function() Gallery.page = Gallery.page + 1; Gallery:UpdatePage() end)
Gallery:SetScript("OnMouseWheel", function(self, delta)
	self.page = self.page - delta
	self:UpdatePage()
end)
Gallery:EnableMouseWheel(true)
