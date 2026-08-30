---@class LapidaryRestoreFrame
---@field private table
local LapidaryRestoreFrame = LapidaryLoader:CreateModule("LapidaryRestoreFrame")
local private = LapidaryRestoreFrame.private

---@type LapidarySockets
local LapidarySockets = LapidaryLoader:ImportModule("LapidarySockets")
---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")
---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")
---@type LapidarySkin
local LapidarySkin = LapidaryLoader:ImportModule("LapidarySkin")

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local PADDING = 12
local WIDTH = 280
local ROW_HEIGHT = 22
local ICON = 18
local HEADER = 54
local ACTION_HEIGHT = 22
local GAP_FROM_MERCHANT = 12

local function onRowClick(row)
    LapidaryMerchant:BuyRestore(row.merchantIndex)
end

local function onRowEnter(row)
    row.highlight:Show()
    if row.gemId then
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink("item:" .. row.gemId)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L.RESTORE_ROW_HINT, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

local function onRowLeave(row)
    row.highlight:Hide()
    GameTooltip:Hide()
end

local function acquireRow(frame, index)
    if frame.rows[index] then
        return frame.rows[index]
    end
    local row = CreateFrame("Button", nil, frame)
    row:SetSize(WIDTH - PADDING * 2, ROW_HEIGHT)
    row:RegisterForClicks("LeftButtonUp")

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture(1, 1, 1, 0.12)
    row.highlight:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON, ICON)
    row.icon:SetPoint("LEFT", 2, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", ICON + 6, 0)
    row.label:SetPoint("RIGHT", -60, 0)
    row.label:SetJustifyH("LEFT")
    local fontPath, fontSize, fontFlags = row.label:GetFont()
    row.label:SetFont(fontPath, fontSize - 1, fontFlags)

    row.price = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.price:SetPoint("RIGHT", -2, 0)
    row.price:SetJustifyH("RIGHT")

    row:SetScript("OnClick", onRowClick)
    row:SetScript("OnEnter", onRowEnter)
    row:SetScript("OnLeave", onRowLeave)

    frame.rows[index] = row
    return row
end

local function createFrame()
    local frame = CreateFrame("Frame", "LapidaryRestorePanel", UIParent)
    frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", GAP_FROM_MERCHANT, 0)
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetWidth(WIDTH)
    frame.rows = {}

    LapidarySkin:Frame(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    frame.title:SetText(L.RESTORE_TITLE)

    frame.hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.hint:SetPoint("TOPLEFT", PADDING, -PADDING - 18)
    frame.hint:SetPoint("RIGHT", -PADDING, 0)
    frame.hint:SetJustifyH("LEFT")
    frame.hint:SetText(L.RESTORE_COST)

    local half = (WIDTH - PADDING * 2) / 2 - 2

    frame.actionOut = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.actionOut:SetSize(half, ACTION_HEIGHT)
    LapidarySkin:Button(frame.actionOut)
    frame.actionOut:SetText(L.ACTION_REMOVE_ALL)
    frame.actionOut:SetScript("OnClick", function()
        LapidarySockets:RemoveAll(nil, false)
    end)
    frame.actionOut:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.TOOLTIP_REMOVE_EQUIPPED, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.actionOut:SetScript("OnLeave", function() GameTooltip:Hide() end)

    frame.actionIn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.actionIn:SetSize(half, ACTION_HEIGHT)
    frame.actionIn:SetPoint("TOPLEFT", frame.actionOut, "TOPRIGHT", 4, 0)
    LapidarySkin:Button(frame.actionIn)
    frame.actionIn:SetText(L.ACTION_INSERT_ALL)
    frame.actionIn:SetScript("OnClick", function()
        LapidarySockets:InsertAll(nil, false)
    end)
    frame.actionIn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L.TOOLTIP_INSERT_EQUIPPED, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame.actionIn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return frame
end

function LapidaryRestoreFrame:Refresh()
    local frame = private.frame
    if not frame or not frame:IsShown() then
        return
    end

    local offered = LapidaryMerchant:GetRestoreEntries()
    local entries = {}
    for index = 1, #offered do
        local entry = offered[index]
        if entry.gemId and (GetItemCount(entry.gemId) or 0) > 0 then
            entries[#entries + 1] = entry
        end
    end

    for _, row in pairs(frame.rows) do
        row:Hide()
    end

    local y = -PADDING - HEADER
    for index = 1, #entries do
        local entry = entries[index]
        local row = acquireRow(frame, index)
        row:SetPoint("TOPLEFT", PADDING, y)
        row.merchantIndex = entry.index
        row.gemId = entry.gemId
        row.icon:SetTexture(entry.gemId and GetItemIcon(entry.gemId) or nil)
        local stats = LapidaryMerchant:GetItemStatText(entry.gemId)
        row.label:SetText(stats or (entry.gemId and GetItemInfo(entry.gemId)) or "?")
        local owned = entry.gemId and GetItemCount(entry.gemId) or 0
        row.price:SetText(owned > 1
            and string.format("x%d  %s", owned, GetCoinTextureString(entry.gold or 0))
            or GetCoinTextureString(entry.gold or 0))
        row:Show()
        y = y - ROW_HEIGHT
    end

    frame.hint:SetText(#entries > 0 and L.RESTORE_COST or L.RESTORE_NOTHING)

    y = y - 8
    frame.actionOut:SetPoint("TOPLEFT", PADDING, y)
    y = y - ACTION_HEIGHT

    frame:SetHeight(math.abs(y) + PADDING)
end

function LapidaryRestoreFrame:Update()
    local config = LapidaryDatabase:Get()
    if not (config and config.enabled and config.showVendorPanel and LapidaryMerchant:IsRestoreVendor()) then
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

function LapidaryRestoreFrame:Hide()
    if private.frame then
        private.frame:Hide()
    end
end
