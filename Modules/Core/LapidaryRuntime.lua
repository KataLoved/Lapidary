---@class LapidaryRuntime
---@field private table
local LapidaryRuntime = LapidaryLoader:CreateModule("LapidaryRuntime")
local private = LapidaryRuntime.private

function LapidaryRuntime:Set(ctx)
    private.ctx = ctx
end

function LapidaryRuntime:Get()
    return private.ctx
end

function LapidaryRuntime:Clear()
    private.ctx = nil
end
