---@class LapidaryCharacterPanel
---@field private table
local LapidaryCharacterPanel = LapidaryLoader:CreateModule("LapidaryCharacterPanel")
local private = LapidaryCharacterPanel.private

---@type LapidarySockets
local LapidarySockets = LapidaryLoader:ImportModule("LapidarySockets")
---@type LapidaryGems
local LapidaryGems = LapidaryLoader:ImportModule("LapidaryGems")
---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")
---@type LapidaryTimer
local LapidaryTimer = LapidaryLoader:ImportModule("LapidaryTimer")

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local BUTTON_WIDTH = 74
local BUTTON_HEIGHT = 21

local function setBusy(busy)
    local frame = private.frame
    if not frame then
        return
    end
    if busy then
        frame.out:Disable()
        frame.insert:Disable()
    else
        frame.out:Enable()
        frame.insert:Enable()
    end
end

local function createFrame()
    local frame = CreateFrame("Frame", "LapidaryCharacterPanel", PaperDollFrame)
    frame:SetSize(BUTTON_WIDTH * 2 + 4, BUTTON_HEIGHT)
    frame:SetPoint("BOTTOMLEFT", PaperDollFrame, "BOTTOMLEFT", 72, 82)

    frame.out = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.out:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    frame.out:SetPoint("LEFT", 0, 0)
    frame.out:SetText(L.ACTION_REMOVE_ALL)
    frame.out:SetScript("OnClick", function()
        setBusy(true)
        LapidarySockets:RemoveAll(function()
            setBusy(false)
        end)
    end)
    frame.out:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.TOOLTIP_REMOVE_ALL, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.out:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.insert = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.insert:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    frame.insert:SetPoint("LEFT", frame.out, "RIGHT", 4, 0)
    frame.insert:SetText(L.ACTION_INSERT_ALL)
    frame.insert:SetScript("OnClick", function()
        setBusy(true)
        LapidarySockets:InsertAll(function()
            setBusy(false)
        end)
    end)
    frame.insert:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.TOOLTIP_INSERT_ALL, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.insert:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return frame
end

function LapidaryCharacterPanel:Refresh()
    local frame = private.frame
    if not frame or not frame:IsShown() then
        return
    end
    local pools = LapidaryGems:CollectLoose()
    local loose = #pools.meta + #pools.big + #pools.small
    if loose > 0 then
        frame.insert:Enable()
    else
        frame.insert:Disable()
    end
    if LapidaryGems:HasSocketedLegendary() then
        frame.out:Enable()
    else
        frame.out:Disable()
    end
end

function LapidaryCharacterPanel:Update()
    local config = LapidaryDatabase:Get()
    if not (config and config.enabled) then
        if private.frame then
            private.frame:Hide()
        end
        return
    end
    if not private.frame then
        if not PaperDollFrame then
            return
        end
        private.frame = createFrame()
    end
    private.frame:Show()
    self:Refresh()
end

function LapidaryCharacterPanel:ScheduleInstall()
    if PaperDollFrame then
        self:Update()
        return
    end
    LapidaryTimer:After(1, function()
        LapidaryCharacterPanel:Update()
    end)
end
