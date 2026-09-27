-- HESTIA demo integration, installed only when Repository.InstallDemo is true.
local remote = game:GetService("ReplicatedStorage"):WaitForChild("HESTIA Demo", 10)
assert(remote, "HESTIA demo server is not running")
local function call(action, ...)
    return remote:InvokeServer(action, ...)
end
return {
    CollectItem = function(item)
        return call("Collect", item)
    end,
    AddFuel = function(generator, fuel)
        return call("Fuel", generator, fuel)
    end,
    AttackTarget = function(target)
        return call("Attack", target)
    end,
    StoreItem = function(item, quantity, storage)
        return call("Store", item, quantity, storage)
    end,
    RepairStructure = function(target)
        return call("Repair", target)
    end,
    UseSurvival = function(kind)
        return call("Survival", kind)
    end,
    GetStorage = function()
        local scene = workspace:FindFirstChild("HESTIA Demo")
        return scene and scene:FindFirstChild("Storage")
    end,
}
