---@class BlackDiamondsServer
---@field private table
local BlackDiamondsServer = BlackDiamondsLoader:CreateModule("BlackDiamondsServer")
local private = BlackDiamondsServer.private

---@type BlackDiamondsConstants
local BlackDiamondsConstants = BlackDiamondsLoader:ImportModule("BlackDiamondsConstants")
---@type BlackDiamondsTimer
local BlackDiamondsTimer = BlackDiamondsLoader:ImportModule("BlackDiamondsTimer")

local OPCODE = BlackDiamondsConstants.OPCODE_REMOVE_SOCKET
local STEP_TIMEOUT = 3

private.queue = {}
private.busy = false

local function finish(success)
    private.busy = false
    BlackDiamondsTimer:Cancel(private.timeout)
    private.timeout = nil
    local callback = private.onDone
    private.onDone = nil
    if callback then
        callback(success)
    end
end

local function sendNext()
    local entry = table.remove(private.queue, 1)
    if not entry then
        finish(true)
        return
    end
    BlackDiamondsTimer:Cancel(private.timeout)
    private.timeout = BlackDiamondsTimer:After(STEP_TIMEOUT, function()
        wipe(private.queue)
        finish(false)
    end)
    SendServerMessage(OPCODE, string.format("%d:%d:%d", entry.bag, entry.slot, entry.index))
end

local function onEvent(_, _, prefix)
    if prefix ~= OPCODE or not private.busy then
        return
    end
    sendNext()
end

function BlackDiamondsServer:Initialize()
    if private.frame then
        return
    end
    private.frame = CreateFrame("Frame")
    private.frame:RegisterEvent("CHAT_MSG_ADDON")
    private.frame:SetScript("OnEvent", onEvent)
end

---@return boolean
function BlackDiamondsServer:IsBusy()
    return private.busy
end

---@param entries table[] @Each entry is { bag = number, slot = number, index = number }
---@param onDone fun(success:boolean)|nil
function BlackDiamondsServer:RemoveSockets(entries, onDone)
    if private.busy then
        if onDone then
            onDone(false)
        end
        return
    end
    wipe(private.queue)
    for i = 1, #entries do
        private.queue[i] = entries[i]
    end
    private.onDone = onDone
    if #private.queue == 0 then
        finish(true)
        return
    end
    private.busy = true
    sendNext()
end

function BlackDiamondsServer:Abort()
    wipe(private.queue)
    if private.busy then
        finish(false)
    end
end
