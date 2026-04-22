local Addon, ns = ...
local API = ns.API or {}
ns.API = API

-- WoW API
local CreateFont = CreateFont
local LibStub = _G.LibStub

-- Lua API
local ipairs = ipairs
local pairs = pairs
local rawset = rawset
local setmetatable = setmetatable
local string_format = string.format
local type = type
local table_insert = table.insert

-- Full cache that spawns new objects on-the-fly.
local count, font_mt = 0
font_mt = {
	__index = function(t,k)
		-- Create a new category and subtable
		if (type(k) == "string") then
			local new = setmetatable({}, font_mt)
			rawset(t,k,new)
			return new
		-- Create a new font object
		elseif (type(k) == "number") then
			count = count + 1
			local new = CreateFont(string_format(ns.Prefix.."Font%d", count))
			new:SetJustifyH("LEFT") -- new fonts appear to be centered after 9.1.5
			rawset(t,k,new)
			return new
		end
	end
}
local Fonts = setmetatable({}, font_mt)

-- Caches used for iterations
local AllFonts, ChatFonts, NumberFonts, NormalFonts = {}, {}, {}, {}

-- Built-in Blizzard font list (works across all locales; the client auto-substitutes
-- _CYR variants for ruRU, _TC/_SC for zh, etc., when only the base name is given).
local DEFAULT_LABEL = "Default (game)"
local BUILTIN_FONTS = {
	{ name = DEFAULT_LABEL,  path = nil },                      -- inherit Game16Font (locale-dependent)
	{ name = "Friz Quadrata", path = _G.STANDARD_TEXT_FONT },   -- FRIZQT
	{ name = "Morpheus",      path = [[Fonts\MORPHEUS.ttf]] },  -- quest/capital style
	{ name = "Skurri",        path = [[Fonts\SKURRI.ttf]] },    -- condensed headline
	{ name = "Arial Narrow",  path = [[Fonts\ARIALN.TTF]] },
}

-- Resolve font path by display name from BUILTIN + LibSharedMedia-3.0 (optional).
local ResolveFontPath = function(name)
	if (not name) or (name == DEFAULT_LABEL) then return nil end
	for _, entry in ipairs(BUILTIN_FONTS) do
		if (entry.name == name) then return entry.path end
	end
	local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
	if (LSM) then
		local path = LSM:Fetch("font", name, true)
		if (path) then return path end
	end
	return nil
end

-- Get current custom-font path from saved settings (nil if disabled / default).
local GetCustomFontPath = function()
	if (not ns.db) or (not ns.db.global) or (not ns.db.global.fonts) then return nil end
	local f = ns.db.global.fonts
	if (not f.customEnabled) then return nil end
	return ResolveFontPath(f.fontName) or f.fontPath
end

-- Return a font object, re-use existing ones that match.
-- Custom font is applied ONLY to "Normal" type (keeps Chat/Number untouched).
local GetFont = function(size, outline, type)
	local inherit = type == "Chat" and _G.ChatFontNormal or type == "Number" and _G.NumberFont_Normal_Med or _G.Game16Font
	local fontObject = Fonts[type or "Normal"][outline and "Outline" or "None"][size]
	local isNormal = (type ~= "Chat" and type ~= "Number")
	local customPath = isNormal and GetCustomFontPath() or nil
	if (fontObject:GetFontObject() ~= inherit) then
		fontObject:SetFontObject(inherit)
		fontObject:SetFont(fontObject:GetFont(), size, outline and "OUTLINE" or "")
		fontObject:SetShadowColor(0,0,0,0)
		fontObject:SetShadowOffset(0,0)
	end
	if (customPath) then
		fontObject:SetFont(customPath, size, outline and "OUTLINE" or "")
	end
	local exists = AllFonts[fontObject]
	if (not exists) then
		AllFonts[fontObject] = true
		ChatFonts[fontObject] = type == "Chat"
		NumberFonts[fontObject] = type == "Number"
		NormalFonts[fontObject] = isNormal
		if (ns.callbacks) then
			ns.callbacks:Fire("FontObject_Created", fontObject, type or "Normal")
		end
	end
	return fontObject
end

-- Iterators for our font caches. Provided for restyling purposes.
local GetAllFonts = function() return pairs(AllFonts) end
local GetAllChatFonts = function() return pairs(ChatFonts) end
local GetAllNumberFonts = function() return pairs(NumberFonts) end
local GetAllNormalFonts = function() return pairs(NormalFonts) end

-- Change the font face of a font object.
-- *Only accepts our own font objects.
local SetFontObject = function(fontObject, font)
	if (not fontObject) or (not AllFonts[fontObject]) then
		return
	end
	local _,size,style = fontObject:GetFont()
	fontObject:SetFont(fontObject:GetFont(), size, style)
end

-- Build the list of available fonts: builtins + LibSharedMedia-3.0 (if installed).
-- Returns an array of {name=..., path=...}, sorted for stable dropdown order.
local GetAvailableFonts = function()
	local list = {}
	for _, entry in ipairs(BUILTIN_FONTS) do
		table_insert(list, { name = entry.name, path = entry.path })
	end
	local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
	if (LSM) then
		local seen = {}
		for _, b in ipairs(BUILTIN_FONTS) do seen[b.name] = true end
		for _, fname in ipairs(LSM:List("font") or {}) do
			if (not seen[fname]) then
				local path = LSM:Fetch("font", fname, true)
				if (path) then
					table_insert(list, { name = fname, path = path })
					seen[fname] = true
				end
			end
		end
	end
	return list
end

-- Re-apply the active custom font (or revert to game default) across every
-- "Normal" font object we created. Used when the setting changes at runtime.
local ApplyActiveFont = function()
	local customPath = GetCustomFontPath()
	-- When reverting, read the path directly from Game16Font (the inherit source)
	-- — relying on `fontObject:GetFont()` after previous SetFont calls would keep
	-- the overridden custom path and the revert would silently no-op.
	local inheritPath
	if (not customPath) and _G.Game16Font then
		inheritPath = _G.Game16Font:GetFont()
	end
	for fontObject in pairs(NormalFonts) do
		local _, curSize, curStyle = fontObject:GetFont()
		if (customPath) then
			fontObject:SetFont(customPath, curSize, curStyle or "")
		elseif (inheritPath) then
			fontObject:SetFont(inheritPath, curSize, curStyle or "")
		end
	end
end

-- Add some aliases for blizzard artwork.
local alias = {
	["plain"] = [[Interface\ChatFrame\ChatFrameBackground]]
}

-- Retrieve an asset from the media asset folder.
local GetMedia = function(name, type)
	return alias[name] or string_format([[Interface\AddOns\%s\Assets\%s.%s]], Addon, name, type or "tga")
end

-- Global API
---------------------------------------------------------
API.GetFont = GetFont
API.GetAllFonts = GetAllFonts
API.GetAllChatFonts = GetAllChatFonts
API.GetAllNumberFonts = GetAllNumberFonts
API.GetAllNormalFonts = GetAllNormalFonts
API.SetFontObject = SetFontObject
API.GetMedia = GetMedia
API.GetAvailableFonts = GetAvailableFonts
API.ApplyActiveFont = ApplyActiveFont
API.ResolveFontPath = ResolveFontPath
