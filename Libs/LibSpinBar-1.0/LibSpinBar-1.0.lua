local MAJOR_VERSION = "LibSpinBar-1.0"
local MINOR_VERSION = 1

if (not LibStub) then 
	error(MAJOR_VERSION .. " requires LibStub.") 
end

local lib, oldversion = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if (not lib) then 
	return 
end

-- Library registries
lib.bars = lib.bars or {}
lib.embeds = lib.embeds or {}

lib.CreateSpinBar = function(self)
end

local mixins = {
	CreateSpinBar = true
}

lib.Embed = function(self, target)
	for method in pairs(mixins) do
		target[method] = self[method]
	end
	self.embeds[target] = true
	return target
end

for target in pairs(lib.embeds) do
	lib:Embed(target)
end
