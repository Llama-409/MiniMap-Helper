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
        if MinimapCluster then
            BuffFrame:SetPoint("TOPRIGHT", MinimapCluster, "TOPLEFT", -15, -15) -- Added Y padding
        else
            BuffFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -230, -13)
        end
        if DebuffFrame then
            DebuffFrame:ClearAllPoints()
            DebuffFrame:SetPoint("TOPRIGHT", BuffFrame, "BOTTOMRIGHT", 0, -8)
        end
    end
end

-- Improved function to check instance type and hide/show minimap and move buffs
local function UpdateMinimapVisibility()
    local inInstance, instanceType = IsInInstance()
    local hideMinimap = false

    if inInstance then
        if instanceType == "arena" and MinimapHelperDB.hideInArena then
            hideMinimap = true
        elseif instanceType == "pvp" and MinimapHelperDB.hideInBG then
            hideMinimap = true
        end
    end

    if MinimapCluster then
        if hideMinimap then
            Minimap:Hide()
            MinimapCluster:Hide()
            Minimap:SetAlpha(0) 
            MinimapCluster:SetAlpha(0) -- Ensure minimap is fully hidden
        else
            Minimap:Show()
            MinimapCluster:Show()
            Minimap:SetAlpha(1) -- Ensure minimap is fully hidden
            MinimapCluster:SetAlpha(1) -- Ensure minimap is fully hidden
        end
    end

    -- Move buffs/debuffs if needed
    local moveBuffs = false
    if inInstance then
        if instanceType == "arena" and MinimapHelperDB.moveBuffsInArena then
            moveBuffs = true
        elseif instanceType == "pvp" and MinimapHelperDB.moveBuffsInBG then
            moveBuffs = true
        end
    end
    MoveBuffFrames(moveBuffs)
end

-- Listen for zone changes, group changes, and update minimap/buffs
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
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

-- Function to sync checkboxes with SavedVariables
local function SyncCheckboxes()
    arenaCheck:SetChecked(MinimapHelperDB.hideInArena)
    arenaBuffCheck:SetChecked(MinimapHelperDB.moveBuffsInArena)
    bgCheck:SetChecked(MinimapHelperDB.hideInBG)
    bgBuffCheck:SetChecked(MinimapHelperDB.moveBuffsInBG)
end

-- Ensure checkboxes reflect SavedVariables on load and when panel is shown
MinimapHelper.options:SetScript("OnShow", SyncCheckboxes)

-- Also set checkboxes on load (for first open after reload)
SyncCheckboxes()

print("Minimap Helper: Please /reload your UI after changing settings for them to take effect.")
