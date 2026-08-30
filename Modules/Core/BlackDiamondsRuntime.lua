---@class BlackDiamondsRuntime
---@field private table
local BlackDiamondsRuntime = BlackDiamondsLoader:CreateModule("BlackDiamondsRuntime")
local private = BlackDiamondsRuntime.private

function BlackDiamondsRuntime:Set(ctx)
    private.ctx = ctx
end

function BlackDiamondsRuntime:Get()
    return private.ctx
end

function BlackDiamondsRuntime:Clear()
    private.ctx = nil
end
