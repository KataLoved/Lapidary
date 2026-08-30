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
---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")
---@type LapidarySkin
local LapidarySkin = LapidaryLoader:ImportModule("LapidarySkin")

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local PADDING = 12
local COLUMN_WIDTH = 268
local COLUMN_GAP = 10
local WIDTH = PADDING * 2 + COLUMN_WIDTH * 2 + COLUMN_GAP
local ROW_HEIGHT = 20
local HEADER_HEIGHT = 18
local GROUP_GAP = 6
local GAP_FROM_MERCHANT = 12
local COLUMNS = {
    { "primary", "secondary" },
    { "hybrid", "tank" },
}

local function createHeader(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetText(text)
    label:SetJustifyH("LEFT")
    label:SetTextColor(1, 0.82, 0)
    return label
end

local function buildBody(frame)
    frame.rows = {}
    local top = -PADDING - 36
    local lowest = top

    for columnIndex = 1, #COLUMNS do
        local x = PADDING + (columnIndex - 1) * (COLUMN_WIDTH + COLUMN_GAP)
        local y = top

        for _, groupKey in ipairs(COLUMNS[columnIndex]) do
            local entries = LapidaryConstants.GEM_GROUPS[groupKey]
            local header = createHeader(frame, L[LapidaryConstants.GROUP_TITLE_KEYS[groupKey]])
            header:SetPoint("TOPLEFT", x, y)
            y = y - HEADER_HEIGHT

            for index = 1, #entries do
                local row = LapidaryBuyButton:Create(frame, entries[index], COLUMN_WIDTH, ROW_HEIGHT)
                row:SetPoint("TOPLEFT", x, y)
                frame.rows[#frame.rows + 1] = row
                y = y - ROW_HEIGHT
            end

            y = y - GROUP_GAP
        end

        if y < lowest then
            lowest = y
        end
    end

    frame:SetSize(WIDTH, math.abs(lowest) + PADDING)
end

local function createFrame()
    local frame = CreateFrame("Frame", "LapidaryVendorPanel", MerchantFrame)
    frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", GAP_FROM_MERCHANT, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)

    LapidarySkin:Frame(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    frame.title:SetText(L.PANEL_TITLE)

    frame.currency = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.currency:SetPoint("TOPLEFT", PADDING, -PADDING - 18)
    frame.currency:SetJustifyH("LEFT")

    buildBody(frame)
    return frame
end

function LapidaryVendorFrame:Refresh()
    local frame = private.frame
    if not frame or not frame:IsShown() then
        return
    end
    frame.currency:SetFormattedText(
        L.PANEL_CURRENCY,
        LapidaryMerchant:GetCurrencyCount(),
        GetItemCount(LapidaryConstants.SHARD_ID) or 0
    )
    for i = 1, #frame.rows do
        LapidaryBuyButton:Refresh(frame.rows[i])
    end
end

function LapidaryVendorFrame:Update()
    local config = LapidaryDatabase:Get()
    if not (config and config.enabled and config.showVendorPanel and LapidaryMerchant:IsCuttingVendor()) then
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
