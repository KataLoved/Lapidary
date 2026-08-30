---@class LapidaryTimer
---@field private table
local LapidaryTimer = LapidaryLoader:CreateModule("LapidaryTimer")
local private = LapidaryTimer.private

private.pending = {}
private.nextId = 1
private.driver = CreateFrame("Frame")
private.running = false

local function onUpdate(_, elapsed)
    local pending = private.pending
    local fired
    for id, entry in pairs(pending) do
        entry.remaining = entry.remaining - elapsed
        if entry.remaining <= 0 then
            fired = fired or {}
            fired[#fired + 1] = id
        end
    end
    if fired then
        for i = 1, #fired do
            local id = fired[i]
            local entry = pending[id]
            pending[id] = nil
            if entry then
                entry.callback(entry.payload)
            end
        end
    end
    if not next(pending) then
        private.driver:SetScript("OnUpdate", nil)
        private.running = false
    end
end

local function start()
    if private.running then
        return
    end
    private.running = true
    private.driver:SetScript("OnUpdate", onUpdate)
end

---@param delay number
---@param callback fun(payload:any)
---@param payload any|nil
---@return number @Handle usable with Cancel
function LapidaryTimer:After(delay, callback, payload)
    local id = private.nextId
    private.nextId = id + 1
    private.pending[id] = { remaining = delay, callback = callback, payload = payload }
    start()
    return id
end

---@param handle number|nil
function LapidaryTimer:Cancel(handle)
    if handle then
        private.pending[handle] = nil
    end
end

function LapidaryTimer:CancelAll()
    wipe(private.pending)
end
