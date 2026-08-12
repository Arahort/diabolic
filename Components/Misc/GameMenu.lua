--[[
	GameMenu.lua
	Reskins the Escape game menu: Blizzard's frame chrome and the buttons' three
	slice atlas art are hidden and replaced with our own textures.

	Only textures, regions and the frame scale are touched, never secure
	attributes or click handlers, so the protected Log Out and Exit Game buttons
	keep working.

	Artwork and the original implementation of this skin are by Gonkast
	(MyCustomFrames / MyCustomFrames-Skins, "Charcoal" skin), used with permission.
--]]
local Addon, ns = ...
local GameMenu = ns:NewModule("GameMenu", "AceEvent-3.0")

-- Lua API
local ipairs = ipairs
local unpack = unpack

-- WoW API
local CreateFrame = CreateFrame
local InCombatLockdown = InCombatLockdown

-- Addon API
local Colors = ns.Colors
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia
local UIHider = ns.Hider

local TEX_BACKDROP = GetMedia("gamemenu/gamemenu-backdrop", "png")
local TEX_BUTTON = GetMedia("gamemenu/gamemenu-button", "png")
local TEX_BUTTON_RED = GetMedia("gamemenu/gamemenu-button-red", "png")

local CFG = {
	-- Full screen dim behind the menu. Own frame, nothing protected involved.
	dimEnabled = true,
	dimAlpha = .4,
	dimColor = { 0, 0, 0 },

	-- Scale of the whole menu. GameMenuFrame is not protected, so this is safe.
	menuScale = .83,

	-- Backdrop art, real size 944x1725. The width follows the frame plus padding,
	-- the height is derived from the real aspect ratio so the art is never stretched.
	bgAspect = 1725 / 944,
	bgScale = 1.25,
	bgPadLeft = 40,
	bgPadRight = 40,
	bgPadTop = 40,
	bgPadBottom = 40,

	-- Title, anchored to the backdrop rather than the frame: the frame's height
	-- changes with the number of visible buttons, the backdrop's does not.
	titleX = 0,
	titleY = -30,
	titleFontSize = 18,

	-- Button art, real size 934x177. The height drives the sizing, the width is
	-- derived from the real proportion.
	buttonAspect = 934 / 177,
	buttonWidthScale = 1,
	buttonExtraHeight = 10,
	buttonFontDelta = 1,
	texExtraHeight = 10,
	buttonSpacing = 1,
}

-- Which buttons get the red art, matched by their localized label so this works
-- in every locale.
local RED_LABELS = {}
if (LOG_OUT) then RED_LABELS[LOG_OUT] = true end
if (EXIT_GAME) then RED_LABELS[EXIT_GAME] = true end
if (MAINMENU_BUTTON) then RED_LABELS[MAINMENU_BUTTON] = true end

local TextureForLabel = function(label)
	return (label and RED_LABELS[label]) and TEX_BUTTON_RED or TEX_BUTTON
end

-- Hide Blizzard's frame chrome. Runs on every show, otherwise the original
-- border peeks through once Blizzard re-shows it.
local HideBlizzardChrome = function()
	local frame = GameMenuFrame
	if (not frame) then return end

	if (frame.NineSlice) then
		frame.NineSlice:SetAlpha(0)
		frame.NineSlice:Hide()
		if (frame.NineSlice:GetParent() ~= UIHider) then
			frame.NineSlice:SetParent(UIHider)
		end
	end

	for _,key in ipairs({ "Border", "Background", "Bg", "BorderFrame" }) do
		local region = frame[key]
		if (region and region.SetAlpha) then
			region:SetAlpha(0)
			if (region.Hide) then region:Hide() end
		end
	end

	-- Everything Blizzard draws straight on the frame goes, ours stays.
	for _,region in ipairs({ frame:GetRegions() }) do
		if (region.GetObjectType and region:GetObjectType() == "Texture" and not region.diabolic) then
			region:SetAlpha(0)
		end
	end
end

-- The retail menu buttons use ThreeSliceButtonTemplate, so their art lives in
-- the Left/Center/Right atlas textures plus the button's own state textures.
local SLICE_KEYS = { "Left", "Center", "Middle", "Right" }
local STATE_GETTERS = { "GetNormalTexture", "GetPushedTexture", "GetDisabledTexture", "GetHighlightTexture" }

local HideButtonArt = function(button)
	for _,key in ipairs(SLICE_KEYS) do
		local region = button[key]
		if (region and region.SetAlpha) then
			region:SetAlpha(0)
		end
	end
	for _,getter in ipairs(STATE_GETTERS) do
		if (button[getter]) then
			local texture = button[getter](button)
			if (texture) then texture:SetAlpha(0) end
		end
	end
end

local IsGameMenuButton = function(button)
	if (not button or button:GetParent() ~= GameMenuFrame) then return false end
	if (button.GetObjectType and button:GetObjectType() ~= "Button") then return false end
	return (button.GetText and button:GetText() ~= nil) and true or false
end

local ForEachMenuButton = function(func)
	if (not GameMenuFrame) then return end
	for _,child in ipairs({ GameMenuFrame:GetChildren() }) do
		if (child.IsShown and child:IsShown()) then
			func(child)
		end
	end
end

-- Uses the stored base font size so repeated passes stay idempotent and the
-- font never keeps growing.
local StyleButtonText = function(button)
	local text = button:GetFontString() or button.Text
	local base = button.diabolicFont
	if (not text or not base) then return end
	text:SetDrawLayer("OVERLAY")
	if (base[1]) then
		text:SetFont(base[1], base[2] + CFG.buttonFontDelta, "OUTLINE")
	end
	text:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	text:SetShadowColor(0, 0, 0, 0)
end

local SkinButton = function(button)
	if (not IsGameMenuButton(button)) then return end

	-- Guarded on the texture itself rather than a flag, so a half initialized
	-- button still gets finished on the next pass.
	if (not button.diabolicTexture) then
		HideButtonArt(button)

		button.diabolicBaseHeight = button:GetHeight()
		local text = button:GetFontString() or button.Text
		if (text) then
			local face, size = text:GetFont()
			button.diabolicFont = { face or STANDARD_TEXT_FONT, size or 14 }
		end

		-- ARTWORK sublevel 7 sits above the atlas slices but below the OVERLAY
		-- label, so the text stays readable even when the button re-shows its
		-- own slices on mouseover.
		local texture = button:CreateTexture(nil, "ARTWORK", nil, 7)
		texture:SetPoint("CENTER")
		button.diabolicTexture = texture

		local highlight = button:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetPoint("CENTER")
		highlight:SetBlendMode("ADD")
		highlight:SetVertexColor(1, 1, 1, .18)
		button.diabolicHighlight = highlight
	end

	if (not button.diabolicBaseHeight) then return end

	-- The button pool reuses buttons for different entries, so everything below
	-- is refreshed on every pass. The highlight uses the same art as the button,
	-- so red buttons glow red.
	local art = TextureForLabel(button:GetText())
	button.diabolicTexture:SetTexture(art)
	button.diabolicHighlight:SetTexture(art)

	local visibleHeight = button.diabolicBaseHeight + CFG.buttonExtraHeight + CFG.texExtraHeight
	local visibleWidth = visibleHeight * CFG.buttonAspect * CFG.buttonWidthScale
	local extraWidth = visibleWidth - button:GetWidth()

	button.diabolicTexture:SetSize(visibleWidth, visibleHeight)
	button.diabolicHighlight:SetSize(visibleWidth, visibleHeight)

	-- Physical box = visible art plus the gap between buttons. The layout stacks
	-- these boxes, so the extra height turns into spacing without changing how
	-- big the buttons look.
	local gap = CFG.buttonSpacing
	button:SetHeight(visibleHeight + gap)

	-- Clickable area follows the visible art: wider than the box, and trimmed
	-- vertically so the gap between buttons is not clickable.
	button:SetHitRectInsets(-extraWidth / 2, -extraWidth / 2, gap / 2, gap / 2)

	StyleButtonText(button)
	HideButtonArt(button)
end

local GetMenuTitle = function()
	local header = GameMenuFrame.Header or _G.GameMenuFrameHeader
	if (header) then
		if (header.Text and header.Text.GetText) then
			local text = header.Text:GetText()
			if (text and text ~= "") then return text end
		end
		for _,region in ipairs({ header:GetRegions() }) do
			if (region.GetObjectType and region:GetObjectType() == "FontString") then
				local text = region:GetText()
				if (text and text ~= "") then return text end
			end
		end
	end
	return MAINMENU_BUTTON or "Game Menu"
end

local BuildFrameArt = function()
	if (GameMenuFrame.diabolicSkinned) then return end
	GameMenuFrame.diabolicSkinned = true

	-- Grab the localized title before the header is hidden.
	local titleText = GetMenuTitle()

	HideBlizzardChrome()

	local header = GameMenuFrame.Header or _G.GameMenuFrameHeader
	if (header) then
		header:SetAlpha(0)
		header:Hide()
	end

	-- Backdrop and border. Centered with an explicit size kept up to date in
	-- UpdateBackdropSize, rather than stretched between two corners, which would
	-- distort the art since the frame's aspect never matches the texture's.
	local backdrop = GameMenuFrame:CreateTexture(nil, "BACKGROUND")
	backdrop:SetTexture(TEX_BACKDROP)
	backdrop:SetPoint("CENTER", GameMenuFrame, "CENTER",
		(CFG.bgPadLeft - CFG.bgPadRight) / 2, (CFG.bgPadTop - CFG.bgPadBottom) / 2)
	-- Tagged so the sweep in HideBlizzardChrome leaves it alone.
	backdrop.diabolic = true
	GameMenuFrame.diabolicBackdrop = backdrop

	-- The title lives on its own child frame with a raised frame level so it
	-- renders above everything else on the plate.
	local headerFrame = CreateFrame("Frame", nil, GameMenuFrame)
	headerFrame:SetAllPoints(GameMenuFrame)
	headerFrame:SetFrameLevel(GameMenuFrame:GetFrameLevel() + 10)

	local title = headerFrame:CreateFontString(nil, "OVERLAY")
	title:SetFontObject(GetFont(CFG.titleFontSize, true))
	title:SetText(titleText)
	title:SetTextColor(Colors.offwhite[1], Colors.offwhite[2], Colors.offwhite[3])
	title:SetShadowColor(0, 0, 0, 0)
	-- Anchored to the backdrop, not the frame: the frame's top edge moves with
	-- the number of visible buttons, the backdrop's does not.
	title:SetPoint("TOP", backdrop, "TOP", CFG.titleX, CFG.titleY)
	GameMenuFrame.diabolicTitle = title
end

-- Width follows the frame plus padding, height is derived from the real texture
-- proportion so the art keeps its shape.
local UpdateBackdropSize = function()
	local backdrop = GameMenuFrame.diabolicBackdrop
	if (not backdrop) then return end
	local width = ((GameMenuFrame:GetWidth() or 200) + CFG.bgPadLeft + CFG.bgPadRight) * CFG.bgScale
	backdrop:SetSize(width, width * CFG.bgAspect)
end

local dimFrame
local EnsureDimFrame = function()
	if (dimFrame) then return dimFrame end
	local frame = CreateFrame("Frame", ns.Prefix.."GameMenuDim", UIParent)
	frame:SetAllPoints(UIParent)
	-- BACKGROUND keeps this behind the menu even when other addons sit at MEDIUM.
	frame:SetFrameStrata("BACKGROUND")
	frame:EnableMouse(false)
	frame:Hide()

	local texture = frame:CreateTexture(nil, "BACKGROUND")
	texture:SetAllPoints()
	texture:SetColorTexture(unpack(CFG.dimColor))
	frame.texture = texture

	dimFrame = frame
	return frame
end

GameMenu.ShowDim = function(self)
	if (not CFG.dimEnabled) then return end
	local frame = EnsureDimFrame()
	frame:SetAlpha(CFG.dimAlpha)
	frame:Show()
end

GameMenu.HideDim = function(self)
	if (dimFrame) then
		dimFrame:Hide()
	end
end

GameMenu.SkinFrame = function(self)
	if (not GameMenuFrame or GameMenuFrame:IsForbidden()) then return end

	-- Resizing buttons and rescaling the frame while the player is in combat is
	-- asking for blocked calls, so it waits for the fight to end instead.
	if (InCombatLockdown()) then
		self.skinPending = true
		return
	end
	self.skinPending = nil

	BuildFrameArt()
	HideBlizzardChrome()
	GameMenuFrame:SetScale(CFG.menuScale)

	UpdateBackdropSize()
	ForEachMenuButton(SkinButton)

	-- Button heights changed after Blizzard's own layout ran, so the layout is
	-- redone to space everything without overlap.
	if (GameMenuFrame.Layout) then
		GameMenuFrame:Layout()
	end

	-- The layout above is what settles the final frame width, so the backdrop is
	-- sized once more. Without this the plate comes out too small the first time
	-- the menu is opened after a reload.
	UpdateBackdropSize()
end

GameMenu.HookMenu = function(self)
	if (not GameMenuFrame or GameMenuFrame.diabolicHooked) then return end
	GameMenuFrame.diabolicHooked = true

	GameMenuFrame:HookScript("OnShow", function()
		self:SkinFrame()
		self:ShowDim()
	end)
	GameMenuFrame:HookScript("OnHide", function()
		self:HideDim()
	end)

	-- Blizzard rebuilds the visible button list here, so we reskin afterwards.
	if (type(GameMenuFrame_UpdateVisibleButtons) == "function") then
		hooksecurefunc("GameMenuFrame_UpdateVisibleButtons", function()
			self:SkinFrame()
		end)
	end

	if (GameMenuFrame:IsShown()) then
		self:SkinFrame()
		self:ShowDim()
	end
end

GameMenu.OnEvent = function(self, event, addon)
	if (event == "ADDON_LOADED") then
		if (addon == "Blizzard_GameMenu") then
			self:HookMenu()
		end
		return
	end
	if (event == "PLAYER_REGEN_ENABLED") then
		if (self.skinPending) then
			self:SkinFrame()
		end
		return
	end
	self:HookMenu()
end

GameMenu.OnInitialize = function(self)
	self:RegisterEvent("ADDON_LOADED", "OnEvent")
	self:RegisterEvent("PLAYER_LOGIN", "OnEvent")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnEvent")
end
