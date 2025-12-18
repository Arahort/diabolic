-- Temporary test for cancelaura - TRY MACRO APPROACH
local testBtn = CreateFrame("Button", "TestCancelAuraButton", UIParent, "SecureActionButtonTemplate")
testBtn:SetSize(50, 50)
testBtn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
testBtn:SetNormalTexture("Interface\\Icons\\Spell_Magic_LesserInvisibilty")

-- Try using MACRO instead of cancelaura type
testBtn:SetAttribute("type", "macro")
testBtn:RegisterForClicks("AnyUp")

-- Add border so we can see it
local border = testBtn:CreateTexture(nil, "OVERLAY")
border:SetAllPoints()
border:SetColorTexture(1, 0, 0, 0.5)

-- Set macro dynamically on click
testBtn:SetScript("PreClick", function(self, button)
    print("|cFFFF0000[TEST] PreClick fired!|r Button:", button)
    local auraData = C_UnitAuras.GetAuraDataByIndex("player", 1, "HELPFUL")
    if auraData then
        print("|cFF00FF00  First buff:|r", auraData.name, "ID:", auraData.spellId)
        -- Try macro command
        local macroText = "/cancelaura " .. auraData.name
        self:SetAttribute("macrotext", macroText)
        print("|cFF00FF00  Macro set to:|r", macroText)
    else
        print("|cFFFF0000  No buffs found!|r")
    end
end)

print("|cFF00FF00[TEST] Created test MACRO cancelaura button in center|r")
print("|cFF00FF00[TEST] Click it to cancel first buff using /cancelaura macro|r")
