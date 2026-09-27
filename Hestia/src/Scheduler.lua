local Scheduler = {}
Scheduler.__index = Scheduler
function Scheduler.new(h)
    local self = setmetatable({ H = h, Jobs = {}, Running = true }, Scheduler)
    h.Connections:Add(
        "HESTIA.Scheduler",
        h.Services.RunService.Heartbeat:Connect(function(dt)
            self:Step(dt)
        end)
    )
    return self
end
function Scheduler:Add(name, interval, callback, onError)
    self:Remove(name)
    self.Jobs[name] =
        { Interval = interval, Elapsed = interval, Callback = callback, OnError = onError, Busy = false }
end
function Scheduler:Remove(name)
    local job = self.Jobs[name]
    self.Jobs[name] = nil
    if
        job
        and job.Thread
        and coroutine.status(job.Thread) ~= "dead"
        and job.Thread ~= coroutine.running()
    then
        pcall(task.cancel, job.Thread)
    end
end
function Scheduler:Step(dt)
    if not self.Running then
        return
    end
    self.H.State.FPS = self.H.State.FPS * 0.9 + (1 / math.max(dt, 0.001)) * 0.1
    for name, job in pairs(self.Jobs) do
        job.Elapsed = job.Elapsed + dt
        if not job.Busy and job.Elapsed >= job.Interval then
            job.Elapsed, job.Busy = 0, true
            job.Thread = task.spawn(function()
                local ok, err = xpcall(job.Callback, debug.traceback)
                job.Busy = false
                if not ok then
                    self.H.Logger:Log("ERROR", name .. ": " .. tostring(err))
                    self.H.State.Errors[name] = tostring(err)
                    if job.OnError then
                        pcall(job.OnError, err)
                    end
                    self:Remove(name)
                end
            end)
        end
    end
end
function Scheduler:Destroy()
    self.Running = false
    for name in pairs(self.Jobs) do
        self:Remove(name)
    end
end
return Scheduler
