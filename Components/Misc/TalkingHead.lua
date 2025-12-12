--[[

	The MIT License (MIT)

	Copyright (c) 2022 Lars Norberg

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

--]]
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
