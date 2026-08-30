---@class LapidaryBuyButton
local LapidaryBuyButton = LapidaryLoader:CreateModule("LapidaryBuyButton")

---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")

local L = LibStub("AceLocale-3.0"):GetLocale("Lapidary", true)

local function resolveAmount()
    if IsShiftKeyDown() then
        return 10
    end
    if IsControlKeyDown() then
        return math.max(LapidaryMerchant:GetCurrencyCount(), 1)
    end
    return 1
end

local function onClick(button)
    if not LapidaryMerchant:IsCuttingVendor() then
        return
    end
    LapidaryMerchant:Buy(button.gemId, button.gemUpgradeId, resolveAmount())
end

local function onEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.gemId then
        GameTooltip:SetHyperlink("item:" .. button.gemId)
        GameTooltip:AddLine(" ")
    end
    GameTooltip:AddLine(L[button.labelKey], 0.6, 0.8, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["TOOLTIP_BUY_ONE"], 1, 1, 1)
    GameTooltip:AddLine(L["TOOLTIP_BUY_TEN"], 1, 1, 1)
    GameTooltip:AddLine(L["TOOLTIP_BUY_ALL"], 1, 1, 1)
    GameTooltip:Show()
end

local function onLeave()
    GameTooltip:Hide()
end

---@param button table
function LapidaryBuyButton:Refresh(button)
    local owned = GetItemCount(button.gemId) or 0
    button.count:SetText(owned > 0 and owned or "")
    local available = LapidaryMerchant:FindIndex(button.gemId)
        or LapidaryMerchant:FindIndex(button.gemUpgradeId)
    button.icon:SetDesaturated(available == nil)
    button:SetAlpha(available and 1 or 0.35)
end

---@param parent table
---@param entry LapidaryGemEntry
---@param size number
---@return table
function LapidaryBuyButton:Create(parent, entry, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)
    button:RegisterForClicks("LeftButtonUp")

    button.gemId = entry.id
    button.gemUpgradeId = entry.upgradeId
    button.labelKey = entry.key

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexture(GetItemIcon(entry.id))
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    button.border = button:CreateTexture(nil, "BORDER")
    button.border:SetPoint("TOPLEFT", -1, 1)
    button.border:SetPoint("BOTTOMRIGHT", 1, -1)
    button.border:SetTexture(0, 0, 0, 1)

    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    button.count:SetPoint("BOTTOMRIGHT", 0, 1)

    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)

    return button
end
