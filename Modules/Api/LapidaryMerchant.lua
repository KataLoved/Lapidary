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

local rememberedGemVendor = false

---Called on MERCHANT_SHOW: the NPC guid is only reliable right then, later
---updates can fire with no unit available.
function LapidaryMerchant:RememberVendor()
    rememberedGemVendor = false
    local guid = UnitGUID("npc") or UnitGUID("target")
    if not guid then
        return
    end
    local npcId = tonumber(guid:sub(9, 12), 16)
    rememberedGemVendor = npcId ~= nil and LapidaryConstants.VENDOR_NPC_IDS[npcId] == true
end

function LapidaryMerchant:ForgetVendor()
    rememberedGemVendor = false
end

---@return boolean @True when the interacted NPC is one of the black diamond vendors
function LapidaryMerchant:IsGemVendor()
    return rememberedGemVendor
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
    if self:IsCuttingVendor() then
        return false
    end
    if not self:IsGemVendor() then
        return false
    end
    local count = GetMerchantNumItems() or 0
    return count == 0 or self:GetItemIdAt(1) == CURRENCY_ID
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

---@return table[] @One entry per offered trade-in: { index, gemId, gold }
function LapidaryMerchant:GetRestoreEntries()
    local entries = {}
    if not self:IsRestoreVendor() then
        return entries
    end
    for index = 1, GetMerchantNumItems() do
        local gemId = self:GetAltCost(index)
        local price = select(3, GetMerchantItemInfo(index))
        entries[#entries + 1] = { index = index, gemId = gemId, gold = price or 0 }
    end
    return entries
end

---@param index number @Merchant index of the trade-in to buy
---@return boolean
function LapidaryMerchant:BuyRestore(index)
    if not self:IsRestoreVendor() then
        return false
    end
    if not index or index < 1 or index > GetMerchantNumItems() then
        return false
    end
    BuyMerchantItem(index, 1)
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

local statCache = {}

---@param itemId number|nil
---@return string|nil @The "+N to stat" line from the merchant tooltip, cached per item
function LapidaryMerchant:GetStatText(itemId)
    if not itemId then
        return nil
    end
    if statCache[itemId] then
        return statCache[itemId]
    end
    local index = self:FindIndex(itemId)
    if not index then
        return nil
    end
    local tip = _G.LapidaryScanTooltip
    if not tip then
        tip = CreateFrame("GameTooltip", "LapidaryScanTooltip", UIParent, "GameTooltipTemplate")
    end
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
    tip:SetMerchantItem(index)
    local parts
    for line = 2, tip:NumLines() do
        local fontString = _G["LapidaryScanTooltipTextLeft" .. line]
        local text = fontString and fontString:GetText()
        if text and text:find("^%+") then
            parts = parts and (parts .. ", " .. text) or text
        end
    end
    if parts then
        statCache[itemId] = parts
    end
    return parts
end
