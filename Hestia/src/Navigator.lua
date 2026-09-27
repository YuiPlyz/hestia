local Navigator = {}
Navigator.__index = Navigator
function Navigator.new(h)
    return setmetatable({ H = h }, Navigator)
end
function Navigator:Cancel(owner)
    if owner and self.Owner ~= owner then
        return
    end
    self.Generation = (self.Generation or 0) + 1
    self.Owner, self.Target, self.Waypoints = nil, nil, nil
    local hum, root = self.H.Adapter:Humanoid(), self.H.Adapter:Root(self.H.Adapter:Character())
    if hum and root then
        hum:MoveTo(root.Position)
    end
end
-- Nonblocking navigation: path computation may yield, but its result needs a valid lease.
function Navigator:Step(owner, target, range)
    local h, a = self.H, self.H.Adapter
    if not h.Tasks:IsOwner(owner) then
        return "Paused"
    end
    if not a:Valid(target) then
        self:Cancel(owner)
        return "Invalid"
    end
    local root, hum = a:Root(a:Character()), a:Humanoid()
    if not root or not hum or hum.Health <= 0 then
        return "NoCharacter"
    end
    if a:Distance(target) <= (range or 5) then
        self:Cancel(owner)
        return "Arrived"
    end
    if self.Owner ~= owner or self.Target ~= target then
        self:Cancel()
        self.Owner, self.Target, self.Started, self.ProgressAt = owner, target, os.clock(), os.clock()
        self.LastPosition, self.Attempts, self.NextPath = root.Position, 0, 0
    end
    local config, now = h.Config.Farming, os.clock()
    if now - self.Started > config.TargetTimeout then
        self:Cancel(owner)
        return "Timeout"
    end
    if (root.Position - self.LastPosition).Magnitude > 1 then
        self.LastPosition, self.ProgressAt = root.Position, now
    elseif now - self.ProgressAt > config.StuckTimeout then
        self.Waypoints, self.ProgressAt = nil, now
        self.Attempts = self.Attempts + 1
    end
    if self.Attempts > config.PathRetries then
        self:Cancel(owner)
        return "Unreachable"
    end
    if not self.Waypoints then
        if now < self.NextPath then
            return "Moving"
        end
        self.NextPath = now + 0.5
        local generation, token = self.Generation, h.Tasks.Serial
        local destination = a:Root(target).Position
        local path = h.Services.PathfindingService:CreatePath({ AgentCanJump = true })
        local ok = pcall(function()
            path:ComputeAsync(root.Position, destination)
        end)
        if generation ~= self.Generation or not h.Tasks:IsOwner(owner, token) or not a:Valid(target) then
            return "Paused"
        end
        if not ok or path.Status ~= Enum.PathStatus.Success then
            self.Attempts = self.Attempts + 1
            return "Moving"
        end
        self.Waypoints, self.Index, self.Destination = path:GetWaypoints(), 2, destination
    end
    if (a:Root(target).Position - self.Destination).Magnitude > 6 then
        self.Waypoints = nil
        return "Moving"
    end
    local point = self.Waypoints[self.Index]
    if not point then
        self.Waypoints = nil
        return "Moving"
    end
    if (root.Position - point.Position).Magnitude < 3 then
        self.Index = self.Index + 1
    end
    if point.Action == Enum.PathWaypointAction.Jump then
        hum.Jump = true
    end
    hum:MoveTo(point.Position)
    return "Moving"
end
return Navigator
