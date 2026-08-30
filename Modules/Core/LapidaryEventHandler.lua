---@class LapidaryEventHandler
---@field private table
local LapidaryEventHandler = LapidaryLoader:CreateModule("LapidaryEventHandler")
local private = LapidaryEventHandler.private

---@type LapidaryVendorFrame
local LapidaryVendorFrame = LapidaryLoader:ImportModule("LapidaryVendorFrame")
---@type LapidaryRestoreFrame
local LapidaryRestoreFrame = LapidaryLoader:ImportModule("LapidaryRestoreFrame")
---@type LapidaryCharacterPanel
local LapidaryCharacterPanel = LapidaryLoader:ImportModule("LapidaryCharacterPanel")
---@type LapidaryEquipSet
local LapidaryEquipSet = LapidaryLoader:ImportModule("LapidaryEquipSet")

function LapidaryEventHandler:RegisterEarlyEvents(frame)
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGIN")
end

function LapidaryEventHandler:RegisterLateEvents(frame)
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("MERCHANT_UPDATE")
    frame:RegisterEvent("BAG_UPDATE")
    frame:RegisterEvent("SOCKET_INFO_UPDATE")
end

function LapidaryEventHandler:BindHandlers(frame)
    if private.bound then
        return
    end
    private.bound = true

    frame.MERCHANT_SHOW = function()
        LapidaryVendorFrame:Update()
        LapidaryRestoreFrame:Update()
    end
    frame.MERCHANT_UPDATE = frame.MERCHANT_SHOW

    frame.MERCHANT_CLOSED = function()
        LapidaryVendorFrame:Hide()
        LapidaryRestoreFrame:Hide()
    end

    frame.BAG_UPDATE = function()
        LapidaryVendorFrame:Refresh()
        LapidaryRestoreFrame:Refresh()
        LapidaryCharacterPanel:Refresh()
    end
    frame.SOCKET_INFO_UPDATE = frame.BAG_UPDATE
end

function LapidaryEventHandler:OnAddonReady(frame)
    self:RegisterLateEvents(frame)
    self:BindHandlers(frame)
    LapidaryEquipSet:ScheduleInstall()
    LapidaryCharacterPanel:ScheduleInstall()
end
