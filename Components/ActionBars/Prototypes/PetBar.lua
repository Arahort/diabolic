local Addon, ns = ...
local ActionBars = ns:GetModule("ActionBars")

-- Lua API
local ipairs = ipairs
local select = select

-- WoW API
local ClearOverrideBindings = ClearOverrideBindings
local GetBindingKey = GetBindingKey
local InCombatLockdown = InCombatLockdown
local SetOverrideBindingClick = SetOverrideBindingClick

local PetBar = CreateFrame("Button")
local PetBar_MT = { __index = PetBar }
ns.PetBar = PetBar

PetBar.CreateButton = function(self, id, name)

	local button = ns.PetButton:Create(id, name, self)
	button.keyBoundTarget = "BONUSACTIONBUTTON"..id

	self.buttons[#self.buttons + 1] = button

	return button
end

PetBar.ForAll = function(self, method, ...)
	if (not self.buttons) then
		return
	end
	for _,button in self:GetAll() do
		local func = button[method]
		if (func) then
			func(button, ...)
		end
	end
end

PetBar.GetAll = function(self)
	return pairs(self.buttons)
end

PetBar.UpdateBindings = function(self)
	if (InCombatLockdown()) then
		return
	end
	if (not self.buttons) then
		return
	end
	ClearOverrideBindings(self)
	for id,button in ipairs(self.buttons) do
		local bindingAction = button.keyBoundTarget
		if (bindingAction) then
			-- iterate through the registered keys for the action
			local buttonName = button:GetName()
			for keyNumber = 1,select("#", GetBindingKey(bindingAction)) do
				-- get a key for the action
				local key = select(keyNumber, GetBindingKey(bindingAction))
				if (key and (key ~= "")) then
					-- this is why we need named buttons
					SetOverrideBindingClick(self, false, key, buttonName) -- assign the key to our own button
				end
			end
		end
	end
end

PetBar.UpdateVisibilityDriver = function(self)
	if (InCombatLockdown()) then
		return
	end

	local visdriver
	if (self.enabled) then
		visdriver = self.customVisibilityDriver or "[petbattle][vehicleui]hide;[@pet,exists,nopossessbar]show;hide"
	end
	self:SetAttribute("visibility-driver", visdriver)

	UnregisterStateDriver(self, "vis")
	self:SetAttribute("state-vis", "0")
	RegisterStateDriver(self, "vis", visdriver or "hide")
end

PetBar.Enable = function(self)
	if (InCombatLockdown()) then
		return
	end
	self.enabled = true
	self:UpdateVisibilityDriver()
end

PetBar.Disable = function(self)
	if (InCombatLockdown()) then
		return
	end
	self.enabled = false
	self:UpdateVisibilityDriver()
end

PetBar.IsEnabled = function(self)
	return self.enabled
end

-- Constructor
PetBar.Create = function(self, name, parent)

	local bar = setmetatable(CreateFrame("Frame", name, parent, "SecureHandlerStateTemplate"), PetBar_MT)
	bar:SetFrameStrata("BACKGROUND")
	bar:SetFrameLevel(10)
	bar:SetAttribute("_onstate-vis", [[
		if not newstate then return end
		if newstate == "show" then
			self:Show()
		elseif newstate == "hide" then
			self:Hide()
		end
	]])
	bar.buttons = {}
	bar.config = {
		showgrid = true,
		hidehotkey = true
	}

	return bar
end