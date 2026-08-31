---@class LapidaryFavorites
local LapidaryFavorites = LapidaryLoader:CreateModule("LapidaryFavorites")

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")
---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")

local byId = {}

local function indexEntries()
    if next(byId) then
        return
    end
    for _, entries in pairs(LapidaryConstants.GEM_GROUPS) do
        for _, entry in ipairs(entries) do
            byId[entry.id] = entry
            if entry.upgradeId then
                byId[entry.upgradeId] = entry
            end
        end
    end
end

---@param gemId number
---@return LapidaryGemEntry|nil @The group entry (id, upgradeId, key) for a gem id
function LapidaryFavorites:FindEntry(gemId)
    indexEntries()
    return byId[gemId]
end

---@return number[] @Favorited gem ids, in the order they were added
function LapidaryFavorites:Get()
    local config = LapidaryDatabase:Get()
    return config and config.favorites or {}
end

---@param gemId number
---@return boolean
function LapidaryFavorites:IsFavorite(gemId)
    for _, id in ipairs(self:Get()) do
        if id == gemId then
            return true
        end
    end
    return false
end

---@param gemId number
---@return boolean @The new favorite state after toggling
function LapidaryFavorites:Toggle(gemId)
    local config = LapidaryDatabase:Get()
    local favorites = config.favorites
    for index, id in ipairs(favorites) do
        if id == gemId then
            table.remove(favorites, index)
            return false
        end
    end
    favorites[#favorites + 1] = gemId
    return true
end