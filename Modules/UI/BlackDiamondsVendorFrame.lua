---@class BlackDiamondsVendorFrame
---@field private table
local BlackDiamondsVendorFrame = BlackDiamondsLoader:CreateModule("BlackDiamondsVendorFrame")
local private = BlackDiamondsVendorFrame.private

---@type BlackDiamondsConstants
local BlackDiamondsConstants = BlackDiamondsLoader:ImportModule("BlackDiamondsConstants")
---@type BlackDiamondsMerchant
local BlackDiamondsMerchant = BlackDiamondsLoader:ImportModule("BlackDiamondsMerchant")
---@type BlackDiamondsBuyButton
local BlackDiamondsBuyButton = BlackDiamondsLoader:ImportModule("BlackDiamondsBuyButton")
---@type BlackDiamondsSockets
local BlackDiamondsSockets = BlackDiamondsLoader:ImportModule("BlackDiamondsSockets")
---@type BlackDiamondsDatabase
local BlackDiamondsDatabase = BlackDiamondsLoader:ImportModule("BlackDiamondsDatabase")

local L = LibStub("AceLocale-3.0"):GetLocale("BlackDiamonds", true)

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
    local config = BlackDiamondsDatabase:Get() or BlackDiamondsConstants.DEFAULTS
    local size = config.buttonSize
    local perRow = config.buttonsPerRow
    local width = perRow * (size + SPACING) - SPACING

    frame.buttons = {}
    local y = -PADDING - 34

    for _, groupKey in ipairs(BlackDiamondsConstants.GROUP_ORDER) do
        local entries = BlackDiamondsConstants.GEM_GROUPS[groupKey]
        local header = createHeader(frame, L[BlackDiamondsConstants.GROUP_TITLE_KEYS[groupKey]])
        header:SetPoint("TOPLEFT", PADDING, y)
        y = y - HEADER_HEIGHT

        for index = 1, #entries do
            local column = (index - 1) % perRow
            local row = math.floor((index - 1) / perRow)
            local button = BlackDiamondsBuyButton:Create(frame, entries[index], size)
            button:SetPoint("TOPLEFT", PADDING + column * (size + SPACING), y - row * (size + SPACING))
            frame.buttons[#frame.buttons + 1] = button
        end

        local rows = math.ceil(#entries / perRow)
        y = y - rows * (size + SPACING) - SPACING
    end

    frame.actionOut = createActionButton(frame, L["ACTION_REMOVE_ALL"], width / 2 - 2, function()
        BlackDiamondsSockets:RemoveAll()
    end)
    frame.actionOut:SetPoint("TOPLEFT", PADDING, y - 4)

    frame.actionIn = createActionButton(frame, L["ACTION_INSERT_ALL"], width / 2 - 2, function()
        BlackDiamondsSockets:InsertAll()
    end)
    frame.actionIn:SetPoint("TOPLEFT", PADDING + width / 2 + 2, y - 4)

    y = y - 28
    frame:SetSize(width + PADDING * 2, math.abs(y) + PADDING)
end

local function createFrame()
    local frame = CreateFrame("Frame", "BlackDiamondsVendorPanel", MerchantFrame)
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
        BlackDiamondsMerchant:GetCurrencyCount(),
        GetItemCount(BlackDiamondsConstants.SHARD_ID) or 0
    )
end

function BlackDiamondsVendorFrame:Refresh()
    local frame = private.frame
    if not frame or not frame:IsShown() then
        return
    end
    refreshCounters(frame)
    for i = 1, #frame.buttons do
        BlackDiamondsBuyButton:Refresh(frame.buttons[i])
    end
end

function BlackDiamondsVendorFrame:Update()
    local config = BlackDiamondsDatabase:Get()
    if not (config and config.enabled and config.showVendorPanel) then
        if private.frame then
            private.frame:Hide()
        end
        return
    end

    if not BlackDiamondsMerchant:IsCuttingVendor() then
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

function BlackDiamondsVendorFrame:Hide()
    if private.frame then
        private.frame:Hide()
    end
end

---@return boolean
function BlackDiamondsVendorFrame:IsShown()
    return private.frame ~= nil and private.frame:IsShown()
end
