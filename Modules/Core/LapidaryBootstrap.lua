---@class LapidaryBootstrap
---@field private table
local LapidaryBootstrap = LapidaryLoader:CreateModule("LapidaryBootstrap")
local private = LapidaryBootstrap.private

---@type LapidaryDatabase
local LapidaryDatabase = LapidaryLoader:ImportModule("LapidaryDatabase")
---@type LapidaryRuntime
local LapidaryRuntime = LapidaryLoader:ImportModule("LapidaryRuntime")
---@type LapidaryServer
local LapidaryServer = LapidaryLoader:ImportModule("LapidaryServer")
---@type LapidarySockets
local LapidarySockets = LapidaryLoader:ImportModule("LapidarySockets")
---@type LapidaryEquipSet
local LapidaryEquipSet = LapidaryLoader:ImportModule("LapidaryEquipSet")
---@type LapidaryKits
local LapidaryKits = LapidaryLoader:ImportModule("LapidaryKits")
---@type LapidaryEventHandler
local LapidaryEventHandler = LapidaryLoader:ImportModule("LapidaryEventHandler")
---@type LapidaryCharacterPanel
local LapidaryCharacterPanel = LapidaryLoader:ImportModule("LapidaryCharacterPanel")
---@type LapidaryVendorFrame
local LapidaryVendorFrame = LapidaryLoader:ImportModule("LapidaryVendorFrame")
---@type LapidarySlash
local LapidarySlash = LapidaryLoader:ImportModule("LapidarySlash")
---@type LapidaryMerchant
local LapidaryMerchant = LapidaryLoader:ImportModule("LapidaryMerchant")

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

function LapidaryBootstrap:BuildStatus()
    local config = LapidaryDatabase:Get()
    local removed, slots = LapidarySockets:GetLastCounts()
    return {
        format(L["STATUS_ENABLED"], tostring(config.enabled)),
        format(L["STATUS_AUTO_SWAP"], tostring(config.autoSwapOnEquipSet)),
        format(L["STATUS_HOOK"], tostring(LapidaryEquipSet:IsInstalled())),
        format(L["STATUS_CURRENCY"], LapidaryMerchant:GetCurrencyCount()),
        format(L["STATUS_LAST_RUN"], tostring(removed or 0), tostring(slots or 0)),
    }
end

function LapidaryBootstrap:RegisterSlash()
    LapidarySlash:Register({
        toggle = function()
            local config = LapidaryDatabase:Get()
            config.enabled = not config.enabled
            if config.enabled then
                LapidaryEventHandler:Enable()
            else
                LapidaryEventHandler:Disable()
            end
            return config.enabled
        end,
    })
end

function LapidaryBootstrap:OnPlayerLogin()
    local frame = private.frame

    private.charKey = (UnitName("player") or "?") .. " - " .. (GetRealmName() or "?")
    LapidaryDatabase:Open(private.charKey)
    LapidaryKits:EnsureDefault(L.KIT_DEFAULT_NAME)
    LapidaryServer:Initialize()

    frame:SetScript("OnEvent", function(self, event, ...)
        local handler = self[event]
        if handler then
            handler(self, event, ...)
        end
    end)

    LapidaryRuntime:Set({
        addonName = private.addonName,
        charKey = private.charKey,
        config = LapidaryDatabase:Get(),
    })

    LapidaryEventHandler:OnAddonReady(frame)
    self:RegisterSlash()
end

function LapidaryBootstrap:OnEvent(_, event, name)
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

function LapidaryBootstrap:Start(frame, addonName)
    private.frame = frame
    private.addonName = addonName
    private.loaded = false
    private.started = false

    LapidaryEventHandler:RegisterEarlyEvents(frame)
    frame:SetScript("OnEvent", function(_, event, ...)
        LapidaryBootstrap:OnEvent(_, event, ...)
    end)
end
