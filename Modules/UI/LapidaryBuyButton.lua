---@class LapidaryBuyButton
local LapidaryBuyButton = LapidaryLoader:CreateModule("LapidaryBuyButton")

---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")
---@type LapidaryFavorites
local LapidaryFavorites = LapidaryLoader:ImportModule("LapidaryFavorites")
---@type LapidaryVendorFrame
local LapidaryVendorFrame = LapidaryLoader:ImportModule("LapidaryVendorFrame")
local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local ICON = 18
local TEXT_LEFT = ICON + 6
local COUNT_WIDTH = 26
local FAVORITE_STAR = "Interface\\COMMON\\FavoritesIcon"

local function resolveAmount()
    if IsShiftKeyDown() then
        return 10
    end
    if IsControlKeyDown() then
        return math.max(LapidaryMerchant:GetCurrencyCount(), 1)
    end
    return 1
end

local function onClick(row, button)
    if not LapidaryMerchant:IsCuttingVendor() then
        return
    end
    if button == "RightButton" then
        LapidaryFavorites:Toggle(row.gemId)
        LapidaryVendorFrame:Rebuild()
        return
    end
    LapidaryMerchant:Buy(row.gemId, row.gemUpgradeId, resolveAmount())
end

local function onEnter(row)
    row.highlight:Show()
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if row.gemId then
        GameTooltip:SetHyperlink("item:" .. row.gemId)
        GameTooltip:AddLine(" ")
    end
    GameTooltip:AddLine(L.TOOLTIP_BUY_ONE, 1, 1, 1)
    GameTooltip:AddLine(L.TOOLTIP_BUY_TEN, 1, 1, 1)
    GameTooltip:AddLine(L.TOOLTIP_BUY_ALL, 1, 1, 1)
    local hint = LapidaryFavorites:IsFavorite(row.gemId) and L.TOOLTIP_FAVORITE_REMOVE
        or L.TOOLTIP_FAVORITE_ADD
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(hint, 1, 0.82, 0)
    GameTooltip:Show()
end

local function onLeave(row)
    row.highlight:Hide()
    GameTooltip:Hide()
end

---@param row table
function LapidaryBuyButton:Refresh(row)
    local offeredId = LapidaryMerchant:GetDisplayItemId(row.gemId, row.gemUpgradeId)
    row.offeredId = offeredId
    local owned = GetItemCount(row.offeredId) or 0
    row.count:SetText(owned > 0 and owned or "")

    local favorite = LapidaryFavorites:IsFavorite(row.gemId)
    if favorite then
        row.star:SetTexture(FAVORITE_STAR)
        row.star:Show()
    else
        row.star:Hide()
    end

    local stats = LapidaryMerchant:GetStatText(row.offeredId)
    row.label:SetText(stats or L[row.labelKey])

    row.icon:SetTexture(GetItemIcon(row.offeredId))

    local available = LapidaryMerchant:FindIndex(row.offeredId)
    row.icon:SetDesaturated(available == nil)
    row:SetAlpha(available and 1 or 0.4)
end

---@param parent table
---@param entry LapidaryGemEntry
---@param width number
---@param height number
---@return table
function LapidaryBuyButton:Create(parent, entry, width, height)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, height)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.gemId = entry.id
    row.gemUpgradeId = entry.upgradeId
    row.offeredId = LapidaryMerchant:GetDisplayItemId(entry.id, entry.upgradeId)
    row.labelKey = entry.key

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture(1, 1, 1, 0.12)
    row.highlight:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON, ICON)
    row.icon:SetPoint("LEFT", 2, 0)
    row.icon:SetTexture(GetItemIcon(row.offeredId))
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", TEXT_LEFT, 0)
    row.label:SetWidth(width - TEXT_LEFT - COUNT_WIDTH)
    row.label:SetJustifyH("LEFT")
    local fontPath, fontSize, fontFlags = row.label:GetFont()
    row.label:SetFont(fontPath, fontSize - 1, fontFlags)
    if row.label.SetWordWrap then
        row.label:SetWordWrap(false)
    end

    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.count:SetPoint("RIGHT", -4, 0)
    row.count:SetJustifyH("RIGHT")

    row.star = row:CreateTexture(nil, "OVERLAY")
    row.star:SetSize(18, 18)
    row.star:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", -5, 5)
    row.star:SetTexture(FAVORITE_STAR)
    row.star:Hide()

    row:SetScript("OnClick", onClick)
    row:SetScript("OnEnter", onEnter)
    row:SetScript("OnLeave", onLeave)

    return row
end
