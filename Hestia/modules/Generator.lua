local Generator = {}
Generator.__index = Generator
function Generator.new(h)
    return setmetatable(
        { H = h, Status = "Disabled", Rejected = setmetatable({}, { __mode = "k" }) },
        Generator
    )
end
function Generator:GetInstance()
    return self.H.Adapter:GetGenerator()
end
function Generator:GetFuel()
    local generator = self:GetInstance()
    return generator and generator:GetAttribute("Fuel")
end
function Generator:GetFuelPercent()
    return self.H.Adapter:GetFuelPercent()
end
function Generator:FindBestFuel(inventory)
    local h, ranking = self.H, {}
    for i, name in ipairs(h.Config.Generator.FuelPriority) do
        ranking[name] = i
    end
    if inventory then
        local best, rank = nil, math.huge
        for _, item in ipairs(h.Adapter:GetInventory()) do
            local value = ranking[item.Name] or 100
            if item.Category == "Fuel" and item.Quantity > 0 and value < rank then
                best, rank = item.Instance, value
            end
        end
        return best
    end
    return h:Import("Utilities").Nearest(h, h.Registry.Fuel, h.Config.Generator.FuelRadius, function(object)
        return (self.Rejected[object] or 0) < os.clock()
    end, function(object, distance)
        return (ranking[object.Name] or 100) * 100000 + distance
    end)
end
function Generator:CollectFuel()
    local h = self.H
    if not self.Target or not h.Adapter:Valid(self.Target) then
        self.Target = self:FindBestFuel(false)
    end
    if not self.Target then
        return false, "No available fuel"
    end
    self.CurrentFuel = self.Target.Name
    local result = h.Navigator:Step("Generator", self.Target, 5)
    if result == "Arrived" and h.Tasks:IsOwner("Generator") then
        local target = self.Target
        local ok = h.Adapter:CollectItem(target)
        self.Rejected[target] = os.clock() + (ok and 5 or 15)
        self.Target = nil
        return ok, ok and "Returning" or "Collection rejected"
    elseif result == "Timeout" or result == "Unreachable" then
        self.Rejected[self.Target] = os.clock() + 30
        self.Target = nil
    end
    return false, result
end
function Generator:AddFuel()
    local h, fuel = self.H, self:FindBestFuel(true)
    if not fuel then
        return false, "No inventory fuel"
    end
    self.CurrentFuel = fuel.Name
    local status = h.Navigator:Step("Generator", self:GetInstance(), 5)
    if status == "Arrived" and h.Tasks:IsOwner("Generator") then
        local ok, reason = h.Adapter:AddFuel(self:GetInstance(), fuel)
        if ok then
            return true
        end
        return false, "Fuel insertion rejected: " .. tostring(reason)
    end
    return false, status
end
function Generator:Step()
    local h, config = self.H, self.H.Config.Generator
    local percent = self:GetFuelPercent()
    if not percent then
        self.Status = "Generator unavailable"
        h.Tasks:Release("Generator")
        h.Navigator:Cancel("Generator")
        return
    end
    if percent < config.FuelBelow then
        self.Fueling = true
    end
    if self.Fueling and percent >= config.FuelUntil then
        self.Fueling = false
        h.Tasks:Release("Generator")
        h.Navigator:Cancel("Generator")
        h.Notifications:Send(
            "Generator restored to " .. math.floor(percent) .. "%. Previous automation resumed.",
            "HESTIA Generator",
            "GeneratorRestored",
            10
        )
    end
    if not self.Fueling then
        self.Status = "Stable"
        h.Tasks:Release("Generator")
        return
    end
    local emergency = percent <= config.EmergencyFuel
    if emergency then
        h.Notifications:Send(
            "Fuel at " .. math.floor(percent) .. "%. Emergency fueling started.",
            "HESTIA Generator",
            "EmergencyFuel",
            30
        )
    end
    if os.clock() < (self.Backoff or 0) then
        self.Status = "Waiting for fuel"
        return
    end
    if not h.Tasks:Request("Generator", emergency and 90 or 60) then
        self.Status = "Paused"
        return
    end
    local ownedFuel = self:FindBestFuel(true)
    local ok, reason
    if ownedFuel then
        ok, reason = self:AddFuel()
    else
        ok, reason = self:CollectFuel()
    end
    self.Status = emergency and "EMERGENCY FUELING" or (ownedFuel and "Adding fuel" or "Collecting fuel")
    if
        not ok
        and (
            reason == "No available fuel"
            or reason == "Collection rejected"
            or reason == "Unreachable"
            or reason == "Timeout"
            or (type(reason) == "string" and reason:find("Fuel insertion rejected", 1, true))
            or (type(reason) == "string" and reason:find("Unsupported"))
        )
    then
        self.Status = reason
        self.Backoff = os.clock() + 5
        h.Tasks:Release("Generator")
        h.Navigator:Cancel("Generator")
    end
end
function Generator:Start()
    self.H.Scheduler:Add("Generator", 1, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Generator:Stop()
    self.H.Scheduler:Remove("Generator")
    self.H.Tasks:Release("Generator")
    self.H.Navigator:Cancel("Generator")
    self.Status, self.Target, self.Fueling = "Disabled", nil, false
end
Generator.Destroy = Generator.Stop
return Generator
