local Movement = {}
Movement.__index = Movement
function Movement.new(h)
    return setmetatable({ H = h, Fly = h:Import("Fly").new(h), Noclip = h:Import("Noclip").new(h) }, Movement)
end
function Movement:Restore()
    if self.Humanoid and self.Humanoid.Parent and self.Original then
        for key, value in pairs(self.Original) do
            self.Humanoid[key] = value
        end
    end
    self.Humanoid, self.Original = nil, nil
end
function Movement:Step()
    local h, c = self.H, self.H.Config.Player
    if not h.Adapter:CanUseMovement() then
        self:Restore()
        self.Fly:Stop()
        self.Noclip:Stop()
        return
    end
    local hum = h.Adapter:Humanoid()
    if self.Humanoid ~= hum then
        self:Restore()
    end
    if hum and (c.OverrideMovement or c.AutoSprint) then
        if not self.Original then
            self.Humanoid = hum
            self.Original =
                { WalkSpeed = hum.WalkSpeed, JumpPower = hum.JumpPower, UseJumpPower = hum.UseJumpPower }
        end
        hum.WalkSpeed = c.AutoSprint and c.SprintSpeed
            or (c.OverrideMovement and c.WalkSpeed or self.Original.WalkSpeed)
        hum.UseJumpPower = c.OverrideMovement or self.Original.UseJumpPower
        hum.JumpPower = c.OverrideMovement and c.JumpPower or self.Original.JumpPower
    else
        self:Restore()
    end
    if c.Fly then
        if h.Tasks:Request("ManualFlight", 110) then
            self.Fly:Step()
        else
            self.Fly:Stop()
        end
    else
        h.Tasks:Release("ManualFlight")
        self.Fly:Stop()
    end
    if c.Noclip then
        self.Noclip:Step()
    else
        self.Noclip:Stop()
    end
    if hum and c.BunnyHop and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end
end
function Movement:Start()
    self.H.Connections:Add(
        "HESTIA.Movement",
        self.H.Services.RunService.PreSimulation:Connect(function()
            self:Step()
        end)
    )
    self.H.Connections:Add(
        "HESTIA.Jump",
        self.H.Services.UserInputService.JumpRequest:Connect(function()
            local hum = self.H.Adapter:Humanoid()
            if hum and self.H.Config.Player.InfiniteJump and self.H.Adapter:CanUseMovement() then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    )
end
function Movement:Reset()
    local c = self.H.Config.Player
    for _, key in ipairs({ "AutoSprint", "InfiniteJump", "Noclip", "Fly", "OverrideMovement", "BunnyHop" }) do
        c[key] = false
    end
    self:Restore()
    self.Fly:Stop()
    self.Noclip:Stop()
    self.H.Tasks:Release("ManualFlight")
end
function Movement:Stop()
    self:Reset()
    self.H.Connections:Remove("HESTIA.Movement")
    self.H.Connections:Remove("HESTIA.Jump")
end
Movement.Destroy = Movement.Stop
return Movement
