---@class BlackDiamondsGems
local BlackDiamondsGems = BlackDiamondsLoader:CreateModule("BlackDiamondsGems")

---@type BlackDiamondsConstants
local BlackDiamondsConstants = BlackDiamondsLoader:ImportModule("BlackDiamondsConstants")

local META_GEMS = BlackDiamondsConstants.META_GEMS
local BIG_GEMS = BlackDiamondsConstants.BIG_GEMS
local SMALL_GEMS = BlackDiamondsConstants.SMALL_GEMS
local LEGENDARY = BlackDiamondsConstants.LEGENDARY_QUALITY
local INVENTORY_SLOTS = BlackDiamondsConstants.INVENTORY_SLOTS
local MAX_SOCKETS = 3

---@param itemId number|nil
---@return string|nil @"meta", "big" or "small"
function BlackDiamondsGems:Classify(itemId)
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

---@return table[] @Removal entries { bag, slot, index }
function BlackDiamondsGems:CollectSocketed()
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

    return entries
end

---@return table @{ meta = {...}, big = {...}, small = {...} }, entries are { bag, slot }
function BlackDiamondsGems:CollectLoose()
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

---@return number[] @Equipped slot ids that currently hold an item
function BlackDiamondsGems:GetOccupiedSlots()
    local slots = {}
    for slotId = BlackDiamondsConstants.EQUIPPED_SLOT_MIN, BlackDiamondsConstants.EQUIPPED_SLOT_MAX do
        if GetInventoryItemLink("player", slotId) then
            slots[#slots + 1] = slotId
        end
    end
    return slots
end

---@return boolean
function BlackDiamondsGems:HasSocketedLegendary()
    for _, slotName in ipairs(INVENTORY_SLOTS) do
        local slotId = GetInventorySlotInfo(slotName)
        if hasLegendaryGem(GetInventoryItemLink("player", slotId)) then
            return true
        end
    end
    return false
end
