local TaskManager = {}
TaskManager.__index = TaskManager
TaskManager.Priorities = {
    EmergencySurvival = 100,
    EmergencyFuel = 90,
    Combat = 80,
    AutoHeal = 70,
    Generator = 60,
    ScrapFarm = 50,
    ItemFarm = 40,
    AutoPickup = 30,
    Idle = 10,
}
function TaskManager.new(onChanged)
    return setmetatable(
        { Requests = {}, Active = nil, Serial = 0, Order = 0, OnChanged = onChanged },
        TaskManager
    )
end
function TaskManager:Reconcile()
    local best, record
    for name, request in pairs(self.Requests) do
        if
            not record
            or request.Priority > record.Priority
            or (request.Priority == record.Priority and request.Order < record.Order)
        then
            best, record = name, request
        end
    end
    if best ~= self.Active then
        local previous = self.Active
        self.Active = best
        self.Serial = self.Serial + 1
        if self.OnChanged then
            self.OnChanged(best, previous)
        end
    end
end
function TaskManager:Request(name, priority)
    assert(type(name) == "string" and type(priority) == "number", "HESTIA invalid task request")
    local old = self.Requests[name]
    if not old then
        self.Order = self.Order + 1
    end
    self.Requests[name] = { Priority = priority, Order = old and old.Order or self.Order }
    self:Reconcile()
    return self:IsOwner(name), self.Serial
end
function TaskManager:Release(name)
    self.Requests[name] = nil
    self:Reconcile()
end
function TaskManager:IsOwner(name, token)
    return self.Active == name and (token == nil or token == self.Serial)
end
function TaskManager:ReleaseAll()
    table.clear(self.Requests)
    self:Reconcile()
end
return TaskManager
