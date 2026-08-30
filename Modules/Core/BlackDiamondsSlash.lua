---@class BlackDiamondsSlash
---@field private table
local BlackDiamondsSlash = BlackDiamondsLoader:CreateModule("BlackDiamondsSlash")
local private = BlackDiamondsSlash.private

local L = LibStub("AceLocale-3.0"):GetLocale("BlackDiamonds", true)

local PREFIX = "|cFF9B59B6BlackDiamonds|r: "

local function say(message)
    print(PREFIX .. message)
end

function BlackDiamondsSlash:Register(handlers)
    private.handlers = handlers
    SLASH_BLACKDIAMONDS1, SLASH_BLACKDIAMONDS2 = "/bd", "/blackdiamonds"
    SlashCmdList.BLACKDIAMONDS = function(args)
        BlackDiamondsSlash:Handle(args)
    end
end

function BlackDiamondsSlash:Handle(args)
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
        print("  /bd out    -- " .. L["SLASH_HELP_OUT"])
        print("  /bd in     -- " .. L["SLASH_HELP_IN"])
        print("  /bd swap   -- " .. L["SLASH_HELP_SWAP"])
        print("  /bd toggle -- " .. L["SLASH_HELP_TOGGLE"])
        print("  /bd status -- " .. L["SLASH_HELP_STATUS"])
    end
end

---@param message string
function BlackDiamondsSlash:Print(message)
    say(message)
end
