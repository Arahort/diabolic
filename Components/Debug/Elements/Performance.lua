local Addon, ns = ...
local Debug = ns:GetModule("Debug", true)
if (not Debug) then return end

local Performance = Debug:NewModule("Performance", "LibMoreEvents-1.0")

-- Lua API
local _G = _G
local debugprofilestop = debugprofilestop
local floor = math.floor
local format = string.format
local pairs = pairs
local select = select
local sort = table.sort
local time = time
local tonumber = tonumber
local tostring = tostring
local type = type

-- WoW API
local C_Timer = C_Timer
local GetAddOnCPUUsage = GetAddOnCPUUsage
local GetAddOnMemoryUsage = GetAddOnMemoryUsage
local GetFramerate = GetFramerate
local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local UpdateAddOnMemoryUsage = UpdateAddOnMemoryUsage

-- Performance tracking data
local eventCounts = {}
local eventCountsPerSecond = {}
local functionTimings = {}
local isMonitoring = false
local monitoringStartTime = 0
local totalMonitoringTime = 0
local samplesCollected = 0

-- Events to monitor for ActionBars
local MONITORED_EVENTS = {
	"ACTIONBAR_UPDATE_COOLDOWN",
	"ACTIONBAR_SLOT_CHANGED",
	"ACTIONBAR_UPDATE_USABLE",
	"ACTIONBAR_UPDATE_STATE",
	"ACTIONBAR_SHOWGRID",
	"ACTIONBAR_HIDEGRID",
	"ACTIONBAR_PAGE_CHANGED",
	"UPDATE_BONUS_ACTIONBAR",
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_STOP",
	"UNIT_SPELLCAST_FAILED",
	"UNIT_SPELLCAST_INTERRUPTED",
	"UNIT_SPELLCAST_SUCCEEDED",
	"PLAYER_ENTERING_WORLD",
	"PLAYER_REGEN_DISABLED",
	"PLAYER_REGEN_ENABLED"
}

-- Helper function to format numbers
local FormatNumber = function(num)
	if (num >= 1000000) then
		return format("%.2fM", num / 1000000)
	elseif (num >= 1000) then
		return format("%.2fK", num / 1000)
	else
		return format("%.0f", num)
	end
end

-- Helper function to format time
local FormatTime = function(ms)
	if (ms >= 1000) then
		return format("%.2fs", ms / 1000)
	else
		return format("%.2fms", ms)
	end
end

-- Event counter
local OnEvent = function(self, event, ...)
	if (not isMonitoring) then return end
	eventCounts[event] = (eventCounts[event] or 0) + 1
end

-- Reset counters every second
local ResetCounters
ResetCounters = function()
	if (not isMonitoring) then return end
	for event, count in pairs(eventCounts) do
		eventCountsPerSecond[event] = (eventCountsPerSecond[event] or 0) + count
	end
	eventCounts = {}
	C_Timer.After(1, function() ResetCounters() end)
end

-- Start monitoring
Performance.Start = function(self)
	if (isMonitoring) then
		print("|cffff0000Performance monitoring is already running!|r")
		return
	end
	isMonitoring = true
	monitoringStartTime = time()
	eventCounts = {}
	eventCountsPerSecond = {}
	functionTimings = {}
	samplesCollected = 0
	for i, event in ipairs(MONITORED_EVENTS) do
		self:RegisterEvent(event, OnEvent)
	end
	C_Timer.After(1, ResetCounters)
	UpdateAddOnCPUUsage()
	UpdateAddOnMemoryUsage()
	print("|cff00ff00Performance monitoring started!|r")
	print("|cffffffffCollecting data... Use '/diabolicdebug performance stop' when done.|r")
end

-- Stop monitoring
Performance.Stop = function(self)
	if (not isMonitoring) then
		print("|cffff0000Performance monitoring is not running!|r")
		return
	end
	isMonitoring = false
	totalMonitoringTime = time() - monitoringStartTime
	for i, event in ipairs(MONITORED_EVENTS) do
		self:UnregisterEvent(event)
	end
	UpdateAddOnCPUUsage()
	UpdateAddOnMemoryUsage()
	print("|cff00ff00Performance monitoring stopped!|r")
	print(format("|cffffffffCollected data for %d seconds. Use '/diabolicdebug performance report' to view.|r", totalMonitoringTime))
end

-- Generate report
Performance.Report = function(self)
	if (isMonitoring) then
		print("|cffff0000Stop monitoring first with '/diabolicdebug performance stop'|r")
		return
	end
	if (totalMonitoringTime == 0) then
		print("|cffff0000No monitoring data available. Start monitoring first with '/diabolicdebug performance start'|r")
		return
	end
	print(" ")
	print("|cff00ff00=== DiabolicUI Performance Report ===|r")
	print(format("|cffffffffMonitoring duration: %d seconds|r", totalMonitoringTime))
	print(" ")
	local cpuUsage = GetAddOnCPUUsage("DiabolicUI3")
	local memUsage = GetAddOnMemoryUsage("DiabolicUI3")
	local fps = GetFramerate()
	print("|cff00ff00System Stats:|r")
	print(format("  CPU Usage: %s", FormatTime(cpuUsage)))
	print(format("  Memory Usage: %.2f MB", memUsage / 1024))
	print(format("  Current FPS: %.0f", fps))
	print(" ")
	print("|cff00ff00Event Counts (total):|r")
	local sortedEvents = {}
	for event, count in pairs(eventCountsPerSecond) do
		table.insert(sortedEvents, {event = event, count = count})
	end
	sort(sortedEvents, function(a, b) return a.count > b.count end)
	if (#sortedEvents == 0) then
		print("  No events recorded")
	else
		for i = 1, math.min(10, #sortedEvents) do
			local data = sortedEvents[i]
			local perSecond = data.count / totalMonitoringTime
			print(format("  %s: %s (%.1f/sec)", data.event, FormatNumber(data.count), perSecond))
		end
	end
	print(" ")
	print("|cffffffffUse '/diabolicdebug performance export' to get shareable report|r")
end

-- Export report
Performance.Export = function(self)
	if (isMonitoring) then
		print("|cffff0000Stop monitoring first with '/diabolicdebug performance stop'|r")
		return
	end
	if (totalMonitoringTime == 0) then
		print("|cffff0000No monitoring data available.|r")
		return
	end
	local cpuUsage = GetAddOnCPUUsage("DiabolicUI3")
	local memUsage = GetAddOnMemoryUsage("DiabolicUI3")
	local fps = GetFramerate()
	local report = {}
	table.insert(report, "=== DiabolicUI Performance Report ===")
	table.insert(report, format("Duration: %d sec | CPU: %s | Memory: %.2f MB | FPS: %.0f",
		totalMonitoringTime, FormatTime(cpuUsage), memUsage / 1024, fps))
	table.insert(report, "")
	table.insert(report, "Top Events:")
	local sortedEvents = {}
	for event, count in pairs(eventCountsPerSecond) do
		table.insert(sortedEvents, {event = event, count = count})
	end
	sort(sortedEvents, function(a, b) return a.count > b.count end)
	for i = 1, math.min(10, #sortedEvents) do
		local data = sortedEvents[i]
		local perSecond = data.count / totalMonitoringTime
		table.insert(report, format("%s: %s (%.1f/sec)", data.event, FormatNumber(data.count), perSecond))
	end
	local exportText = table.concat(report, "\n")
	print(" ")
	print("|cff00ff00Copy the report below:|r")
	print("|cffffffff" .. exportText .. "|r")
	print(" ")
	local exportFrame = _G.DiabolicDebugExportFrame
	if (not exportFrame) then
		exportFrame = CreateFrame("Frame", "DiabolicDebugExportFrame", UIParent, "DialogBoxFrame")
		exportFrame:SetSize(500, 400)
		exportFrame:SetPoint("CENTER")
		exportFrame:SetFrameStrata("DIALOG")
		exportFrame:EnableMouse(true)
		exportFrame:SetMovable(true)
		exportFrame:RegisterForDrag("LeftButton")
		exportFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
		exportFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
		local title = exportFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		title:SetPoint("TOP", 0, -5)
		title:SetText("Performance Report")
		local scrollFrame = CreateFrame("ScrollFrame", nil, exportFrame, "UIPanelScrollFrameTemplate")
		scrollFrame:SetPoint("TOPLEFT", 10, -30)
		scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
		local editBox = CreateFrame("EditBox", nil, scrollFrame)
		editBox:SetMultiLine(true)
		editBox:SetAutoFocus(false)
		editBox:SetFontObject(ChatFontNormal)
		editBox:SetWidth(450)
		editBox:SetScript("OnEscapePressed", function() exportFrame:Hide() end)
		scrollFrame:SetScrollChild(editBox)
		exportFrame.editBox = editBox
		local closeButton = CreateFrame("Button", nil, exportFrame, "UIPanelButtonTemplate")
		closeButton:SetSize(100, 22)
		closeButton:SetPoint("BOTTOM", 0, 10)
		closeButton:SetText("Close")
		closeButton:SetScript("OnClick", function() exportFrame:Hide() end)
	end
	exportFrame.editBox:SetText(exportText)
	exportFrame.editBox:HighlightText()
	exportFrame.editBox:SetFocus()
	exportFrame:Show()
end

-- Command handler
Performance.HandleCommand = function(self, command, ...)
	if (command == "start") then
		self:Start()
	elseif (command == "stop") then
		self:Stop()
	elseif (command == "report") then
		self:Report()
	elseif (command == "export") then
		self:Export()
	else
		print("|cffff0000Unknown performance command. Available commands:|r")
		print("  start, stop, report, export")
	end
end

Performance.OnInit = function(self)
	print("|cff00ff00Debug Performance module loaded. Type /diabolicdebug help for commands.|r")
end
