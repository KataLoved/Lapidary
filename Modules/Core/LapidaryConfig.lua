---@class LapidaryConfig
local LapidaryConfig = LapidaryLoader:CreateModule("LapidaryConfig")

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")

function LapidaryConfig:GetDefaults()
    return LapidaryConstants.DEFAULTS
end

function LapidaryConfig:GetGemGroups()
    return LapidaryConstants.GEM_GROUPS
end

function LapidaryConfig:GetGroupOrder()
    return LapidaryConstants.GROUP_ORDER
end
