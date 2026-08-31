---@class LapidaryKits
local LapidaryKits = LapidaryLoader:CreateModule("LapidaryKits")

---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")
---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")
---@type LapidaryTimer
local LapidaryTimer = LapidaryLoader:ImportModule("LapidaryTimer")
---@type LapidaryGems
local LapidaryGems = LapidaryLoader:ImportModule("LapidaryGems")

local BUY_DELAY = 0.1
local buySequence = 0

---@return table @All saved kits
function LapidaryKits:Get()
    local config = LapidaryDatabase:Get()
    return config and config.kits or {}
end

---@return number|nil
function LapidaryKits:GetActiveIndex()
    local config = LapidaryDatabase:Get()
    local index = config and config.activeKit
    if index and index >= 1 and index <= #self:Get() then
        return index
    end
    return nil
end

---@return table|nil @The currently selected kit
function LapidaryKits:GetActive()
    local index = self:GetActiveIndex()
    if not index then
        return nil
    end
    return self:Get()[index]
end

---@param index number|nil
function LapidaryKits:SetActive(index)
    LapidaryDatabase:Get().activeKit = index and math.max(1, index) or nil
end

---@param defaultName string
---@return table @New empty kit, now active
function LapidaryKits:Create(defaultName)
    local kits = self:Get()
    local baseName = defaultName or "Комплект"
    local suffix = 1
    local name = baseName .. " " .. suffix
    local used = {}
    for _, existing in ipairs(kits) do
        used[existing.name] = true
    end
    while used[name] do
        suffix = suffix + 1
        name = baseName .. " " .. suffix
    end
    local kit = { name = name, items = {} }
    kits[#kits + 1] = kit
    self:SetActive(#kits)
    return kit
end

---@param defaultName string
---@return table @The first kit
function LapidaryKits:EnsureDefault(defaultName)
    local kits = self:Get()
    if #kits == 0 then
        kits[1] = { name = defaultName, items = {} }
    end
    if not self:GetActiveIndex() then
        self:SetActive(1)
    end
    return kits[1]
end

---@param index number
---@return boolean @False when the last remaining kit was left untouched
function LapidaryKits:Delete(index)
    local kits = self:Get()
    if #kits <= 1 then
        return false
    end
    tremove(kits, index)
    self:SetActive(math.min(math.max(index or 1, 1), #kits))
    return true
end

---@param kit table
---@param name string
function LapidaryKits:SetName(kit, name)
    name = name and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name ~= "" then
        kit.name = name
    end
end

local function findItem(kit, gemId)
    for _, item in ipairs(kit.items) do
        if item.id == gemId then
            return item
        end
    end
    return nil
end

---@param kit table
---@param gemId number
---@return table|nil @The stored kit item for a gem, if its quantity is set
function LapidaryKits:GetItem(kit, gemId)
    return findItem(kit, gemId)
end

---@param kit table
---@param entry LapidaryGemEntry @The cut gem row the player clicked
---@param amount number @How many of this gem to want in the kit
function LapidaryKits:AddGem(kit, entry, amount)
    local offeredId = LapidaryMerchant:GetDisplayItemId(entry.id, entry.upgradeId)
    local requiredId = offeredId or entry.id
    local item = findItem(kit, requiredId)
    if item then
        item.count = item.count + amount
    else
        kit.items[#kit.items + 1] = {
            id = requiredId,
            upgradeId = nil,
            key = entry.key,
            count = amount,
        }
    end
end

---@param kit table
---@param entry LapidaryGemEntry
---@param amount number
function LapidaryKits:RemoveGem(kit, entry, amount)
    local offeredId = LapidaryMerchant:GetDisplayItemId(entry.id, entry.upgradeId)
    local requiredId = offeredId or entry.id
    for index, item in ipairs(kit.items) do
        if item.id == requiredId then
            item.count = item.count - amount
            if item.count <= 0 then
                tremove(kit.items, index)
            end
            return
        end
    end
end

---@param item table
---@param offeredId number|nil @The exact variant currently offered by the vendor
---@return number @Owned count for the exact variant
function LapidaryKits:GetOwned(item, offeredId)
    local id = offeredId or item.id
    local owned = GetItemCount(id) or 0
    local equipped = LapidaryGems and LapidaryGems:CountSocketed(id) or 0
    return owned + equipped
end

---@param item table
---@return number|nil @The exact merchant item required for this purchase
function LapidaryKits:GetPurchaseId(item)
    if LapidaryMerchant:GetVariantMode() == "normal" then
        return item.id
    end
    return LapidaryMerchant:FindIndex(item.id) and item.id or nil
end

---@param item table
---@param offeredId number|nil @The exact variant currently offered by the vendor
---@return number @Still to buy for the exact variant
function LapidaryKits:GetMissing(item, offeredId)
    return math.max(0, item.count - self:GetOwned(item, offeredId))
end

---@param kit table
---@return number, number, number @needed, owned, missing totals
function LapidaryKits:GetTotals(kit)
    local need, owned, missing = 0, 0, 0
    for _, item in ipairs(kit.items) do
        local purchaseId = self:GetPurchaseId(item)
        if purchaseId then
            local ownedHere = self:GetOwned(item, purchaseId)
            need = need + item.count
            owned = owned + ownedHere
            missing = missing + math.max(0, item.count - ownedHere)
        end
    end
    return need, owned, missing
end

---@param kit table
---@return boolean @True when a delayed purchase sequence was started
function LapidaryKits:Buy(kit)
    if not kit or not LapidaryMerchant:IsCuttingVendor() then
        return false
    end

    buySequence = buySequence + 1
    local sequence = buySequence
    local purchases = {}
    for _, item in ipairs(kit.items) do
        local purchaseId = self:GetPurchaseId(item)
        local missing = purchaseId and self:GetMissing(item, purchaseId) or 0
        local index = purchaseId and LapidaryMerchant:FindIndex(purchaseId)
        if missing > 0 and index then
            for _ = 1, missing do
                purchases[#purchases + 1] = { index = index }
            end
        end
    end

    for order, purchase in ipairs(purchases) do
        LapidaryTimer:After((order - 1) * BUY_DELAY, function()
            if sequence == buySequence and LapidaryMerchant:IsCuttingVendor() then
                BuyMerchantItem(purchase.index, 1)
            end
        end)
    end
    return #purchases > 0
end
