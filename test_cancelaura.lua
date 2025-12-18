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

-- Set macro dynamically on click - find CANCELABLE buff
testBtn:SetScript("PreClick", function(self, button)
    print("|cFFFF0000[TEST] PreClick fired!|r Button:", button)

    -- Search for first CANCELABLE buff (not passive auras)
    local foundBuff = nil
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if auraData then
            -- Check if cancelable (has duration, not from player permanent ability, etc)
            local isCancelable = auraData.isCancelable or (auraData.duration and auraData.duration > 0)
            print("|cFFFFAA00  Buff", i, ":|r", auraData.name, "Cancelable:", auraData.isCancelable, "Duration:", auraData.duration)

            if isCancelable then
                foundBuff = auraData
                break
            end
        else
            break
        end
    end

    if foundBuff then
        print("|cFF00FF00  FOUND CANCELABLE:|r", foundBuff.name, "ID:", foundBuff.spellId)
        local macroText = "/cancelaura " .. foundBuff.name
        self:SetAttribute("macrotext", macroText)
        print("|cFF00FF00  Macro set to:|r", macroText)
    else
        print("|cFFFF0000  No cancelable buffs found! Mount up or use temp buff|r")
    end
end)

print("|cFF00FF00[TEST] Created test MACRO cancelaura button in center|r")
print("|cFF00FF00[TEST] Click it to cancel first buff using /cancelaura macro|r")
