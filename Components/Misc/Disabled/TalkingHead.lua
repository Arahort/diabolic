local Addon, ns = ...
if (not ns.IsRetail) then
	return
end

local TalkingHead = ns:NewModule("TalkingHead", "AceEvent-3.0")

-- Addon API
local SetObjectScale = ns.API.SetObjectScale

TalkingHead.UpdatePosition = function(self)
	if ns.IsRetail and EditModeManagerFrame then
		if EditModeManagerFrame:IsEditModeActive() then
			return
		else
			local point, relativeTo, relativePoint, xOfs, yOfs = TalkingHeadFrame:GetPoint()
			if point and relativeTo and xOfs and yOfs then
				local db = ns.db.global.talkinghead
				db.positionX = xOfs
				db.positionY = yOfs
			end
		end
	end
	local db = ns.db.global.talkinghead
	TalkingHeadFrame:ClearAllPoints()
	TalkingHeadFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", db.positionX or 0, db.positionY or 160)
end

TalkingHead.OnInitialize = function(self)

	local TalkingHeadFrame = SetObjectScale(TalkingHeadFrame, 1)
	TalkingHeadFrame.ignoreFramePositionManager = true

	if (not ns.IsRetail) then
		UIPARENT_MANAGED_FRAME_POSITIONS.TalkingHeadFrame = nil
	end

	self:UpdatePosition()

	local model = TalkingHeadFrame.MainFrame.Model
	if (model.uiCameraID) then
		model:RefreshCamera()
		Model_ApplyUICamera(model, model.uiCameraID)
	end

	if ns.IsRetail then
		self:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED", "UpdatePosition")
	end

end
