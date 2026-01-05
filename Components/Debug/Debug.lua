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
