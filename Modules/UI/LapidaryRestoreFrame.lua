---@class LapidaryRestoreFrame
---@field private table
local LapidaryRestoreFrame = LapidaryLoader:CreateModule("LapidaryRestoreFrame")
local private = LapidaryRestoreFrame.private

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")
---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")
---@type LapidaryGems
local LapidaryGems = LapidaryLoader:ImportModule("LapidaryGems")
---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local PADDING = 10
local ICON = 24
local SPACING = 3
local WIDTH = 200
local MAX_ROW = 7

local function countCutGemsInBags()
    local counts, order = {}, {}
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemId = GetContainerItemID(bag, slot)
            if itemId and LapidaryGems:Classify(itemId) then
                if not counts[itemId] then
                    order[#order + 1] = itemId
                end
                local _, stack = GetContainerItemInfo(bag, slot)
                counts[itemId] = (counts[itemId] or 0) + (stack or 1)
            end
        end
    end
    return counts, order
end

local function acquireIcon(frame, index)
    local icons = frame.icons
    if icons[index] then
        return icons[index]
    end
    local button = CreateFrame("Frame", nil, frame)
    button:SetSize(ICON, ICON)
    button.texture = button:CreateTexture(nil, "ARTWORK")
    button.texture:SetAllPoints()
    button.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", 0, 1)
    icons[index] = button
    return button
end

local function createFrame()
    local frame = CreateFrame("Frame", "LapidaryRestorePanel", MerchantFrame)
    frame:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", -4, -12)
    frame:SetFrameStrata("HIGH")
    frame:SetWidth(WIDTH)
    frame.icons = {}

    frame.backdrop = frame:CreateTexture(nil, "BACKGROUND")
    frame.backdrop:SetAllPoints()
    frame.backdrop:SetTexture(0, 0, 0, 0.85)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    frame.title:SetText(L.RESTORE_TITLE)

    frame.costLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.costLabel:SetPoint("TOPLEFT", PADDING, -PADDING - 20)
    frame.costLabel:SetText(L.RESTORE_COST)

    frame.costIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.costIcon:SetSize(ICON, ICON)
    frame.costIcon:SetPoint("TOPLEFT", PADDING, -PADDING - 36)
    frame.costIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    frame.costText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.costText:SetPoint("LEFT", frame.costIcon, "RIGHT", 4, 0)
    frame.costText:SetWidth(WIDTH - PADDING * 2 - ICON - 4)
    frame.costText:SetJustifyH("LEFT")

    frame.button = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.button:SetSize(WIDTH - PADDING * 2, 22)
    frame.button:SetPoint("TOPLEFT", PADDING, -PADDING - 68)
    frame.button:SetText(L.RESTORE_BUTTON)
    frame.button:SetScript("OnClick", function()
        LapidaryMerchant:BuyRestore()
    end)

    frame.bagsLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.bagsLabel:SetPoint("TOPLEFT", PADDING, -PADDING - 98)
    frame.bagsLabel:SetText(L.RESTORE_IN_BAGS)

    return frame
end

local function layoutBagIcons(frame)
    local counts, order = countCutGemsInBags()
    for _, icon in pairs(frame.icons) do
        icon:Hide()
    end

    local shown = 0
    for index = 1, #order do
        local itemId = order[index]
        local icon = acquireIcon(frame, index)
        local column = (index - 1) % MAX_ROW
        local row = math.floor((index - 1) / MAX_ROW)
        icon:SetPoint("TOPLEFT", PADDING + column * (ICON + SPACING), -PADDING - 114 - row * (ICON + SPACING))
        icon.texture:SetTexture(GetItemIcon(itemId))
        icon.count:SetText(counts[itemId] > 1 and counts[itemId] or "")
        icon:Show()
        shown = index
    end

    local rows = math.max(math.ceil(shown / MAX_ROW), 1)
    frame.bagsLabel:SetText(shown > 0 and L.RESTORE_IN_BAGS or L.RESTORE_NOTHING)
    frame:SetHeight(PADDING + 114 + rows * (ICON + SPACING) + PADDING)
end

function LapidaryRestoreFrame:Refresh()
    local frame = private.frame
    if not frame or not frame:IsShown() then
        return
    end

    local cost = LapidaryMerchant:GetRestoreCost()
    if cost and cost.gemId then
        frame.costIcon:SetTexture(GetItemIcon(cost.gemId))
        frame.costIcon:Show()
        frame.costText:SetText(string.format("%s\n%s",
            GetItemInfo(cost.gemId) or "", GetCoinTextureString(cost.gold or 0)))
        frame.button:Enable()
    else
        frame.costIcon:Hide()
        frame.costText:SetText(L.RESTORE_NO_GEM)
        frame.button:Disable()
    end

    layoutBagIcons(frame)
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
