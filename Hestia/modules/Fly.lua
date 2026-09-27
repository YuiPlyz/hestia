local Fly = {}
Fly.__index = Fly
function Fly.new(h)
    return setmetatable({ H = h }, Fly)
end
function Fly:Step()
    local h, root, hum = self.H, self.H.Adapter:Root(self.H.Adapter:Character()), self.H.Adapter:Humanoid()
    if self.Root ~= root then
        self:Stop()
    end
    if not root or not hum then
        return
    end
    if not self.Velocity then
        self.Root, self.Humanoid, self.AutoRotate = root, hum, hum.AutoRotate
        self.Attachment = Instance.new("Attachment")
        self.Attachment.Name = "HESTIA Flight"
        self.Attachment.Parent = root
        self.Velocity = Instance.new("LinearVelocity")
        self.Velocity.Attachment0 = self.Attachment
        self.Velocity.MaxForce = math.huge
        self.Velocity.RelativeTo = Enum.ActuatorRelativeTo.World
        self.Velocity.Parent = root
        hum.AutoRotate = false
    end
    local input, camera = h.Services.UserInputService, workspace.CurrentCamera
    local direction = Vector3.zero
    if not input:GetFocusedTextBox() and camera then
        if input:IsKeyDown(Enum.KeyCode.W) then
            direction = direction + camera.CFrame.LookVector
        end
        if input:IsKeyDown(Enum.KeyCode.S) then
            direction = direction - camera.CFrame.LookVector
        end
        if input:IsKeyDown(Enum.KeyCode.D) then
            direction = direction + camera.CFrame.RightVector
        end
        if input:IsKeyDown(Enum.KeyCode.A) then
            direction = direction - camera.CFrame.RightVector
        end
        if input:IsKeyDown(Enum.KeyCode.Space) then
            direction = direction + Vector3.yAxis
        end
        if input:IsKeyDown(Enum.KeyCode.LeftControl) then
            direction = direction - Vector3.yAxis
        end
    end
    self.Velocity.VectorVelocity = direction.Magnitude > 0 and direction.Unit * h.Config.Player.FlySpeed
        or Vector3.zero
end
function Fly:Stop()
    if self.Velocity then
        self.Velocity:Destroy()
    end
    if self.Attachment then
        self.Attachment:Destroy()
    end
    if self.Humanoid and self.Humanoid.Parent then
        self.Humanoid.AutoRotate = self.AutoRotate
    end
    self.Velocity, self.Attachment, self.Root, self.Humanoid = nil, nil, nil, nil
end
Fly.Destroy = Fly.Stop
return Fly
