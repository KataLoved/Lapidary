---@class LapidaryGems
local LapidaryGems = LapidaryLoader:CreateModule("LapidaryGems")

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")

local META_GEMS = LapidaryConstants.META_GEMS
local BIG_GEMS = LapidaryConstants.BIG_GEMS
local SMALL_GEMS = LapidaryConstants.SMALL_GEMS
local LEGENDARY = LapidaryConstants.LEGENDARY_QUALITY
local INVENTORY_SLOTS = LapidaryConstants.INVENTORY_SLOTS
local MAX_SOCKETS = 3

---@param itemId number|nil
---@return string|nil @"meta", "big" or "small"
function LapidaryGems:Classify(itemId)
    if not itemId then
        return nil
    end
    if META_GEMS[itemId] then
        return "meta"
    end
    if BIG_GEMS[itemId] then
        return "big"
    end
    if SMALL_GEMS[itemId] then
        return "small"
    end
    return nil
end

---@param itemLink string|nil
---@return boolean
local function hasLegendaryGem(itemLink)
    if not itemLink then
        return false
    end
    for index = 1, MAX_SOCKETS do
        local _, gemLink = GetItemGem(itemLink, index)
        if gemLink then
            local _, _, quality = GetItemInfo(gemLink)
            if quality == LEGENDARY then
                return true
            end
        end
    end
    return false
end

---@param includeBags boolean|nil @Also strip items sitting in bags
---@return table[] @Removal entries { bag, slot, index }
function LapidaryGems:CollectSocketed(includeBags)
    local entries = {}

    for _, slotName in ipairs(INVENTORY_SLOTS) do
        local slotId = GetInventorySlotInfo(slotName)
        local itemLink = GetInventoryItemLink("player", slotId)
        if itemLink then
            for index = 1, MAX_SOCKETS do
                local _, gemLink = GetItemGem(itemLink, index)
                if gemLink then
                    local _, _, quality = GetItemInfo(gemLink)
                    if quality == LEGENDARY then
                        entries[#entries + 1] = { bag = -1, slot = slotId, index = index }
                    end
                end
            end
        end
    end

    if includeBags then
        for bag = 0, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                local itemLink = GetContainerItemLink(bag, slot)
                if itemLink then
                    for index = 1, MAX_SOCKETS do
                        local _, gemLink = GetItemGem(itemLink, index)
                        if gemLink then
                            local _, _, quality = GetItemInfo(gemLink)
                            if quality == LEGENDARY then
                                entries[#entries + 1] = { bag = bag, slot = slot, index = index }
                            end
                        end
                    end
                end
            end
        end
    end

    return entries
end

---@return table @{ meta = {...}, big = {...}, small = {...} }, entries are { bag, slot }
function LapidaryGems:CollectLoose()
    local pools = { meta = {}, big = {}, small = {} }
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemId = GetContainerItemID(bag, slot)
            local kind = self:Classify(itemId)
            if kind then
                local pool = pools[kind]
                pool[#pool + 1] = { bag = bag, slot = slot }
            end
        end
    end
    return pools
end

---@param includeBags boolean|nil @Also target equippable items sitting in bags
---@return table[] @Targets { equipped = slotId } or { bag = b, slot = s }
function LapidaryGems:GetSocketTargets(includeBags)
    local targets = {}
    for slotId = LapidaryConstants.EQUIPPED_SLOT_MIN, LapidaryConstants.EQUIPPED_SLOT_MAX do
        if GetInventoryItemLink("player", slotId) then
            targets[#targets + 1] = { equipped = slotId }
        end
    end
    if not includeBags then
        return targets
    end
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local itemLink = GetContainerItemLink(bag, slot)
            if itemLink then
                local equipSlot = select(9, GetItemInfo(itemLink))
                if equipSlot and equipSlot ~= "" and equipSlot ~= "INVTYPE_BAG" then
                    targets[#targets + 1] = { bag = bag, slot = slot }
                end
            end
        end
    end
    return targets
end

---@return boolean
function LapidaryGems:HasSocketedLegendary()
    for _, slotName in ipairs(INVENTORY_SLOTS) do
        local slotId = GetInventorySlotInfo(slotName)
        if hasLegendaryGem(GetInventoryItemLink("player", slotId)) then
            return true
        end
    end
    return false
end
