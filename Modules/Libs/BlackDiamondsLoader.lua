---@class BlackDiamondsLoader
BlackDiamondsLoader = {}

local modules = {}
BlackDiamondsLoader._modules = modules

---@generic T
---@param name `T` @Module name
---@return T|{ private: table } @Module reference
function BlackDiamondsLoader:CreateModule(name)
    if not modules[name] then
        modules[name] = { private = {} }
    end
    return modules[name]
end

---@generic T
---@param name `T` @Module name
---@return T|{ private: table } @Module reference
function BlackDiamondsLoader:ImportModule(name)
    if not modules[name] then
        modules[name] = { private = {} }
    end
    return modules[name]
end

function BlackDiamondsLoader:PopulateGlobals()
    for name, module in pairs(modules) do
        _G[name] = module
    end
end
