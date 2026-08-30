local addonName = ...
local addon = CreateFrame("Frame", "Lapidary", UIParent)

---@type LapidaryBootstrap
local LapidaryBootstrap = LapidaryLoader:ImportModule("LapidaryBootstrap")

LapidaryLoader:PopulateGlobals()
LapidaryBootstrap:Start(addon, addonName)
