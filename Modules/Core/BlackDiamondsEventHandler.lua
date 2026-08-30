---@class BlackDiamondsEventHandler
---@field private table
local BlackDiamondsEventHandler = BlackDiamondsLoader:CreateModule("BlackDiamondsEventHandler")
local private = BlackDiamondsEventHandler.private

---@type BlackDiamondsVendorFrame
local BlackDiamondsVendorFrame = BlackDiamondsLoader:ImportModule("BlackDiamondsVendorFrame")
---@type BlackDiamondsEquipSet
local BlackDiamondsEquipSet = BlackDiamondsLoader:ImportModule("BlackDiamondsEquipSet")

function BlackDiamondsEventHandler:RegisterEarlyEvents(frame)
    frame:RegisterEvent("ADDON_LOADED")
    frame:RegisterEvent("PLAYER_LOGIN")
end

function BlackDiamondsEventHandler:RegisterLateEvents(frame)
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("MERCHANT_UPDATE")
    frame:RegisterEvent("BAG_UPDATE")
end

function BlackDiamondsEventHandler:BindHandlers(frame)
    if private.bound then
        return
    end
    private.bound = true

    frame.MERCHANT_SHOW = function()
        BlackDiamondsVendorFrame:Update()
    end
    frame.MERCHANT_UPDATE = frame.MERCHANT_SHOW

    frame.MERCHANT_CLOSED = function()
        BlackDiamondsVendorFrame:Hide()
    end

    frame.BAG_UPDATE = function()
        BlackDiamondsVendorFrame:Refresh()
    end
end

function BlackDiamondsEventHandler:OnAddonReady(frame)
    self:RegisterLateEvents(frame)
    self:BindHandlers(frame)
    BlackDiamondsEquipSet:ScheduleInstall()
end
