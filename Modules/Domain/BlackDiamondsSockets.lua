---@class BlackDiamondsSockets
---@field private table
local BlackDiamondsSockets = BlackDiamondsLoader:CreateModule("BlackDiamondsSockets")
local private = BlackDiamondsSockets.private

---@type BlackDiamondsConstants
local BlackDiamondsConstants = BlackDiamondsLoader:ImportModule("BlackDiamondsConstants")
---@type BlackDiamondsGems
local BlackDiamondsGems = BlackDiamondsLoader:ImportModule("BlackDiamondsGems")
---@type BlackDiamondsServer
local BlackDiamondsServer = BlackDiamondsLoader:ImportModule("BlackDiamondsServer")
---@type BlackDiamondsTimer
local BlackDiamondsTimer = BlackDiamondsLoader:ImportModule("BlackDiamondsTimer")

local STEP = BlackDiamondsConstants.SOCKET_STEP

local function poolsEmpty(pools)
    return #pools.meta == 0 and #pools.big == 0 and #pools.small == 0
end

local function takeFrom(pool)
    local entry = table.remove(pool, 1)
    return entry
end

local function fillSlot(payload)
    local pools = payload.pools
    if poolsEmpty(pools) then
        return
    end

    SocketInventoryItem(payload.slotId)
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
function BlackDiamondsSockets:RemoveAll(onDone)
    local entries = BlackDiamondsGems:CollectSocketed()
    private.lastRemovedCount = #entries
    BlackDiamondsServer:RemoveSockets(entries, onDone)
end

---@param onDone fun()|nil
function BlackDiamondsSockets:InsertAll(onDone)
    local pools = BlackDiamondsGems:CollectLoose()
    if poolsEmpty(pools) then
        if onDone then
            onDone()
        end
        return
    end

    local slots = BlackDiamondsGems:GetOccupiedSlots()
    private.lastInsertSlots = #slots

    for i = 1, #slots do
        BlackDiamondsTimer:After(STEP * i, fillSlot, { slotId = slots[i], pools = pools })
    end

    if onDone then
        BlackDiamondsTimer:After(STEP * (#slots + 1), onDone)
    end
end

---@param onDone fun()|nil
function BlackDiamondsSockets:SwapAll(onDone)
    self:RemoveAll(function()
        self:InsertAll(onDone)
    end)
end

---@return number|nil, number|nil
function BlackDiamondsSockets:GetLastCounts()
    return private.lastRemovedCount, private.lastInsertSlots
end
