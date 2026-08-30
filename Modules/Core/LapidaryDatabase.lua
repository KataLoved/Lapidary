---@class LapidaryDatabase
---@field private table
local LapidaryDatabase = LapidaryLoader:CreateModule("LapidaryDatabase")
local private = LapidaryDatabase.private

---@type LapidaryConfig
local LapidaryConfig = LapidaryLoader:ImportModule("LapidaryConfig")

local function copyDefaults(dst, src)
    for key, value in pairs(src) do
        if type(value) == "table" then
            if type(dst[key]) ~= "table" then
                dst[key] = {}
            end
            copyDefaults(dst[key], value)
        elseif dst[key] == nil then
            dst[key] = value
        end
    end
    return dst
end

---@param charKey string
---@return table
function LapidaryDatabase:Open(charKey)
    LapidaryDB = LapidaryDB or {}
    LapidaryDB.profiles = LapidaryDB.profiles or {}
    LapidaryDB.profiles[charKey] = LapidaryDB.profiles[charKey] or {}

    private.charKey = charKey
    private.config = copyDefaults(LapidaryDB.profiles[charKey], LapidaryConfig:GetDefaults())
    return private.config
end

---@return table|nil
function LapidaryDatabase:Get()
    return private.config
end

function LapidaryDatabase:ResetProfile()
    if not private.charKey then
        return
    end
    LapidaryDB.profiles[private.charKey] = {}
    private.config = copyDefaults(LapidaryDB.profiles[private.charKey], LapidaryConfig:GetDefaults())
    return private.config
end
