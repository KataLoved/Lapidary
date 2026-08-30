---@class LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:CreateModule("LapidaryMerchant")

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")

local CURRENCY_ID = LapidaryConstants.CURRENCY_ID

---@param index number
---@return number|nil
function LapidaryMerchant:GetItemIdAt(index)
    local link = GetMerchantItemLink(index)
    if not link then
        return nil
    end
    return tonumber(link:match("item:(%d+)"))
end

---@param itemId number|nil
---@return number|nil @Merchant index
function LapidaryMerchant:FindIndex(itemId)
    if not itemId then
        return nil
    end
    for index = 1, GetMerchantNumItems() do
        if self:GetItemIdAt(index) == itemId then
            return index
        end
    end
    return nil
end

---@return boolean @True when the open merchant is the gem-cutting list
function LapidaryMerchant:IsCuttingVendor()
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        return false
    end
    local count = GetMerchantNumItems()
    if not count or count < 2 then
        return false
    end
    return self:GetItemIdAt(1) ~= CURRENCY_ID
end

---@return boolean @True when the open merchant is the "return to base gem" list
function LapidaryMerchant:IsRestoreVendor()
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        return false
    end
    return GetMerchantNumItems() == 1 and self:GetItemIdAt(1) == CURRENCY_ID
end

---@param index number
---@return number|nil, string|nil @Item id and link of the extra cost Sirus shows next to the price
function LapidaryMerchant:GetAltCost(index)
    local page = MerchantFrame and MerchantFrame.page or 1
    local slot = index - (page - 1) * MERCHANT_ITEMS_PER_PAGE
    if slot < 1 or slot > MERCHANT_ITEMS_PER_PAGE then
        return nil, nil
    end
    local frame = _G["MerchantItem" .. slot .. "AltCurrencyFrameItem1"]
    if not (frame and frame:IsShown() and frame.itemLink) then
        return nil, nil
    end
    return tonumber(frame.itemLink:match("item:(%d+)")), frame.itemLink
end

---@return table|nil @{ gemId, gemLink, gold } describing one restore purchase
function LapidaryMerchant:GetRestoreCost()
    if not self:IsRestoreVendor() then
        return nil
    end
    local gemId, gemLink = self:GetAltCost(1)
    local price = select(3, GetMerchantItemInfo(1))
    return { gemId = gemId, gemLink = gemLink, gold = price or 0 }
end

---@return boolean
function LapidaryMerchant:BuyRestore()
    if not self:IsRestoreVendor() then
        return false
    end
    BuyMerchantItem(1, 1)
    return true
end

---@param itemId number|nil
---@param upgradeId number|nil
---@param amount number
---@return boolean, number|nil @Success and the merchant index that was used
function LapidaryMerchant:Buy(itemId, upgradeId, amount)
    local index = self:FindIndex(itemId) or self:FindIndex(upgradeId)
    if not index then
        return false, nil
    end
    for _ = 1, math.max(amount, 1) do
        BuyMerchantItem(index, 1)
    end
    return true, index
end

---@return number
function LapidaryMerchant:GetCurrencyCount()
    return GetItemCount(CURRENCY_ID) or 0
end
