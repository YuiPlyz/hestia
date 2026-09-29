local Worker = {}
Worker.__index = Worker
function Worker.new(h, name, options)
    return setmetatable({
        H = h,
        Name = name,
        Options = options,
        Rejected = setmetatable({}, { __mode = "k" }),
        Collected = 0,
    }, Worker)
end
function Worker:FindNearest()
    return self:Find(false)
end
function Worker:FindBest()
    return self:Find(true)
end
function Worker:Find(best)
    local h, options = self.H, self.Options
    return h:Import("Utilities").Nearest(h, h.Registry[options.Registry], options.Radius(), function(object)
        return (self.Rejected[object] or 0) < os.clock() and (not options.Filter or options.Filter(object))
    end, best and function(object, distance)
        return -(tonumber(object:GetAttribute("ScrapValue")) or 1) * 100000 + distance
    end or nil)
end
function Worker:SetTarget(target)
    self.Target = target
    self.H.Navigator:Cancel(self.Name)
end
function Worker:Collect(target)
    if not self.H.Tasks:IsOwner(self.Name) or not self.H.Adapter:Valid(target) then
        return false
    end
    local ok, quantity = self.H.Adapter:CollectItem(target)
    self.Status = ok and "Collected " .. target.Name or tostring(quantity or "Collection rejected")
    if ok then
        local amount = type(quantity) == "number" and math.max(tonumber(quantity) or 0, 0) or 1
        self.Collected = self.Collected + amount
        if self.Options.Stat then
            self.H.State.Stats[self.Options.Stat] = self.H.State.Stats[self.Options.Stat] + amount
        end
    end
    self.Rejected[target] = os.clock() + (ok and 5 or 10)
    return ok
end
function Worker:Step()
    local h = self.H
    if self.Options.Ready and not self.Options.Ready() then
        h.Tasks:Release(self.Name)
        h.Navigator:Cancel(self.Name)
        self.Status = "Waiting"
        return
    end
    if
        self.Target
        and (
            (self.Options.Filter and not self.Options.Filter(self.Target))
            or (self.Options.Radius() > 0 and h.Adapter:Distance(self.Target) > self.Options.Radius())
        )
    then
        self:SetTarget(nil)
    end
    if not self.Target or not h.Adapter:Valid(self.Target) then
        self.Target = self.Options.Best and self.Options.Best() and self:FindBest() or self:FindNearest()
    end
    if not self.Target then
        h.Tasks:Release(self.Name)
        self.Status = "Searching"
        return
    end
    if not h.Tasks:Request(self.Name, self.Options.Priority) then
        self.Status = "Paused"
        return
    end
    local status = h.Navigator:Step(self.Name, self.Target, 5)
    self.Status = status
    if status == "Arrived" and os.clock() >= (self.NextCollect or 0) then
        local target = self.Target
        self.NextCollect = os.clock() + (self.Options.Delay and self.Options.Delay() or 0.25)
        self:Collect(target)
        self.Target = nil
    elseif status == "Timeout" or status == "Unreachable" or status == "Invalid" then
        self.Rejected[self.Target] = os.clock() + 30
        self.Target = nil
        h.Tasks:Release(self.Name)
    end
end
function Worker:Start()
    if self.Running then
        return
    end
    self.Running, self.StartedAt, self.Status = true, os.clock(), "Searching"
    self.H.Scheduler:Add(self.Name, 0.25, function()
        self:Step()
    end, function()
        self:Stop()
    end)
end
function Worker:Stop()
    self.Running, self.Target, self.Status = false, nil, "Disabled"
    self.H.Scheduler:Remove(self.Name)
    self.H.Tasks:Release(self.Name)
    self.H.Navigator:Cancel(self.Name)
end
Worker.Destroy = Worker.Stop
return Worker
