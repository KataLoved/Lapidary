---@class LapidarySkin
---@field private table
local LapidarySkin = LapidaryLoader:CreateModule("LapidarySkin")
local private = LapidarySkin.private

local function skins()
    if private.resolved then
        return private.skins
    end
    private.resolved = true
    local elv = _G.ElvUI and _G.ElvUI[1]
    if elv then
        local ok, module = pcall(elv.GetModule, elv, "Skins")
        if ok then
            private.skins = module
        end
    end
    return private.skins
end

---@return boolean
function LapidarySkin:IsActive()
    return skins() ~= nil
end

---@param frame table
function LapidarySkin:Frame(frame)
    local S = skins()
    if S and S.HandleFrame then
        pcall(S.HandleFrame, S, frame)
        return
    end
    if S and S.SetTemplate then
        pcall(S.SetTemplate, frame, "Transparent")
        return
    end
    frame.fallbackBackdrop = frame:CreateTexture(nil, "BACKGROUND")
    frame.fallbackBackdrop:SetAllPoints()
    frame.fallbackBackdrop:SetTexture(0, 0, 0, 0.85)
end

---@param button table
function LapidarySkin:Button(button)
    local S = skins()
    if S and S.HandleButton then
        pcall(S.HandleButton, S, button)
    end
end

---@param button table
function LapidarySkin:CloseButton(button)
    local S = skins()
    if S and S.HandleCloseButton then
        pcall(S.HandleCloseButton, S, button)
    end
end
