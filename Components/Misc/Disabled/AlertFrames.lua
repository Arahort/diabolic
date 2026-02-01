local Addon, ns = ...
local AlertFrames = ns:NewModule("AlertFrames", "LibMoreEvents-1.0")

-- Addon API
local SetObjectScale = ns.API.SetObjectScale

local GroupLootContainer_PostUpdate = function(self)
	local lastIdx = nil
	for i = 1, self.maxIndex do
		local frame = self.rollFrames[i]
		local prevFrame = self.rollFrames[i-1]
		if (frame) then
			frame:ClearAllPoints()
			if (prevFrame and prevFrame ~= frame) then
				frame:SetPoint("BOTTOM", prevFrame, "TOP", 0, 10)
			else
				frame:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
			end
			lastIdx = i
		end
	end
	if (lastIdx) then
		self:SetHeight(self.reservedSize * lastIdx)
		self:Show()
	else
		self:Hide()
	end
end

local AlertSubSystem_AdjustAnchors = function(self, relativeAlert)
	local alertFrame = self.alertFrame
	if (alertFrame and alertFrame:IsShown()) then
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint("BOTTOM", relativeAlert, "TOP", 0, 10)
		return alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustAnchorsNonAlert = function(self, relativeAlert)
	local anchorFrame = self.anchorFrame
	if (anchorFrame and anchorFrame:IsShown()) then
		anchorFrame:ClearAllPoints()
		anchorFrame:SetPoint("BOTTOM", relativeAlert, "TOP", 0, 10)
		return anchorFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustQueuedAnchors = function(self, relativeAlert)
	for alertFrame in self.alertFramePool:EnumerateActive() do
		alertFrame:ClearAllPoints()
		alertFrame:SetPoint("BOTTOM", relativeAlert, "TOP", 0, 10)
		relativeAlert = alertFrame
	end
	return relativeAlert
end

local AlertSubSystem_AdjustPosition = function(alertFrame, subSystem)
	if (subSystem.alertFramePool) then --queued alert system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustQueuedAnchors
	elseif (not subSystem.anchorFrame) then --simple alert system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustAnchors
	elseif (subSystem.anchorFrame) then --anchor frame system
		subSystem.AdjustAnchors = AlertSubSystem_AdjustAnchorsNonAlert
	end
end

local AlertFrame_PostUpdateAnchors = function()
	local AlertFrameHolder = _G[ns.Prefix.."AlertFrameHolder"]

	AlertFrameHolder:ClearAllPoints()
	if (TalkingHeadFrame and TalkingHeadFrame:IsShown()) then
		AlertFrameHolder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 530)
	else
		AlertFrameHolder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 330)
	end

	AlertFrame:ClearAllPoints()
	AlertFrame:SetAllPoints(AlertFrameHolder)

	GroupLootContainer:ClearAllPoints()
	GroupLootContainer:SetPoint("BOTTOM", AlertFrameHolder, "TOP", 0, 10)

	if (GroupLootContainer:IsShown()) then
		GroupLootContainer_PostUpdate(GroupLootContainer)
	end
end

AlertFrames.OnInitialize = function(self)

	local AlertFrameHolder = SetObjectScale(CreateFrame("Frame", ns.Prefix.."AlertFrameHolder", UIParent))
	AlertFrameHolder:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 330)
	AlertFrameHolder:SetSize(180, 20)

	local AlertFrame = SetObjectScale(AlertFrame, 1) -- might need to adjust
	AlertFrame.ignoreFramePositionManager = true
	AlertFrame:SetParent(UIParent)
	AlertFrame:OnLoad()

	for index,alertFrameSubSystem in ipairs(AlertFrame.alertFrameSubSystems) do
		AlertSubSystem_AdjustPosition(AlertFrame, alertFrameSubSystem)
		if (TalkingHeadFrame and TalkingHeadFrame == alertFrameSubSystem.anchorFrame) then
			table_remove(AlertFrame.alertFrameSubSystems, index)
		end
	end

	local GroupLootContainer = SetObjectScale(GroupLootContainer, 1) -- might need to adjust
	GroupLootContainer.ignoreFramePositionManager = true
	GroupLootContainer.ignoreFramePositionManager = true

	if (not ns.IsRetail) and UIPARENT_MANAGED_FRAME_POSITIONS then
		UIPARENT_MANAGED_FRAME_POSITIONS["GroupLootContainer"] = nil
	end

	hooksecurefunc(AlertFrame, "AddAlertFrameSubSystem", AlertSubSystem_AdjustPosition)
	hooksecurefunc(AlertFrame, "UpdateAnchors", AlertFrame_PostUpdateAnchors)
	hooksecurefunc("GroupLootContainer_Update", GroupLootContainer_PostUpdate)

	if (TalkingHeadFrame) then
		TalkingHeadFrame:HookScript("OnShow", AlertFrame_PostUpdateAnchors)
		TalkingHeadFrame:HookScript("OnHide", AlertFrame_PostUpdateAnchors)
	end

end
