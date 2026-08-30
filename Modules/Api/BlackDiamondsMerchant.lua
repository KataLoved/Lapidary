---@class BlackDiamondsMerchant
local BlackDiamondsMerchant = BlackDiamondsLoader:CreateModule("BlackDiamondsMerchant")

---@type BlackDiamondsConstants
local BlackDiamondsConstants = BlackDiamondsLoader:ImportModule("BlackDiamondsConstants")

local CURRENCY_ID = BlackDiamondsConstants.CURRENCY_ID

---@param index number
---@return number|nil
function BlackDiamondsMerchant:GetItemIdAt(index)
    local link = GetMerchantItemLink(index)
    if not link then
        return nil
    end
    return tonumber(link:match("item:(%d+)"))
end

---@param itemId number|nil
---@return number|nil @Merchant index
function BlackDiamondsMerchant:FindIndex(itemId)
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
function BlackDiamondsMerchant:IsCuttingVendor()
    if not (MerchantFrame and MerchantFrame:IsShown()) then
        return false
    end
    local count = GetMerchantNumItems()
    if not count or count < 2 then
        return false
    end
    return self:GetItemIdAt(1) ~= CURRENCY_ID
end

---@param itemId number|nil
---@param upgradeId number|nil
---@param amount number
---@return boolean, number|nil @Success and the merchant index that was used
function BlackDiamondsMerchant:Buy(itemId, upgradeId, amount)
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
function BlackDiamondsMerchant:GetCurrencyCount()
    return GetItemCount(CURRENCY_ID) or 0
end
