---@class LapidarySlash
---@field private table
local LapidarySlash = LapidaryLoader:CreateModule("LapidarySlash")
local private = LapidarySlash.private

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local PREFIX = "|cFFFF8000Lapidary|r: "

local function say(message)
    print(PREFIX .. message)
end

function LapidarySlash:Register(handlers)
    private.handlers = handlers
    SLASH_LAPIDARY1, SLASH_LAPIDARY2 = "/lap", "/lapidary"
    SlashCmdList.LAPIDARY = function(args)
        LapidarySlash:Handle(args)
    end
end

function LapidarySlash:Handle(args)
    local handlers = private.handlers
    if not handlers then
        return
    end
    local command = strlower(strsplit(" ", args or "") or "")

    if command == "toggle" then
        say(handlers.toggle() and L.SLASH_ENABLED or L.SLASH_DISABLED)
    else
        say(L.SLASH_HELP_TOGGLE)
    end
end

---@param message string
function LapidarySlash:Print(message)
    say(message)
end
