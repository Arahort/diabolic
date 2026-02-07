local Addon, ns = ...

-- Addon API
local GetScale = ns.API.GetScale

-- Little trick to show the layout and dimensions
-- of the Minimap blip icons on-screen in-game,
-- whenever blizzard decide to update those.
------------------------------------------------------------

-- By setting a single point, but not any sizes,
-- the texture is shown in its original size and dimensions!
local f = UIParent:CreateTexture()
f:SetIgnoreParentScale(true)
f:SetScale(GetScale())
f:Hide()
f:SetTexture([[Interface\MiniMap\ObjectIconsAtlas.blp]])
f:SetPoint("CENTER")

-- Add a little backdrop for easy
-- copy & paste from screenshots!
local g = UIParent:CreateTexture()
g:Hide()
g:SetColorTexture(0,.7,0,.25)
g:SetAllPoints(f)

LibStub("AceConsole-3.0"):RegisterChatCommand("toggleblips", function()
	local show = not f:IsShown()
	f:SetShown(show)
	g:SetShown(show)
end)

-- Kill off the non-stop voice chat error 17 on retail.
if (ns.IsRetail) then
	if (ChannelFrame) then
		ChannelFrame:UnregisterEvent("VOICE_CHAT_ERROR")
	else
		local frame = CreateFrame("Frame")
		frame:RegisterEvent("ADDON_LOADED")
		frame:SetScript("OnEvent", function(self, event, addon)
			if (addon ~= "Blizzard_Channels") then return end
			self:UnregisterEvent("ADDON_LOADED")
			ChannelFrame:UnregisterEvent("VOICE_CHAT_ERROR")
		end)
	end
end
