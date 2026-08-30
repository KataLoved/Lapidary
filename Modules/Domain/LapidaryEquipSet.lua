---@class LapidaryEquipSet
---@field private table
local LapidaryEquipSet = LapidaryLoader:CreateModule("LapidaryEquipSet")
local private = LapidaryEquipSet.private

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")
---@type LapidarySockets
local LapidarySockets = LapidaryLoader:ImportModule("LapidarySockets")
---@type LapidaryTimer
local LapidaryTimer = LapidaryLoader:ImportModule("LapidaryTimer")
---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")

local SETTLE = LapidaryConstants.EQUIP_SETTLE_DELAY

local function isEnabled()
    local config = LapidaryDatabase:Get()
    return config and config.enabled and config.autoSwapOnEquipSet
end

---@param name string
function LapidaryEquipSet:OnEquipSet(name)
    local original = private.original
    if not original then
        return
    end
    if not isEnabled() or private.inProgress then
        return original(name)
    end

    private.inProgress = true
    LapidarySockets:RemoveAll(function()
        original(name)
        LapidaryTimer:After(SETTLE, function()
            LapidarySockets:InsertAll(function()
                private.inProgress = false
            end)
        end)
    end)
end

---@return boolean
function LapidaryEquipSet:InstallHook()
    if private.installed then
        return true
    end
    if type(EquipmentManager_EquipSet) ~= "function" then
        return false
    end
    private.original = EquipmentManager_EquipSet
    EquipmentManager_EquipSet = function(name)
        LapidaryEquipSet:OnEquipSet(name)
    end
    private.installed = true
    return true
end

function LapidaryEquipSet:ScheduleInstall()
    if self:InstallHook() then
        return
    end
    LapidaryTimer:After(1, function()
        LapidaryEquipSet:InstallHook()
    end)
end

---@return boolean
function LapidaryEquipSet:IsInstalled()
    return private.installed == true
end
