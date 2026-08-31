---@class LapidaryConstants
local LapidaryConstants = LapidaryLoader:CreateModule("LapidaryConstants")

LapidaryConstants.CURRENCY_ID = 280505
LapidaryConstants.CHARGED_DIAMOND_ID = 104021
LapidaryConstants.SHARD_ID = 104022
LapidaryConstants.LEGENDARY_QUALITY = 5

LapidaryConstants.VENDOR_NPC_IDS = {
    [55000] = true,
    [13499] = true,
}

---The personal assistant carries the gem service among many others and is
---matched by name, the way the WeakAura did: its id is not in the list above.
LapidaryConstants.VENDOR_NAMES = {
    ["Персональный ассистент"] = true,
    ["Personal assistant"] = true,
}

LapidaryConstants.INVENTORY_SLOTS = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "WristSlot",
    "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot",
    "Trinket0Slot", "Trinket1Slot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot",
}

LapidaryConstants.EQUIPPED_SLOT_MIN = 1
LapidaryConstants.EQUIPPED_SLOT_MAX = 19

local function addRange(target, from, to)
    for id = from, to do
        target[id] = true
    end
    return target
end

LapidaryConstants.META_GEMS = addRange({}, 260050, 260070)

LapidaryConstants.BIG_GEMS = addRange(addRange({}, 104000, 104019), 100824, 100884)

LapidaryConstants.SMALL_GEMS =
    addRange(addRange(addRange({}, 103501, 103520), 100700, 100823), 260030, 260048)

---@class LapidaryGemEntry
---@field id number
---@field upgradeId number|nil
---@field key string

---@type table<string, LapidaryGemEntry[]>
LapidaryConstants.GEM_GROUPS = {
    primary = {
        { id = 103502, upgradeId = 104001, key = "GEM_STRENGTH" },
        { id = 103501, upgradeId = 104000, key = "GEM_AGILITY" },
        { id = 103503, upgradeId = 104002, key = "GEM_INTELLECT" },
        { id = 103504, upgradeId = 104003, key = "GEM_SPIRIT" },
        { id = 103505, upgradeId = 104004, key = "GEM_STAMINA" },
        { id = 103506, upgradeId = 104005, key = "GEM_ATTACK_POWER" },
        { id = 103507, upgradeId = 104006, key = "GEM_SPELL_POWER" },
    },
    secondary = {
        { id = 103512, upgradeId = 104011, key = "GEM_HIT" },
        { id = 103513, upgradeId = 104012, key = "GEM_CRIT" },
        { id = 103515, upgradeId = 104014, key = "GEM_HASTE" },
        { id = 103516, upgradeId = 104015, key = "GEM_EXPERTISE" },
        { id = 103514, upgradeId = 104013, key = "GEM_RESILIENCE" },
        { id = 103518, upgradeId = 104017, key = "GEM_ARMOR_PENETRATION" },
        { id = 103519, upgradeId = 104018, key = "GEM_SPELL_PENETRATION" },
        { id = 103517, upgradeId = 104016, key = "GEM_MP5" },
    },
    tank = {
        { id = 103508, upgradeId = 104007, key = "GEM_DEFENSE" },
        { id = 103509, upgradeId = 104008, key = "GEM_DODGE" },
        { id = 103510, upgradeId = 104009, key = "GEM_PARRY" },
        { id = 103511, upgradeId = 104010, key = "GEM_BLOCK_RATING" },
        { id = 103520, upgradeId = 104019, key = "GEM_BLOCK_VALUE" },
    },
    hybrid = {
        { id = 100719, upgradeId = 100843, key = "GEM_STRENGTH_HIT" },
        { id = 100722, upgradeId = 100846, key = "GEM_STRENGTH_CRIT" },
        { id = 100738, upgradeId = 100862, key = "GEM_AGILITY_HIT" },
        { id = 100723, upgradeId = 100847, key = "GEM_AGILITY_CRIT" },
        { id = 100732, upgradeId = 100856, key = "GEM_ATTACK_POWER_HIT" },
        { id = 100739, upgradeId = 100863, key = "GEM_ATTACK_POWER_CRIT" },
        { id = 100721, upgradeId = 100845, key = "GEM_ATTACK_POWER_HASTE" },
        { id = 100736, upgradeId = 100860, key = "GEM_SPELL_POWER_HIT" },
        { id = 100724, upgradeId = 100848, key = "GEM_SPELL_POWER_CRIT" },
        { id = 100727, upgradeId = 100851, key = "GEM_SPELL_POWER_HASTE" },
        { id = 100720, upgradeId = 100844, key = "GEM_EXPERTISE_HIT" },
    },
}

LapidaryConstants.GROUP_ORDER = { "primary", "secondary", "hybrid", "tank" }

LapidaryConstants.GROUP_TITLE_KEYS = {
    primary = "GROUP_PRIMARY",
    secondary = "GROUP_SECONDARY",
    hybrid = "GROUP_HYBRID",
    tank = "GROUP_TANK",
}

LapidaryConstants.OPCODE_REMOVE_SOCKET = "ACMSG_REMOVE_SOCKET_FROM_ITEM"

LapidaryConstants.SOCKET_STEP = 0.25
LapidaryConstants.REMOVE_STEP = 0.2
LapidaryConstants.EQUIP_SETTLE_DELAY = 0.5

LapidaryConstants.KIT_BUY_DELAY = 0.3
LapidaryConstants.KIT_BUY_BATCH = 3
LapidaryConstants.KIT_BATCH_SETTLE = 1.5

LapidaryConstants.DEFAULTS = {
    enabled = true,
    autoSwapOnEquipSet = true,
    showVendorPanel = true,
    buttonSize = 26,
    buttonsPerRow = 6,
    framePos = { anchor = "TOPLEFT", x = 0, y = 0 },
    favorites = {},
    kits = {},
    activeKit = nil,
}
