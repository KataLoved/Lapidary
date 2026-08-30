---@class BlackDiamondsDatabase
---@field private table
local BlackDiamondsDatabase = BlackDiamondsLoader:CreateModule("BlackDiamondsDatabase")
local private = BlackDiamondsDatabase.private

---@type BlackDiamondsConfig
local BlackDiamondsConfig = BlackDiamondsLoader:ImportModule("BlackDiamondsConfig")

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
function BlackDiamondsDatabase:Open(charKey)
    BlackDiamondsDB = BlackDiamondsDB or {}
    BlackDiamondsDB.profiles = BlackDiamondsDB.profiles or {}
    BlackDiamondsDB.profiles[charKey] = BlackDiamondsDB.profiles[charKey] or {}

    private.charKey = charKey
    private.config = copyDefaults(BlackDiamondsDB.profiles[charKey], BlackDiamondsConfig:GetDefaults())
    return private.config
end

---@return table|nil
function BlackDiamondsDatabase:Get()
    return private.config
end

function BlackDiamondsDatabase:ResetProfile()
    if not private.charKey then
        return
    end
    BlackDiamondsDB.profiles[private.charKey] = {}
    private.config = copyDefaults(BlackDiamondsDB.profiles[private.charKey], BlackDiamondsConfig:GetDefaults())
    return private.config
end
