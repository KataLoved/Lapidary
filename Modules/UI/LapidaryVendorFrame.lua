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
---@type LapidaryFavorites
local LapidaryFavorites = LapidaryLoader:ImportModule("LapidaryFavorites")
---@type LapidaryKitFrame
local LapidaryKitFrame = LapidaryLoader:ImportModule("LapidaryKitFrame")
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

local FAVORITE_GAP = 10
local BODY_TOP = -PADDING - 36

local function acquireRow(frame, index)
    if not frame.rows[index] then
        frame.rows[index] = LapidaryBuyButton:Create(frame, COLUMN_WIDTH, ROW_HEIGHT)
    end
    return frame.rows[index]
end

local function acquireHeader(frame, index)
    if not frame.headers[index] then
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetJustifyH("LEFT")
        label:SetTextColor(1, 0.82, 0)
        frame.headers[index] = label
    end
    return frame.headers[index]
end

---Favourited gems keep a section of their own above the two columns and are
---taken out of the group they came from, so no gem appears twice.
local function layout(frame)
    for _, row in pairs(frame.rows) do
        row:Hide()
    end
    for _, header in pairs(frame.headers) do
        header:Hide()
    end

    local usedRows, usedHeaders = 0, 0

    local function placeRow(entry, x, y)
        usedRows = usedRows + 1
        local row = acquireRow(frame, usedRows)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", x, y)
        LapidaryBuyButton:Bind(row, entry)
        row:Show()
    end

    local function placeHeader(text, x, y)
        usedHeaders = usedHeaders + 1
        local header = acquireHeader(frame, usedHeaders)
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", x, y)
        header:SetText(text)
        header:Show()
    end

    local pinned = {}
    for _, gemId in ipairs(LapidaryFavorites:Get()) do
        local entry = LapidaryFavorites:FindEntry(gemId)
        if entry then
            pinned[#pinned + 1] = entry
        end
    end

    local top = BODY_TOP

    if #pinned > 0 then
        placeHeader(L.GROUP_FAVORITES, PADDING, top)
        top = top - HEADER_HEIGHT - FAVORITE_GAP
        for index = 1, #pinned do
            local column = (index - 1) % 2
            local row = math.floor((index - 1) / 2)
            placeRow(pinned[index],
                PADDING + column * (COLUMN_WIDTH + COLUMN_GAP),
                top - row * ROW_HEIGHT)
        end
        top = top - math.ceil(#pinned / 2) * ROW_HEIGHT - FAVORITE_GAP
    end

    local lowest = top
    for columnIndex = 1, #COLUMNS do
        local x = PADDING + (columnIndex - 1) * (COLUMN_WIDTH + COLUMN_GAP)
        local y = top

        for _, groupKey in ipairs(COLUMNS[columnIndex]) do
            local entries = LapidaryConstants.GEM_GROUPS[groupKey]
            placeHeader(L[LapidaryConstants.GROUP_TITLE_KEYS[groupKey]], x, y)
            y = y - HEADER_HEIGHT

            for index = 1, #entries do
                local entry = entries[index]
                if not LapidaryFavorites:IsFavorite(entry.id) then
                    placeRow(entry, x, y)
                    y = y - ROW_HEIGHT
                end
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
    local frame = CreateFrame("Frame", "LapidaryVendorPanel", UIParent)
    frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", GAP_FROM_MERCHANT, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame.rows = {}
    frame.headers = {}

    LapidarySkin:Frame(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    frame.title:SetText(L.PANEL_TITLE)

    frame.currency = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.currency:SetPoint("TOPLEFT", PADDING, -PADDING - 18)
    frame.currency:SetJustifyH("LEFT")

    frame.kitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.kitButton:SetSize(100, 20)
    frame.kitButton:SetPoint("TOPRIGHT", -PADDING, -PADDING)
    frame.kitButton:SetText(L.KIT_BUTTON)
    LapidarySkin:Button(frame.kitButton)
    frame.kitButton:SetScript("OnClick", function(button)
        LapidaryKitFrame:Toggle()
        button:SetText(LapidaryKitFrame:IsShown() and L.KIT_BUTTON_HIDE or L.KIT_BUTTON)
    end)
    frame.kitButton:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.KIT_TOGGLE_HINT)
        GameTooltip:Show()
    end)
    frame.kitButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

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
        LapidaryMerchant:GetChargedDiamondCount(),
        GetItemCount(LapidaryConstants.SHARD_ID) or 0
    )
    frame.kitButton:SetText(LapidaryKitFrame:IsShown() and L.KIT_BUTTON_HIDE or L.KIT_BUTTON)
    for index = 1, #frame.rows do
        local row = frame.rows[index]
        if row:IsShown() then
            LapidaryBuyButton:Refresh(row)
        end
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
    self:Rebuild()
end

function LapidaryVendorFrame:Rebuild()
    local frame = private.frame
    if not frame or not frame:IsShown() then
        return
    end
    layout(frame)
    self:Refresh()
end

function LapidaryVendorFrame:Hide()
    if private.frame then
        private.frame:Hide()
    end
end

---@return table|nil @The vendor panel frame handle
function LapidaryVendorFrame:GetFrame()
    return private.frame
end

---@return boolean
function LapidaryVendorFrame:IsShown()
    return private.frame ~= nil and private.frame:IsShown()
end
