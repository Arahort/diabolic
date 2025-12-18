-- Temporary test for cancelaura
local testBtn = CreateFrame("Button", "TestCancelAuraButton", UIParent, "SecureActionButtonTemplate")
testBtn:SetSize(50, 50)
testBtn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
testBtn:SetNormalTexture("Interface\\Icons\\Spell_Magic_LesserInvisibilty")

-- Set cancelaura attributes
testBtn:SetAttribute("type", "cancelaura")
testBtn:SetAttribute("unit", "player")
testBtn:SetAttribute("index", 1)
testBtn:SetAttribute("filter", "HELPFUL")

testBtn:RegisterForClicks("RightButtonUp")

-- Add border so we can see it
local border = testBtn:CreateTexture(nil, "OVERLAY")
border:SetAllPoints()
border:SetColorTexture(1, 0, 0, 0.5)

print("|cFF00FF00[TEST] Created test cancelaura button in center of screen|r")
print("|cFF00FF00[TEST] Right-click it to cancel first buff (index=1)|r")
print("|cFF00FF00[TEST] Attributes:|r", "type=", testBtn:GetAttribute("type"), "unit=", testBtn:GetAttribute("unit"), "index=", testBtn:GetAttribute("index"), "filter=", testBtn:GetAttribute("filter"))
