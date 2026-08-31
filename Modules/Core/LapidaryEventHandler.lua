---@class LapidaryEventHandler
---@field private table
local LapidaryEventHandler = LapidaryLoader:CreateModule("LapidaryEventHandler")
local private = LapidaryEventHandler.private

---@type LapidaryVendorFrame
local LapidaryVendorFrame = LapidaryLoader:ImportModule("LapidaryVendorFrame")
---@type LapidaryKitFrame
local LapidaryKitFrame = LapidaryLoader:ImportModule("LapidaryKitFrame")
---@type LapidaryRestoreFrame
local LapidaryRestoreFrame = LapidaryLoader:ImportModule("LapidaryRestoreFrame")
---@type LapidaryCharacterPanel
local LapidaryCharacterPanel = LapidaryLoader:ImportModule("LapidaryCharacterPanel")
---@type LapidaryEquipSet
local LapidaryEquipSet = LapidaryLoader:ImportModule("LapidaryEquipSet")
---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")

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
        LapidaryMerchant:RememberVendor()
        LapidaryVendorFrame:Update()
        LapidaryRestoreFrame:Update()
    end

    frame.MERCHANT_UPDATE = function()
        LapidaryVendorFrame:Update()
        LapidaryRestoreFrame:Update()
    end

    frame.MERCHANT_CLOSED = function()
        LapidaryMerchant:ForgetVendor()
        LapidaryVendorFrame:Hide()
        LapidaryRestoreFrame:Hide()
        LapidaryKitFrame:Hide()
    end

    frame.BAG_UPDATE = function()
        LapidaryVendorFrame:Refresh()
        LapidaryRestoreFrame:Refresh()
        LapidaryKitFrame:Refresh()
        LapidaryCharacterPanel:Refresh()
    end
    frame.SOCKET_INFO_UPDATE = frame.BAG_UPDATE
end

local LATE_EVENTS = {
    "MERCHANT_SHOW", "MERCHANT_CLOSED", "MERCHANT_UPDATE",
    "BAG_UPDATE", "SOCKET_INFO_UPDATE",
}

---Drops every gameplay subscription so a disabled addon costs nothing.
function LapidaryEventHandler:Disable()
    local frame = private.frame
    if not frame then
        return
    end
    for _, event in ipairs(LATE_EVENTS) do
        frame:UnregisterEvent(event)
    end
    LapidaryVendorFrame:Hide()
    LapidaryRestoreFrame:Hide()
    LapidaryKitFrame:Hide()
    LapidaryCharacterPanel:Update()
end

function LapidaryEventHandler:Enable()
    local frame = private.frame
    if not frame then
        return
    end
    self:RegisterLateEvents(frame)
    LapidaryCharacterPanel:Update()
end

function LapidaryEventHandler:OnAddonReady(frame)
    private.frame = frame
    self:BindHandlers(frame)
    self:RegisterLateEvents(frame)
    LapidaryEquipSet:ScheduleInstall()
    LapidaryCharacterPanel:ScheduleInstall()
end
