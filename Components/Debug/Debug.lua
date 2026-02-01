local Addon, ns = ...
local Debug = ns:NewModule("Debug", "LibMoreEvents-1.0")

-- Lua API
local _G = _G
local string_format = string.format
local string_lower = string.lower
local table_insert = table.insert

Debug.OnInit = function(self)
	-- Load Performance module
	local Performance = self:NewModule("Performance", "LibMoreEvents-1.0")
end

-- Command handler
Debug.HandleCommand = function(self, command, ...)
	command = command and string_lower(command)
	if (command == "performance") then
		local Performance = self:GetModule("Performance", true)
		if (Performance) then
			Performance:HandleCommand(...)
		else
			print("|cffff0000Debug Performance module not loaded!|r")
		end
	elseif (command == "help") then
		print("|cff00ff00DiabolicUI Debug Commands:|r")
		print("  /diabolicdebug performance start - Start performance monitoring")
		print("  /diabolicdebug performance stop - Stop performance monitoring")
		print("  /diabolicdebug performance report - Show performance report")
		print("  /diabolicdebug performance export - Export report for sharing")
		print("  /diabolicdebug help - Show this help")
	else
		print("|cffff0000Unknown debug command. Type /diabolicdebug help for help.|r")
	end
end

-- Register slash command
_G.SLASH_DIABOLICDEBUG1 = "/diabolicdebug"
_G.SlashCmdList.DIABOLICDEBUG = function(msg)
	local command, arg1, arg2, arg3 = string.match(msg, "^(%S+)%s*(%S*)%s*(%S*)%s*(%S*)")
	Debug:HandleCommand(command, arg1, arg2, arg3)
end
