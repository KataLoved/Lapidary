---@class BlackDiamondsEquipSet
---@field private table
local BlackDiamondsEquipSet = BlackDiamondsLoader:CreateModule("BlackDiamondsEquipSet")
local private = BlackDiamondsEquipSet.private

---@type BlackDiamondsConstants
local BlackDiamondsConstants = BlackDiamondsLoader:ImportModule("BlackDiamondsConstants")
---@type BlackDiamondsSockets
local BlackDiamondsSockets = BlackDiamondsLoader:ImportModule("BlackDiamondsSockets")
---@type BlackDiamondsTimer
local BlackDiamondsTimer = BlackDiamondsLoader:ImportModule("BlackDiamondsTimer")
---@type BlackDiamondsDatabase
local BlackDiamondsDatabase = BlackDiamondsLoader:ImportModule("BlackDiamondsDatabase")

local SETTLE = BlackDiamondsConstants.EQUIP_SETTLE_DELAY

local function isEnabled()
    local config = BlackDiamondsDatabase:Get()
    return config and config.enabled and config.autoSwapOnEquipSet
end

---@param name string
function BlackDiamondsEquipSet:OnEquipSet(name)
    local original = private.original
    if not original then
        return
    end
    if not isEnabled() or private.inProgress then
        return original(name)
    end

    private.inProgress = true
    BlackDiamondsSockets:RemoveAll(function()
        original(name)
        BlackDiamondsTimer:After(SETTLE, function()
            BlackDiamondsSockets:InsertAll(function()
                private.inProgress = false
            end)
        end)
    end)
end

---@return boolean
function BlackDiamondsEquipSet:InstallHook()
    if private.installed then
        return true
    end
    if type(EquipmentManager_EquipSet) ~= "function" then
        return false
    end
    private.original = EquipmentManager_EquipSet
    EquipmentManager_EquipSet = function(name)
        BlackDiamondsEquipSet:OnEquipSet(name)
    end
    private.installed = true
    return true
end

function BlackDiamondsEquipSet:ScheduleInstall()
    if self:InstallHook() then
        return
    end
    BlackDiamondsTimer:After(1, function()
        BlackDiamondsEquipSet:InstallHook()
    end)
end

---@return boolean
function BlackDiamondsEquipSet:IsInstalled()
    return private.installed == true
end
