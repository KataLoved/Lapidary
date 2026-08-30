---@class LapidaryLoader
LapidaryLoader = {}

local modules = {}
LapidaryLoader._modules = modules

---@generic T
---@param name `T` @Module name
---@return T|{ private: table } @Module reference
function LapidaryLoader:CreateModule(name)
    if not modules[name] then
        modules[name] = { private = {} }
    end
    return modules[name]
end

---@generic T
---@param name `T` @Module name
---@return T|{ private: table } @Module reference
function LapidaryLoader:ImportModule(name)
    if not modules[name] then
        modules[name] = { private = {} }
    end
    return modules[name]
end

function LapidaryLoader:PopulateGlobals()
    for name, module in pairs(modules) do
        _G[name] = module
    end
end
