---@class LapidaryBuyButton
local LapidaryBuyButton = LapidaryLoader:CreateModule("LapidaryBuyButton")

---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")
---@type LapidaryFavourites
local LapidaryFavourites = LapidaryLoader:ImportModule("LapidaryFavourites")

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local ICON = 18
local STAR = 12
local TEXT_LEFT = ICON + 6
local COUNT_WIDTH = 26

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
    if button == "RightButton" then
        LapidaryFavourites:Toggle(row.gemId)
        return
    end
    if not LapidaryMerchant:IsCuttingVendor() then
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
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(LapidaryFavourites:Has(row.gemId)
        and L.TOOLTIP_FAVOURITE_REMOVE or L.TOOLTIP_FAVOURITE_ADD, 0.6, 0.8, 1)
    GameTooltip:Show()
end

local function onLeave(row)
    row.highlight:Hide()
    GameTooltip:Hide()
end

---Points an existing row at another gem, so the list can be reordered without
---creating new frames.
---@param row table
---@param entry LapidaryGemEntry
function LapidaryBuyButton:Bind(row, entry)
    row.gemId = entry.id
    row.gemUpgradeId = entry.upgradeId
    row.labelKey = entry.key
    row.icon:SetTexture(GetItemIcon(entry.id))
end

---@param row table
function LapidaryBuyButton:Refresh(row)
    local owned = GetItemCount(row.gemId) or 0
    row.count:SetText(owned > 0 and owned or "")
    row.label:SetText(LapidaryMerchant:GetStatText(row.gemId) or L[row.labelKey])

    if LapidaryFavourites:Has(row.gemId) then
        row.star:Show()
    else
        row.star:Hide()
    end

    local available = LapidaryMerchant:FindIndex(row.gemId)
        or LapidaryMerchant:FindIndex(row.gemUpgradeId)
    row.icon:SetDesaturated(available == nil)
    row:SetAlpha(available and 1 or 0.4)
end

---@param parent table
---@param width number
---@param height number
---@return table
function LapidaryBuyButton:Create(parent, width, height)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, height)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.highlight = row:CreateTexture(nil, "BACKGROUND")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture(1, 1, 1, 0.12)
    row.highlight:Hide()

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON, ICON)
    row.icon:SetPoint("LEFT", 2, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", TEXT_LEFT, 0)
    row.label:SetWidth(width - TEXT_LEFT - COUNT_WIDTH - STAR)
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
    row.star:SetSize(STAR, STAR)
    row.star:SetPoint("RIGHT", row.count, "LEFT", -3, 0)
    row.star:SetTexture("Interface\\COMMON\\FavoritesIcon")
    row.star:SetTexCoord(0.03125, 0.8125, 0.03125, 0.8125)
    row.star:Hide()

    row:SetScript("OnClick", onClick)
    row:SetScript("OnEnter", onEnter)
    row:SetScript("OnLeave", onLeave)

    return row
end
