--[[
# Element: Portraits

Handles the updating of the unit's portrait.

## Widget

Portrait - A `PlayerModel` or a `Texture` used to represent the unit's portrait.

## Notes

A question mark model will be used if the widget is a PlayerModel and the client doesn't have the model information for
the unit.

## Options

.showClass - Displays the unit's class in the portrait (boolean)

## Examples

    -- 3D Portrait
    -- Position and size
    local Portrait = CreateFrame('PlayerModel', nil, self)
    Portrait:SetSize(32, 32)
    Portrait:SetPoint('RIGHT', self, 'LEFT')

    -- Register it with oUF
    self.Portrait = Portrait

    -- 2D Portrait
    local Portrait = self:CreateTexture(nil, 'OVERLAY')
    Portrait:SetSize(32, 32)
    Portrait:SetPoint('RIGHT', self, 'LEFT')

    -- Register it with oUF
    self.Portrait = Portrait
--]]

local _, ns = ...
local oUF = ns.oUF

-- WoW 12.0.0: issecretvalue may not exist in older versions
local issecretvalue = issecretvalue or function() return false end

local function Update(self, event, unit)
	if(not unit) then return end
	-- WoW 12.0: UnitIsUnit can return a secret boolean for hostile unseen units
	-- (e.g. target="target" when our focustarget is an enemy NPC). A `not` test on
	-- a secret boolean throws. Use pcall and treat secret result as "no match".
	local ok, isSame = pcall(UnitIsUnit, self.unit, unit)
	if (not ok) or issecretvalue(isSame) or (not isSame) then return end

	local element = self.Portrait

	--[[ Callback: Portrait:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Portrait element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if(element.PreUpdate) then element:PreUpdate(unit) end

	-- WoW 12.0: UnitGUID can return a secret value for hostile unseen units
	-- (e.g. focustarget when target is an enemy NPC). Comparing/storing a secret
	-- string taints the frame. Treat secret GUID as "no GUID change" to avoid taint.
	local ok, guid = pcall(UnitGUID, unit)
	if (not ok) or (guid and issecretvalue(guid)) then guid = nil end
	local isAvailable = UnitIsConnected(unit) and UnitIsVisible(unit)
	local hasStateChanged = event ~= 'OnUpdate' or element.guid ~= guid or element.state ~= isAvailable
	if(hasStateChanged) then
		if(element:IsObjectType('PlayerModel')) then
			if(not isAvailable) then
				element:SetCamDistanceScale(0.25)
				element:SetPortraitZoom(0)
				element:SetPosition(0, 0, 0.25)
				element:ClearModel()
				element:SetModel([[Interface\Buttons\TalkToMeQuestionMark.m2]])
			else
				element:SetCamDistanceScale(1)
				element:SetPortraitZoom(1)
				element:SetPosition(0, 0, 0)
				element:ClearModel()
				pcall(element.SetUnit, element, unit)
			end
		else
			local class, _
			if(element.showClass) then
				-- BUG: UnitClassBase can't be trusted
				--      https://github.com/Stanzilla/WoWUIBugs/issues/621
				local okC
				okC, _, class = pcall(UnitClass, unit)
				if (not okC) or (class and issecretvalue(class)) then class = nil end
			end

			if(class) then
				element:SetAtlas('classicon-' .. class)
			else
				pcall(SetPortraitTexture, element, unit)
			end
		end

		element.guid = guid
		element.state = isAvailable
	end

	--[[ Callback: Portrait:PostUpdate(unit)
	Called after the element has been updated.

	* self            - the Portrait element
	* unit            - the unit for which the update has been triggered (string)
	* hasStateChanged - indicates whether the state has changed since the last update (boolean)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, hasStateChanged)
	end
end

local function Path(self, ...)
	--[[ Override: Portrait.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	--]]
	return (self.Portrait.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.Portrait
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_MODEL_CHANGED', Path)
		self:RegisterEvent('UNIT_PORTRAIT_UPDATE', Path)
		self:RegisterEvent('PORTRAITS_UPDATED', Path, true)
		self:RegisterEvent('UNIT_CONNECTION', Path)

		-- The quest log uses PARTY_MEMBER_{ENABLE,DISABLE} to handle updating of
		-- party members overlapping quests. This will probably be enough to handle
		-- model updating.
		if(unit == 'party' or unit == 'target') then
			self:RegisterEvent('PARTY_MEMBER_ENABLE', Path)
			self:RegisterEvent('PARTY_MEMBER_DISABLE', Path)
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Portrait
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_MODEL_CHANGED', Path)
		self:UnregisterEvent('UNIT_PORTRAIT_UPDATE', Path)
		self:UnregisterEvent('PORTRAITS_UPDATED', Path)
		self:UnregisterEvent('PARTY_MEMBER_ENABLE', Path)
		self:UnregisterEvent('PARTY_MEMBER_DISABLE', Path)
		self:UnregisterEvent('UNIT_CONNECTION', Path)
	end
end

oUF:AddElement('Portrait', Path, Enable, Disable)
