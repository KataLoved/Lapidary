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
    local command, scope = strsplit(" ", args or "", 2)
    command = strlower(command or "")
    local everything = strlower(scope or "") == "all"

    if command == "out" then
        handlers.removeAll(everything)
    elseif command == "in" then
        handlers.insertAll(everything)
    elseif command == "swap" then
        handlers.swapAll(everything)
    elseif command == "toggle" then
        say(handlers.toggle() and L["SLASH_ENABLED"] or L["SLASH_DISABLED"])
    elseif command == "resetpos" then
        handlers.resetPos()
        say(L.SLASH_POS_RESET)
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
        print("  /lap status   -- " .. L["SLASH_HELP_STATUS"])
        print("  /lap resetpos -- " .. L["SLASH_HELP_RESETPOS"])
        print("  " .. L["SLASH_HELP_SCOPE"])
    end
end

---@param message string
function LapidarySlash:Print(message)
    say(message)
end
