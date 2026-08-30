---@class LapidarySockets
---@field private table
local LapidarySockets = LapidaryLoader:CreateModule("LapidarySockets")
local private = LapidarySockets.private

---@type LapidaryConstants
local LapidaryConstants = LapidaryLoader:ImportModule("LapidaryConstants")
---@type LapidaryGems
local LapidaryGems = LapidaryLoader:ImportModule("LapidaryGems")
---@type LapidaryServer
local LapidaryServer = LapidaryLoader:ImportModule("LapidaryServer")
---@type LapidaryTimer
local LapidaryTimer = LapidaryLoader:ImportModule("LapidaryTimer")

local STEP = LapidaryConstants.SOCKET_STEP

local function poolsEmpty(pools)
    return #pools.meta == 0 and #pools.big == 0 and #pools.small == 0
end

local function takeFrom(pool)
    return table.remove(pool, 1)
end

local function openTarget(target)
    if target.equipped then
        SocketInventoryItem(target.equipped)
    else
        SocketContainerItem(target.bag, target.slot)
    end
end

local function fillTarget(payload)
    local pools = payload.pools
    if poolsEmpty(pools) then
        return
    end

    openTarget(payload.target)
    local total = GetNumSockets()
    if not total or total < 1 then
        HideUIPanel(ItemSocketingFrame)
        return
    end

    local placed = false
    for socketIndex = 1, total do
        if not GetExistingSocketInfo(socketIndex) then
            local socketType = GetSocketTypes(socketIndex)
            local entry
            if socketType == "Meta" then
                entry = takeFrom(pools.meta)
            else
                entry = takeFrom(pools.big) or takeFrom(pools.small)
            end
            if entry then
                PickupContainerItem(entry.bag, entry.slot)
                ClickSocketButton(socketIndex)
                placed = true
            end
        end
    end

    if placed then
        AcceptSockets()
    end
    HideUIPanel(ItemSocketingFrame)
end

---@param onDone fun(success:boolean)|nil
---@param includeBags boolean|nil
function LapidarySockets:RemoveAll(onDone, includeBags)
    local entries = LapidaryGems:CollectSocketed(includeBags)
    private.lastRemovedCount = #entries
    LapidaryServer:RemoveSockets(entries, onDone)
end

---@param onDone fun()|nil
---@param includeBags boolean|nil
function LapidarySockets:InsertAll(onDone, includeBags)
    local pools = LapidaryGems:CollectLoose()
    if poolsEmpty(pools) then
        if onDone then
            onDone()
        end
        return
    end

    local targets = LapidaryGems:GetSocketTargets(includeBags)
    private.lastInsertTargets = #targets

    for i = 1, #targets do
        LapidaryTimer:After(STEP * i, fillTarget, { target = targets[i], pools = pools })
    end

    if onDone then
        LapidaryTimer:After(STEP * (#targets + 1), onDone)
    end
end

---@param onDone fun()|nil
---@param includeBags boolean|nil
function LapidarySockets:SwapAll(onDone, includeBags)
    self:RemoveAll(function()
        self:InsertAll(onDone, includeBags)
    end, includeBags)
end

---@return number|nil, number|nil
function LapidarySockets:GetLastCounts()
    return private.lastRemovedCount, private.lastInsertTargets
end
