---@class LapidaryLocale
---@field private table
local LapidaryLocale = LapidaryLoader:CreateModule("LapidaryLocale")
local private = LapidaryLocale.private

private.active = {}
private.fallback = {}

local proxy = setmetatable({}, {
    __index = function(_, key)
        return private.active[key] or private.fallback[key] or key
    end,
    __newindex = function()
    end,
})

---@param locale string
---@param strings table<string, string>
---@param isDefault boolean|nil
function LapidaryLocale:Register(locale, strings, isDefault)
    if isDefault then
        private.fallback = strings
    end
    if locale == GetLocale() then
        private.active = strings
    end
end

---@return table<string, string>
function LapidaryLocale:Get()
    return proxy
end
