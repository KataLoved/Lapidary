local addonName = ...
local addon = CreateFrame("Frame", "BlackDiamonds", UIParent)

---@type BlackDiamondsBootstrap
local BlackDiamondsBootstrap = BlackDiamondsLoader:ImportModule("BlackDiamondsBootstrap")

BlackDiamondsLoader:PopulateGlobals()
BlackDiamondsBootstrap:Start(addon, addonName)
