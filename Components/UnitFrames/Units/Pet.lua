local Addon, ns = ...
local UnitStyles = ns.UnitStyles
if (not UnitStyles) then
	return
end

-- WoW API
local CreateFrame = CreateFrame

-- Addon API
local GetFont = ns.API.GetFont
local GetMedia = ns.API.GetMedia

-- Classic style (portrait + health bar)
local StyleClassic = function(self, unit, id)
	self:SetSize(60,72)
	self:SetHitRectInsets(0,0,0,-16)

	-- Health
	--------------------------------------------
	local health = self:CreateBar(self:GetName().."HealthBar")
	health:SetHeight(9)
	health:SetPoint("TOP", 0, -1)
	health:SetPoint("LEFT", 2, 0)
	health:SetPoint("RIGHT", -2, 0)
	health:SetStatusBarTexture(GetMedia("bar-small"))
	health.colorHealth = true
	health.colorClass = false
	health.colorReaction = true

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth

	local healthBg = health:CreateTexture(health:GetName().."Backdrop", "BACKGROUND", nil, -7)
	healthBg:SetPoint("TOPLEFT", -1, 1)
	healthBg:SetPoint("BOTTOMRIGHT", 1, -1)
	healthBg:SetColorTexture(.05, .05, .05, .85)

	self.Health.bg = healthBg

	local name = self:CreateFontString(nil, "OVERLAY", nil, 6)
	name:SetFontObject(GetFont(12,true))
	name:SetJustifyH("CENTER")
	name:SetTextColor(unpack(ns.Colors.offwhite))
	name:SetAlpha(.85)
	name:SetPoint("TOP", self, "BOTTOM", 0, -4)
	name:SetPoint("LEFT", self, -20, 0)
	name:SetPoint("RIGHT", self, 20, 0)
	self:Tag(name, "["..ns.Prefix..":Name]")

	self.Name = name

	-- Portrait
	--------------------------------------------
	local portrait = CreateFrame("PlayerModel", self:GetName().."Portrait", self)
	portrait:SetPoint("TOP", 0, -18)
    portrait:SetPoint("BOTTOM", 0, 6)
	portrait:SetPoint("LEFT", 6, 0)
	portrait:SetPoint("RIGHT", -6, 0)
	portrait:SetAlpha(.85)

    self.Portrait = portrait

	local backdrop = portrait:CreateTexture(portrait:GetName().."Backdrop", "BACKGROUND", nil, -7)
	backdrop:SetIgnoreParentAlpha(true)
	backdrop:SetAllPoints()
	backdrop:SetColorTexture(.05, .05, .05, .85)

	self.Portrait.Backdrop = backdrop

	local border = CreateFrame("Frame", portrait:GetName().."BorderFrame", portrait, ns.BackdropTemplate)
	border:SetIgnoreParentAlpha(true)
	border:SetBackdrop({ edgeFile = GetMedia("border-aura"), edgeSize = 16 })
	border:SetBackdropBorderColor(unpack(self.colors.cast))
	border:SetPoint("TOPLEFT", -13, 13)
	border:SetPoint("BOTTOMRIGHT", 13, -13)
	border:SetFrameLevel(self:GetFrameLevel() + 2)

	self.Portrait.Border = border

	-- CombatFeedback
	--------------------------------------------
	local feedbackText = border:CreateFontString(nil, "OVERLAY")
	feedbackText.maxAlpha = .8
	feedbackText.feedbackFont = GetFont(18, true)
	feedbackText.feedbackFontLarge = GetFont(18, true)
	feedbackText.feedbackFontSmall = GetFont(13, true)
	feedbackText:SetPoint("CENTER", 0, 0)
	feedbackText:SetFontObject(feedbackText.feedbackFont)

	self.CombatFeedback = feedbackText

	-- Cast
	--------------------------------------------
	local cast = self:CreateBar(self:GetName().."CastBar")
	cast:Hide()
	cast:SetFrameLevel(health:GetFrameLevel() + 1)
	cast:SetHeight(9)
	cast:SetPoint("TOP", 0, -1)
	cast:SetPoint("LEFT", 2, 0)
	cast:SetPoint("RIGHT", -2, 0)
	cast:SetStatusBarTexture(GetMedia("bar-small"))
	cast:SetStatusBarColor(1, 1, 1, .25)
	cast:SetSparkTexture(GetMedia("blank"))
	cast:DisableSmoothing(true)

	self.Castbar = cast

	-- Mark as classic style for positioning
	self.isOrbStyle = false
end

-- Orb style (like player health orb but smaller and green)
local StyleOrb = function(self, unit, id)
	-- Orb is half the size of player orb (200 -> 100)
	local orbSize = 100
	local backdropSize = 165

	self:SetSize(orbSize, orbSize)
	self:SetHitRectInsets(-10, -10, -10, -10)

	-- Artwork holder (for proper layering)
	local artworkHolder = CreateFrame("Frame", nil, self)
	artworkHolder:SetAllPoints()
	artworkHolder:SetFrameLevel(self:GetFrameLevel())

	local artworkOverlay = CreateFrame("Frame", nil, self)
	artworkOverlay:SetAllPoints()
	artworkOverlay:SetFrameStrata(self:GetFrameStrata())
	artworkOverlay:SetFrameLevel(self:GetFrameLevel() + 5)

	-- Health Orb
	--------------------------------------------
	local health = self:CreateOrb(self:GetName().."HealthOrb")
	health:SetSize(orbSize, orbSize)
	health:SetPoint("CENTER")
	health:SetStatusBarTexture(GetMedia("orb2"), GetMedia("orb2"))
	-- Green color for friendly (pet)
	health.colorHealth = false
	health:SetStatusBarColor(0.2, 0.9, 0.2) -- Friendly green

	select(2, health:GetStatusBarTexture()):SetTexCoord(1,0,1,0) -- flip 2nd texture horizontally

	self.Health = health
	self.Health.Override = ns.API.UpdateHealth

	local healthBackdrop = artworkHolder:CreateTexture(health:GetName().."Backdrop", "BACKGROUND", nil, -7)
	healthBackdrop:SetSize(backdropSize, backdropSize)
	healthBackdrop:SetPoint("CENTER", health)
	healthBackdrop:SetTexture(GetMedia("orb-backdrop1"))

	self.Health.Backdrop = healthBackdrop

	local healthOverlay = CreateFrame("Frame", nil, health)
	healthOverlay:SetFrameLevel(health:GetFrameLevel() + 5)

	self.Health.Overlay = healthOverlay

	local healthShade = artworkOverlay:CreateTexture(nil, "BACKGROUND")
	healthShade:SetAllPoints(health)
	healthShade:SetTexture(GetMedia("shade-circle"))
	healthShade:SetVertexColor(0,0,0,1)

	self.Health.Shade = healthShade

	local healthGlass = artworkOverlay:CreateTexture(health:GetName().."Glass", "BORDER")
	healthGlass:SetAllPoints(healthBackdrop)
	healthGlass:SetTexture(GetMedia("orb-glass"))
	healthGlass:SetAlpha(.6)

	self.Health.Glass = healthGlass

	local healthBorder = artworkOverlay:CreateTexture(health:GetName().."Border", "ARTWORK")
	healthBorder:SetAllPoints(healthBackdrop)
	healthBorder:SetTexture(GetMedia("orb-border"))

	self.Health.Border = healthBorder

	-- Mark as orb style for positioning
	self.isOrbStyle = true
end

UnitStyles["Pet"] = function(self, unit, id)
	-- Check setting for orb style
	local useOrbStyle = ns.db and ns.db.char and ns.db.char.pet and ns.db.char.pet.useOrbStyle
	if useOrbStyle then
		StyleOrb(self, unit, id)
	else
		StyleClassic(self, unit, id)
	end
end
