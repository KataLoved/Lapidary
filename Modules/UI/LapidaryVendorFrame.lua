---@class LapidaryVendorFrame
---@field private table
local LapidaryVendorFrame = LapidaryLoader:CreateModule("LapidaryVendorFrame")
local private = LapidaryVendorFrame.private

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")
---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")
---@type LapidaryBuyButton
local LapidaryBuyButton = LapidaryLoader:ImportModule("LapidaryBuyButton")
---@type LapidarySockets
local LapidarySockets = LapidaryLoader:ImportModule("LapidarySockets")
---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")

local L = LibStub("AceLocale-3.0"):GetLocale("Lapidary", true)

local PADDING = 10
local SPACING = 3
local HEADER_HEIGHT = 16

local function createHeader(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetText(text)
    label:SetJustifyH("LEFT")
    return label
end

local function createActionButton(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 20)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function buildBody(frame)
    local config = LapidaryDatabase:Get() or LapidaryConstants.DEFAULTS
    local size = config.buttonSize
    local perRow = config.buttonsPerRow
    local width = perRow * (size + SPACING) - SPACING

    frame.buttons = {}
    local y = -PADDING - 34

    for _, groupKey in ipairs(LapidaryConstants.GROUP_ORDER) do
        local entries = LapidaryConstants.GEM_GROUPS[groupKey]
        local header = createHeader(frame, L[LapidaryConstants.GROUP_TITLE_KEYS[groupKey]])
        header:SetPoint("TOPLEFT", PADDING, y)
        y = y - HEADER_HEIGHT

        for index = 1, #entries do
            local column = (index - 1) % perRow
            local row = math.floor((index - 1) / perRow)
            local button = LapidaryBuyButton:Create(frame, entries[index], size)
            button:SetPoint("TOPLEFT", PADDING + column * (size + SPACING), y - row * (size + SPACING))
            frame.buttons[#frame.buttons + 1] = button
        end

        local rows = math.ceil(#entries / perRow)
        y = y - rows * (size + SPACING) - SPACING
    end

    frame.actionOut = createActionButton(frame, L["ACTION_REMOVE_ALL"], width / 2 - 2, function()
        LapidarySockets:RemoveAll()
    end)
    frame.actionOut:SetPoint("TOPLEFT", PADDING, y - 4)

    frame.actionIn = createActionButton(frame, L["ACTION_INSERT_ALL"], width / 2 - 2, function()
        LapidarySockets:InsertAll()
    end)
    frame.actionIn:SetPoint("TOPLEFT", PADDING + width / 2 + 2, y - 4)

    y = y - 28
    frame:SetSize(width + PADDING * 2, math.abs(y) + PADDING)
end

local function createFrame()
    local frame = CreateFrame("Frame", "LapidaryVendorPanel", MerchantFrame)
    frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", -4, -12)
    frame:SetFrameStrata("HIGH")

    frame.backdrop = frame:CreateTexture(nil, "BACKGROUND")
    frame.backdrop:SetAllPoints()
    frame.backdrop:SetTexture(0, 0, 0, 0.85)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    frame.title:SetText(L["PANEL_TITLE"])

    frame.currency = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.currency:SetPoint("TOPLEFT", PADDING, -PADDING - 16)
    frame.currency:SetJustifyH("LEFT")

    buildBody(frame)
    return frame
end

local function refreshCounters(frame)
    frame.currency:SetFormattedText(
        L["PANEL_CURRENCY"],
        LapidaryMerchant:GetCurrencyCount(),
        GetItemCount(LapidaryConstants.SHARD_ID) or 0
    )
end

function LapidaryVendorFrame:Refresh()
    local frame = private.frame
    if not frame or not frame:IsShown() then
        return
    end
    refreshCounters(frame)
    for i = 1, #frame.buttons do
        LapidaryBuyButton:Refresh(frame.buttons[i])
    end
end

function LapidaryVendorFrame:Update()
    local config = LapidaryDatabase:Get()
    if not (config and config.enabled and config.showVendorPanel) then
        if private.frame then
            private.frame:Hide()
        end
        return
    end

    if not LapidaryMerchant:IsCuttingVendor() then
        if private.frame then
            private.frame:Hide()
        end
        return
    end

    if not private.frame then
        private.frame = createFrame()
    end
    private.frame:Show()
    self:Refresh()
end

function LapidaryVendorFrame:Hide()
    if private.frame then
        private.frame:Hide()
    end
end

---@return boolean
function LapidaryVendorFrame:IsShown()
    return private.frame ~= nil and private.frame:IsShown()
end
