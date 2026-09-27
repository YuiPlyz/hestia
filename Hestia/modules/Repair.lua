local Repair = {}
Repair.__index = Repair
function Repair.new(h)
    return setmetatable({ H = h, Last = 0 }, Repair)
end
function Repair:Step()
    local h, config = self.H, self.H.Config.Repair
    if os.clock() - self.Last < config.Rate then
        return
    end
    h.Tasks:Release("Repair")
    if not h.Adapter:HasRepairEquipment() then
        self.Status = "Repair equipment unavailable"
        return
    end
    local target = h:Import("Utilities").Nearest(h, h.Registry.Structures, config.Radius, function(object)
        local hp, maximum = h.Adapter:Health(object)
        return hp and maximum and hp > 0 and hp < maximum
    end, function(object, distance)
        local hp, maximum = h.Adapter:Health(object)
        return config.Priority == "LowestHealth" and hp / maximum or distance
    end)
    self.Target = target
    if not target then
        self.Status = "Stable"
        return
    end
    local hp, maximum = h.Adapter:Health(target)
    self.Status = string.format("%s  %.0f/%.0f", target.Name, hp, maximum)
    local priority = config.Emergency and hp / maximum * 100 <= config.EmergencyBelow and 85 or 60
    if not h.Tasks:Request("Repair", priority) then
        return
    end
    self.Last = os.clock()
    if h.Adapter:RepairStructure(target) then
        h.State.Stats.Repairs = h.State.Stats.Repairs + 1
    end
    h.Tasks:Release("Repair")
end
function Repair:Start()
    self.H.Scheduler:Add("Repair", 0.2, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Repair:Stop()
    self.H.Scheduler:Remove("Repair")
    self.H.Tasks:Release("Repair")
end
Repair.Destroy = Repair.Stop
return Repair
