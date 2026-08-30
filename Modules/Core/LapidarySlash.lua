---@class LapidarySlash
---@field private table
local LapidarySlash = LapidaryLoader:CreateModule("LapidarySlash")
local private = LapidarySlash.private

local L = LapidaryLoader:ImportModule("LapidaryLocale"):Get()

local PREFIX = "|cFF9B59B6Lapidary|r: "

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

    if command == "out" then
        handlers.removeAll()
    elseif command == "in" then
        handlers.insertAll()
    elseif command == "swap" then
        handlers.swapAll()
    elseif command == "toggle" then
        say(handlers.toggle() and L["SLASH_ENABLED"] or L["SLASH_DISABLED"])
    elseif command == "status" then
        for _, line in ipairs(handlers.status()) do
            say(line)
        end
    else
        say(L["SLASH_HELP_HEADER"])
        print("  /lap out    -- " .. L["SLASH_HELP_OUT"])
        print("  /lap in     -- " .. L["SLASH_HELP_IN"])
        print("  /lap swap   -- " .. L["SLASH_HELP_SWAP"])
        print("  /lap toggle -- " .. L["SLASH_HELP_TOGGLE"])
        print("  /lap status -- " .. L["SLASH_HELP_STATUS"])
    end
end

---@param message string
function LapidarySlash:Print(message)
    say(message)
end
