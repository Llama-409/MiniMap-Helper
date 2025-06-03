-- Create a global addon table
MinimapHelper = {}

-- SavedVariables defaults
MinimapHelperDB = MinimapHelperDB or {}
if MinimapHelperDB.hideInBG == nil then MinimapHelperDB.hideInBG = false end
if MinimapHelperDB.hideInArena == nil then MinimapHelperDB.hideInArena = false end
if MinimapHelperDB.moveBuffsInBG == nil then MinimapHelperDB.moveBuffsInBG = false end
if MinimapHelperDB.moveBuffsInArena == nil then MinimapHelperDB.moveBuffsInArena = false end

-- Create a blank options panel frame
MinimapHelper.options = CreateFrame("Frame")
MinimapHelper.options.name = "Minimap Helper"

-- Add title text to the panel
local title = MinimapHelper.options:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Minimap Helper")

-- Add info text below the title about the slash command
local infoText = MinimapHelper.options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
infoText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
infoText:SetText("Tip: Type /minimap to open this panel.")

-- Add reload note below the command tip
local reloadNote = MinimapHelper.options:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
reloadNote:SetPoint("TOPLEFT", infoText, "BOTTOMLEFT", 0, -4)
reloadNote:SetText("Note: Please /reload your UI after changing settings for them to take effect.")

-- Arena: Hide Minimap
local arenaCheck = CreateFrame("CheckButton", "MinimapHelperArenaCheck", MinimapHelper.options, "InterfaceOptionsCheckButtonTemplate")
arenaCheck:SetPoint("TOPLEFT", reloadNote, "BOTTOMLEFT", 0, -16)
_G["MinimapHelperArenaCheckText"]:SetText("Hide Minimap in Arenas")
arenaCheck:SetChecked(MinimapHelperDB.hideInArena)
arenaCheck:SetScript("OnClick", function(self)
    MinimapHelperDB.hideInArena = self:GetChecked()
end)

-- Arena: Move Buffs/Debuffs
local arenaBuffCheck = CreateFrame("CheckButton", "MinimapHelperArenaBuffCheck", MinimapHelper.options, "InterfaceOptionsCheckButtonTemplate")
arenaBuffCheck:SetPoint("TOPLEFT", arenaCheck, "BOTTOMLEFT", 24, 0)
_G["MinimapHelperArenaBuffCheckText"]:SetText("Move Buffs/Debuffs to the right")
arenaBuffCheck:SetChecked(MinimapHelperDB.moveBuffsInArena)
arenaBuffCheck:SetScript("OnClick", function(self)
    MinimapHelperDB.moveBuffsInArena = self:GetChecked()
end)

-- BG: Hide Minimap
local bgCheck = CreateFrame("CheckButton", "MinimapHelperBGCheck", MinimapHelper.options, "InterfaceOptionsCheckButtonTemplate")
bgCheck:SetPoint("TOPLEFT", arenaBuffCheck, "BOTTOMLEFT", -24, -8)
_G["MinimapHelperBGCheckText"]:SetText("Hide Minimap in Battlegrounds")
bgCheck:SetChecked(MinimapHelperDB.hideInBG)
bgCheck:SetScript("OnClick", function(self)
    MinimapHelperDB.hideInBG = self:GetChecked()
end)

-- BG: Move Buffs/Debuffs
local bgBuffCheck = CreateFrame("CheckButton", "MinimapHelperBGBuffCheck", MinimapHelper.options, "InterfaceOptionsCheckButtonTemplate")
bgBuffCheck:SetPoint("TOPLEFT", bgCheck, "BOTTOMLEFT", 24, 0)
_G["MinimapHelperBGBuffCheckText"]:SetText("Move Buffs/Debuffs to the right")
bgBuffCheck:SetChecked(MinimapHelperDB.moveBuffsInBG)
bgBuffCheck:SetScript("OnClick", function(self)
    MinimapHelperDB.moveBuffsInBG = self:GetChecked()
end)

-- Helper function to move BuffFrame and DebuffFrame
local function MoveBuffFrames(enable)
    if not BuffFrame then return end
    if enable then
        BuffFrame:ClearAllPoints()
        BuffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -30, -13)
        if DebuffFrame then
            DebuffFrame:ClearAllPoints()
            DebuffFrame:SetPoint("TOPRIGHT", BuffFrame, "BOTTOMRIGHT", 0, -8)
        end
    else
        BuffFrame:ClearAllPoints()
        BuffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -205, -13)
        if DebuffFrame then
            DebuffFrame:ClearAllPoints()
            DebuffFrame:SetPoint("TOPRIGHT", BuffFrame, "BOTTOMRIGHT", 0, -8)
        end
    end
end

-- Helper function to check instance type and hide/show minimap and move buffs
local function UpdateMinimapVisibility()
    local inInstance, instanceType = IsInInstance()
    if MinimapCluster then
        if (inInstance and instanceType == "pvp" and MinimapHelperDB.hideInBG) or
           (inInstance and instanceType == "arena" and MinimapHelperDB.hideInArena) then
            MinimapCluster:Hide()
            MinimapCluster:EnableMouse(false)
            MinimapCluster:SetAlpha(0)
        else
            MinimapCluster:EnableMouse(true)
            MinimapCluster:SetAlpha(1)
            MinimapCluster:Show()
        end
    end

    -- Always move buffs back if unchecked, even outside BG/Arena
    if (inInstance and instanceType == "pvp" and MinimapHelperDB.moveBuffsInBG) or
       (inInstance and instanceType == "arena" and MinimapHelperDB.moveBuffsInArena) then
        MoveBuffFrames(true)
        C_Timer.After(0.05, function() MoveBuffFrames(true) end)
        C_Timer.After(0.1, function() MoveBuffFrames(true) end)
    else
        MoveBuffFrames(false)
        C_Timer.After(0.05, function() MoveBuffFrames(false) end)
        C_Timer.After(0.1, function() MoveBuffFrames(false) end)
    end
end

-- Listen for zone changes, group changes, and update minimap/buffs
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:SetScript("OnEvent", function()
    UpdateMinimapVisibility()
end)

-- Function to open the options panel in either the new or old system
local function OpenOptionsPanel()
    if Settings and Settings.OpenToCategory and MinimapHelper.settingsCategory then
        Settings.OpenToCategory(MinimapHelper.settingsCategory.ID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(MinimapHelper.options)
        InterfaceOptionsFrame_OpenToCategory(MinimapHelper.options)
    else
        print("Minimap Helper: No options panel system found.")
    end
end

-- Register with new SettingsPanel if available
if Settings and Settings.RegisterCanvasLayoutCategory then
    MinimapHelper.settingsCategory = Settings.RegisterCanvasLayoutCategory(MinimapHelper.options, "Minimap Helper")
    Settings.RegisterAddOnCategory(MinimapHelper.settingsCategory)
else
    -- Fallback to old Interface Options
    C_Timer.After(1, function()
        if InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(MinimapHelper.options)
        end
    end)
end

-- Slash command to open the panel with /minimap
SLASH_MINIMAP1 = "/minimap"
SlashCmdList["MINIMAP"] = function()
    OpenOptionsPanel()
end

-- Add author info a few lines below the last checkbox, centered and larger font
local authorInfo = MinimapHelper.options:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
authorInfo:SetPoint("TOP", bgBuffCheck, "BOTTOM", 0, -40)
authorInfo:SetJustifyH("CENTER")
authorInfo:SetWidth(400)
authorInfo:SetText("Author: Foxyllama\nTwitch: Foxyllama\nX: Foxyllama11")

-- Ensure checkboxes reflect SavedVariables on load and when panel is shown
MinimapHelper.options:SetScript("OnShow", function()
    arenaCheck:SetChecked(MinimapHelperDB.hideInArena)
    arenaBuffCheck:SetChecked(MinimapHelperDB.moveBuffsInArena)
    bgCheck:SetChecked(MinimapHelperDB.hideInBG)
    bgBuffCheck:SetChecked(MinimapHelperDB.moveBuffsInBG)
end)

-- Also set checkboxes on load (for first open after reload)
arenaCheck:SetChecked(MinimapHelperDB.hideInArena)
arenaBuffCheck:SetChecked(MinimapHelperDB.moveBuffsInArena)
bgCheck:SetChecked(MinimapHelperDB.hideInBG)
bgBuffCheck:SetChecked(MinimapHelperDB.moveBuffsInBG)

print("Minimap Helper: Please /reload your UI after changing settings for them to take effect.")