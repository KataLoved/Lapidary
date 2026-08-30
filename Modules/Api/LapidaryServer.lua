---@class LapidaryServer
---@field private table
local LapidaryServer = LapidaryLoader:CreateModule("LapidaryServer")
local private = LapidaryServer.private

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")
---@type LapidaryTimer
local LapidaryTimer = LapidaryLoader:ImportModule("LapidaryTimer")

local OPCODE = LapidaryConstants.OPCODE_REMOVE_SOCKET
local STEP_TIMEOUT = 3

private.queue = {}
private.busy = false

local function finish(success)
    private.busy = false
    LapidaryTimer:Cancel(private.timeout)
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
    LapidaryTimer:Cancel(private.timeout)
    private.timeout = LapidaryTimer:After(STEP_TIMEOUT, function()
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

function LapidaryServer:Initialize()
    if private.frame then
        return
    end
    private.frame = CreateFrame("Frame")
    private.frame:RegisterEvent("CHAT_MSG_ADDON")
    private.frame:SetScript("OnEvent", onEvent)
end

---@return boolean
function LapidaryServer:IsBusy()
    return private.busy
end

---@param entries table[] @Each entry is { bag = number, slot = number, index = number }
---@param onDone fun(success:boolean)|nil
function LapidaryServer:RemoveSockets(entries, onDone)
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

function LapidaryServer:Abort()
    wipe(private.queue)
    if private.busy then
        finish(false)
    end
end
