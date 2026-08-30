---@class BlackDiamondsBootstrap
---@field private table
local BlackDiamondsBootstrap = BlackDiamondsLoader:CreateModule("BlackDiamondsBootstrap")
local private = BlackDiamondsBootstrap.private

---@type BlackDiamondsDatabase
local BlackDiamondsDatabase = BlackDiamondsLoader:ImportModule("BlackDiamondsDatabase")
---@type BlackDiamondsRuntime
local BlackDiamondsRuntime = BlackDiamondsLoader:ImportModule("BlackDiamondsRuntime")
---@type BlackDiamondsServer
local BlackDiamondsServer = BlackDiamondsLoader:ImportModule("BlackDiamondsServer")
---@type BlackDiamondsSockets
local BlackDiamondsSockets = BlackDiamondsLoader:ImportModule("BlackDiamondsSockets")
---@type BlackDiamondsEquipSet
local BlackDiamondsEquipSet = BlackDiamondsLoader:ImportModule("BlackDiamondsEquipSet")
---@type BlackDiamondsEventHandler
local BlackDiamondsEventHandler = BlackDiamondsLoader:ImportModule("BlackDiamondsEventHandler")
---@type BlackDiamondsVendorFrame
local BlackDiamondsVendorFrame = BlackDiamondsLoader:ImportModule("BlackDiamondsVendorFrame")
---@type BlackDiamondsSlash
local BlackDiamondsSlash = BlackDiamondsLoader:ImportModule("BlackDiamondsSlash")
---@type BlackDiamondsMerchant
local BlackDiamondsMerchant = BlackDiamondsLoader:ImportModule("BlackDiamondsMerchant")

local L = LibStub("AceLocale-3.0"):GetLocale("BlackDiamonds", true)

function BlackDiamondsBootstrap:BuildStatus()
    local config = BlackDiamondsDatabase:Get()
    local removed, slots = BlackDiamondsSockets:GetLastCounts()
    return {
        format(L["STATUS_ENABLED"], tostring(config.enabled)),
        format(L["STATUS_AUTO_SWAP"], tostring(config.autoSwapOnEquipSet)),
        format(L["STATUS_HOOK"], tostring(BlackDiamondsEquipSet:IsInstalled())),
        format(L["STATUS_CURRENCY"], BlackDiamondsMerchant:GetCurrencyCount()),
        format(L["STATUS_LAST_RUN"], tostring(removed or 0), tostring(slots or 0)),
    }
end

function BlackDiamondsBootstrap:RegisterSlash()
    BlackDiamondsSlash:Register({
        removeAll = function()
            BlackDiamondsSockets:RemoveAll()
        end,
        insertAll = function()
            BlackDiamondsSockets:InsertAll()
        end,
        swapAll = function()
            BlackDiamondsSockets:SwapAll()
        end,
        toggle = function()
            local config = BlackDiamondsDatabase:Get()
            config.enabled = not config.enabled
            BlackDiamondsVendorFrame:Update()
            return config.enabled
        end,
        status = function()
            return BlackDiamondsBootstrap:BuildStatus()
        end,
    })
end

function BlackDiamondsBootstrap:OnPlayerLogin()
    local frame = private.frame

    BlackDiamondsDatabase:Open(private.charKey)
    BlackDiamondsServer:Initialize()

    frame:SetScript("OnEvent", function(self, event, ...)
        local handler = self[event]
        if handler then
            handler(self, event, ...)
        end
    end)

    BlackDiamondsRuntime:Set({
        addonName = private.addonName,
        charKey = private.charKey,
        config = BlackDiamondsDatabase:Get(),
    })

    BlackDiamondsEventHandler:OnAddonReady(frame)
    self:RegisterSlash()
end

function BlackDiamondsBootstrap:OnEvent(_, event, name)
    if event == "ADDON_LOADED" and name == private.addonName then
        private.loaded = true
    end
    if not (private.loaded and IsLoggedIn()) then
        return
    end
    if private.started then
        return
    end
    private.started = true
    self:OnPlayerLogin()
end

function BlackDiamondsBootstrap:Start(frame, addonName)
    private.frame = frame
    private.addonName = addonName
    private.loaded = false
    private.started = false
    private.charKey = UnitName("player") .. " - " .. GetRealmName()

    BlackDiamondsEventHandler:RegisterEarlyEvents(frame)
    frame:SetScript("OnEvent", function(_, event, ...)
        BlackDiamondsBootstrap:OnEvent(_, event, ...)
    end)
end
