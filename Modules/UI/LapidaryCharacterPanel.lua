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
---@type LapidarySkin
local LapidarySkin = LapidaryLoader:ImportModule("LapidarySkin")
---@type LapidaryTimer
local LapidaryTimer = LapidaryLoader:ImportModule("LapidaryTimer")

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local BUTTON_WIDTH = 100
local BUTTON_HEIGHT = 17
local BUTTON_GAP = 2
local BLOCK_GAP = 8
local DEFAULT_X = 80
local DEFAULT_Y = -68

local function setBusy(busy)
    local frame = private.frame
    if not frame then
        return
    end
    private.busy = busy
    if busy then
        for _, b in ipairs(frame.buttons) do
            b:Disable()
        end
    else
        LapidaryCharacterPanel:Refresh()
    end
end

local function savePosition(frame)
    local config = LapidaryDatabase:Get()
    if not config then
        return
    end
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    config.charPanelPos = { point = point, relativePoint = relativePoint, x = x, y = y }
end

local function restorePosition(frame)
    local config = LapidaryDatabase:Get()
    local saved = config and config.charPanelPos
    frame:ClearAllPoints()
    if saved and saved.point then
        frame:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
    else
        frame:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", DEFAULT_X, DEFAULT_Y)
    end
end

---@param parent table
---@param label string
---@param tooltip string
---@param handler fun()
local function makeButton(parent, label, tooltip, handler)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    button:SetText(label)
    local fontString = button:GetFontString()
    if fontString then
        fontString:SetFontObject("GameFontNormalSmall")
    end
    LapidarySkin:Button(button)
    button:SetScript("OnClick", handler)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(tooltip, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return button
end

local function createFrame()
    local frame = CreateFrame("Frame", "LapidaryCharacterButtons", UIParent)
    frame:SetSize(BUTTON_WIDTH * 2 + BLOCK_GAP, BUTTON_HEIGHT * 2 + BUTTON_GAP)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePosition(self)
    end)

    frame.outEquipped = makeButton(frame, L.ACTION_REMOVE_ALL, L.TOOLTIP_REMOVE_EQUIPPED, function()
        setBusy(true)
        LapidarySockets:RemoveAll(function() setBusy(false) end, false)
    end)
    frame.outEquipped:SetPoint("TOPLEFT", 0, 0)

    frame.inEquipped = makeButton(frame, L.ACTION_INSERT_ALL, L.TOOLTIP_INSERT_EQUIPPED, function()
        setBusy(true)
        LapidarySockets:InsertAll(function() setBusy(false) end, false)
    end)
    frame.inEquipped:SetPoint("TOPLEFT", frame.outEquipped, "BOTTOMLEFT", 0, -BUTTON_GAP)

    frame.outEverything = makeButton(frame, L.ACTION_REMOVE_EVERYTHING, L.TOOLTIP_REMOVE_EVERYTHING, function()
        setBusy(true)
        LapidarySockets:RemoveAll(function() setBusy(false) end, true)
    end)
    frame.outEverything:SetPoint("TOPLEFT", frame.outEquipped, "TOPRIGHT", BLOCK_GAP, 0)

    frame.inEverything = makeButton(frame, L.ACTION_INSERT_EVERYTHING, L.TOOLTIP_INSERT_EVERYTHING, function()
        setBusy(true)
        LapidarySockets:InsertAll(function() setBusy(false) end, true)
    end)
    frame.inEverything:SetPoint("TOPLEFT", frame.outEverything, "BOTTOMLEFT", 0, -BUTTON_GAP)

    frame.buttons = {
        frame.outEquipped, frame.inEquipped,
        frame.outEverything, frame.inEverything,
    }

    restorePosition(frame)
    return frame
end

function LapidaryCharacterPanel:ResetPosition()
    local config = LapidaryDatabase:Get()
    if config then
        config.charPanelPos = nil
    end
    if private.frame then
        restorePosition(private.frame)
    end
end

function LapidaryCharacterPanel:Refresh()
    local frame = private.frame
    if not frame or not frame:IsShown() or private.busy then
        return
    end

    local pools = LapidaryGems:CollectLoose()
    local loose = #pools.meta + #pools.big + #pools.small
    local equippedGems = #LapidaryGems:CollectSocketed(false)
    local everythingGems = #LapidaryGems:CollectSocketed(true)

    local function toggle(button, enabled)
        if enabled then button:Enable() else button:Disable() end
    end

    toggle(frame.outEquipped, equippedGems > 0)
    toggle(frame.outEverything, everythingGems > 0)
    toggle(frame.inEquipped, loose > 0)
    toggle(frame.inEverything, loose > 0)
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
    if PaperDollFrame:IsShown() then
        private.frame:Show()
        self:Refresh()
    else
        private.frame:Hide()
    end
end

function LapidaryCharacterPanel:ScheduleInstall()
    if PaperDollFrame then
        if not private.hooked then
            private.hooked = true
            PaperDollFrame:HookScript("OnShow", function()
                LapidaryCharacterPanel:Update()
            end)
            PaperDollFrame:HookScript("OnHide", function()
                if private.frame then
                    private.frame:Hide()
                end
            end)
        end
        self:Update()
        return
    end
    LapidaryTimer:After(1, function()
        LapidaryCharacterPanel:Update()
    end)
end
