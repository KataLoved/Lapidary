---@class BlackDiamondsConfig
local BlackDiamondsConfig = BlackDiamondsLoader:CreateModule("BlackDiamondsConfig")

---@type BlackDiamondsConstants
local BlackDiamondsConstants = BlackDiamondsLoader:ImportModule("BlackDiamondsConstants")

function BlackDiamondsConfig:GetDefaults()
    return BlackDiamondsConstants.DEFAULTS
end

function BlackDiamondsConfig:GetGemGroups()
    return BlackDiamondsConstants.GEM_GROUPS
end

function BlackDiamondsConfig:GetGroupOrder()
    return BlackDiamondsConstants.GROUP_ORDER
end
