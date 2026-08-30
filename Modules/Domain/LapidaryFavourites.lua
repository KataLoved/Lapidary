---@class LapidaryFavourites
---@field private table
local LapidaryFavourites = LapidaryLoader:CreateModule("LapidaryFavourites")
local private = LapidaryFavourites.private

---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")

local function store()
    local config = LapidaryDatabase:Get()
    if not config then
        return nil
    end
    config.favourites = config.favourites or {}
    return config.favourites
end

---@param itemId number|nil
---@return boolean
function LapidaryFavourites:Has(itemId)
    local favourites = store()
    return itemId ~= nil and favourites ~= nil and favourites[itemId] == true
end

---@param itemId number|nil
---@return boolean @New state
function LapidaryFavourites:Toggle(itemId)
    local favourites = store()
    if not (itemId and favourites) then
        return false
    end
    local wanted = not favourites[itemId]
    favourites[itemId] = wanted or nil
    if private.onChanged then
        private.onChanged()
    end
    return wanted
end

---@param callback fun()
function LapidaryFavourites:SetChangeHandler(callback)
    private.onChanged = callback
end

---Splits gem entries into the pinned ones and the rest, keeping the original
---order inside each part.
---@param entries LapidaryGemEntry[]
---@return LapidaryGemEntry[], LapidaryGemEntry[]
function LapidaryFavourites:Split(entries)
    local pinned, rest = {}, {}
    for index = 1, #entries do
        local entry = entries[index]
        if self:Has(entry.id) then
            pinned[#pinned + 1] = entry
        else
            rest[#rest + 1] = entry
        end
    end
    return pinned, rest
end
