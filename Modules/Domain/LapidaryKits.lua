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
---@type LapidaryFavorites
local LapidaryFavorites = LapidaryLoader:ImportModule("LapidaryFavorites")
---@type LapidarySockets
local LapidarySockets = LapidaryLoader:ImportModule("LapidarySockets")
---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")

local BUY_DELAY = LapidaryConstants.KIT_BUY_DELAY
local BUY_BATCH = LapidaryConstants.KIT_BUY_BATCH
local BATCH_SETTLE = LapidaryConstants.KIT_BATCH_SETTLE
local buySequence = 0

---Kits store the base gem id, never the variant that happened to be on sale
---when the gem was added: the charged branch sells a different item id for the
---same stat, and a kit built on one branch has to keep working on the other.
---@param gemId number
---@return number, number|nil @Base id and its upgrade, falling back to the id itself
local function baseIds(gemId)
    local entry = LapidaryFavorites:FindEntry(gemId)
    if not entry then
        return gemId, nil
    end
    return entry.id, entry.upgradeId
end

---@param gemId number
---@return number @The variant this vendor branch actually sells
local function variantOf(gemId)
    local id, upgradeId = baseIds(gemId)
    return LapidaryMerchant:GetDisplayItemId(id, upgradeId) or id
end

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
    local suffix = 1
    local name = defaultName .. " " .. suffix
    local used = {}
    for _, existing in ipairs(kits) do
        used[existing.name] = true
    end
    while used[name] do
        suffix = suffix + 1
        name = defaultName .. " " .. suffix
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
    table.remove(kits, index)
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
    local id = baseIds(gemId)
    for _, item in ipairs(kit.items) do
        if baseIds(item.id) == id then
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
    local item = findItem(kit, entry.id)
    if item then
        item.count = item.count + amount
        return
    end
    kit.items[#kit.items + 1] = {
        id = entry.id,
        upgradeId = nil,
        key = entry.key,
        count = amount,
    }
end

---@param kit table
---@param entry LapidaryGemEntry
---@param amount number
function LapidaryKits:RemoveGem(kit, entry, amount)
    local wanted = baseIds(entry.id)
    for index, item in ipairs(kit.items) do
        if baseIds(item.id) == wanted then
            item.count = item.count - amount
            if item.count <= 0 then
                table.remove(kit.items, index)
            end
            return
        end
    end
end

---@param item table
---@param offeredId number|nil @Pass nil to count whichever variant is on sale
---@return number @Owned count for that variant, bags plus sockets
function LapidaryKits:GetOwned(item, offeredId)
    local id = offeredId or variantOf(item.id)
    local owned = GetItemCount(id) or 0
    local equipped = LapidaryGems and LapidaryGems:CountSocketed(id) or 0
    return owned + equipped
end

---@param item table
---@return number|nil @The item id this vendor branch sells for that kit entry
function LapidaryKits:GetPurchaseId(item)
    return variantOf(item.id)
end

---@param item table
---@param offeredId number|nil @Pass nil to measure against the variant on sale
---@return number @Still to buy
function LapidaryKits:GetMissing(item, offeredId)
    return math.max(0, item.count - self:GetOwned(item, offeredId))
end

---@param kit table
---@return number, number, number @needed, owned, missing totals
function LapidaryKits:GetTotals(kit)
    local need, owned, missing = 0, 0, 0
    for _, item in ipairs(kit.items) do
        local ownedHere = self:GetOwned(item, self:GetPurchaseId(item))
        need = need + item.count
        owned = owned + ownedHere
        missing = missing + math.max(0, item.count - ownedHere)
    end
    return need, owned, missing
end

---@param kit table
---@return table[] @One entry per gem still to buy, resolved to a merchant index
local function pendingPurchases(kit)
    local purchases = {}
    for _, item in ipairs(kit.items) do
        local purchaseId = LapidaryKits:GetPurchaseId(item)
        local missing = purchaseId and LapidaryKits:GetMissing(item, purchaseId) or 0
        local index = purchaseId and LapidaryMerchant:FindIndex(purchaseId)
        if missing > 0 and index then
            for _ = 1, missing do
                purchases[#purchases + 1] = { index = index }
            end
        end
    end
    return purchases
end

---Buys a few gems, sockets them, then buys a few more. Buying the whole kit up
---front would need as many free bag slots as there are gems, and sockets them
---all in one burst of server traffic.
---@param queue table[]
---@param position number
---@param sequence number
---@param onDone fun()|nil
local function runBatch(queue, position, sequence, onDone)
    if sequence ~= buySequence then
        return
    end
    if position > #queue then
        if onDone then onDone() end
        return
    end

    local last = math.min(position + BUY_BATCH - 1, #queue)
    for order = position, last do
        LapidaryTimer:After(BUY_DELAY * (order - position), function()
            if sequence == buySequence and LapidaryMerchant:IsCuttingVendor() then
                BuyMerchantItem(queue[order].index, 1)
            end
        end)
    end

    local bought = last - position + 1
    LapidaryTimer:After(BUY_DELAY * bought + BATCH_SETTLE, function()
        if sequence ~= buySequence then
            return
        end
        LapidarySockets:InsertAll(function()
            LapidaryTimer:After(BATCH_SETTLE, function()
                runBatch(queue, last + 1, sequence, onDone)
            end)
        end, false)
    end)
end

---@param kit table
---@param onDone fun()|nil
---@return boolean @True when a purchase sequence was started
function LapidaryKits:Buy(kit, onDone)
    if not kit or not LapidaryMerchant:IsCuttingVendor() then
        return false
    end

    buySequence = buySequence + 1
    local queue = pendingPurchases(kit)
    if #queue == 0 then
        return false
    end

    runBatch(queue, 1, buySequence, onDone)
    return true
end

function LapidaryKits:AbortBuy()
    buySequence = buySequence + 1
end
