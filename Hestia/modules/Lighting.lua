local Lighting = {}
Lighting.__index = Lighting
function Lighting.new(h)
    return setmetatable({ H = h }, Lighting)
end
function Lighting:Restore()
    if self.Original then
        for key, value in pairs(self.Original) do
            self.H.Services.Lighting[key] = value
        end
        self.Original = nil
    end
end
function Lighting:RestoreFog()
    if self.FogOriginal then
        local lighting = self.H.Services.Lighting
        lighting.FogStart, lighting.FogEnd = self.FogOriginal.Start, self.FogOriginal.End
        self.FogOriginal = nil
    end
    for object, values in pairs(self.FogObjects or {}) do
        if object.Parent then
            for key, value in pairs(values) do
                object[key] = value
            end
        end
    end
    self.FogObjects = {}
end
function Lighting:HideFog(object)
    if not self.H.Config.Visuals.RemoveFog then
        return
    end
    self.FogObjects = self.FogObjects or {}
    if self.FogObjects[object] then
        return
    end
    local values
    if object:IsA("Atmosphere") then
        values = { Density = object.Density, Haze = object.Haze }
    elseif object:IsA("BasePart") then
        values = { LocalTransparencyModifier = object.LocalTransparencyModifier }
    elseif object:IsA("ParticleEmitter") or object:IsA("Beam") or object:IsA("Smoke") then
        values = { Enabled = object.Enabled }
    end
    if values then
        self.FogObjects[object] = values
        for key in pairs(values) do
            if key == "Enabled" then
                object[key] = false
            else
                object[key] = key == "LocalTransparencyModifier" and 1 or 0
            end
        end
    end
end
function Lighting:UpdateFog()
    if not self.H.Config.Visuals.RemoveFog then
        if self.FogOriginal or next(self.FogObjects or {}) then
            self:RestoreFog()
        end
        return
    end
    local lighting = self.H.Services.Lighting
    if not self.FogOriginal then
        self.FogOriginal = { Start = lighting.FogStart, End = lighting.FogEnd }
        for _, object in ipairs(lighting:GetChildren()) do
            if object:IsA("Atmosphere") then
                self:HideFog(object)
            end
        end
        local fog = workspace:FindFirstChild("Fog")
        if fog then
            self:HideFog(fog)
            for _, object in ipairs(fog:GetDescendants()) do
                self:HideFog(object)
            end
        end
    end
    lighting.FogStart, lighting.FogEnd = 1000000, 1000000
end
function Lighting:Start()
    self.H.Connections:Add(
        "HESTIA.Fog.Lighting",
        self.H.Services.Lighting.ChildAdded:Connect(function(object)
            if object:IsA("Atmosphere") then
                self:HideFog(object)
            end
        end)
    )
    self.H.Connections:Add(
        "HESTIA.Fog.World",
        workspace.DescendantAdded:Connect(function(object)
            local fog = workspace:FindFirstChild("Fog")
            if fog and (object == fog or object:IsDescendantOf(fog)) then
                self:HideFog(object)
            end
        end)
    )
    self.H.Scheduler:Add("Lighting", 0.5, function()
        self:UpdateFog()
        if self.H.Config.Visuals.Fullbright then
            local lighting = self.H.Services.Lighting
            if not self.Original then
                self.Original = {
                    Brightness = lighting.Brightness,
                    ClockTime = lighting.ClockTime,
                    Ambient = lighting.Ambient,
                }
            end
            lighting.Brightness = 2
            lighting.ClockTime = 14
            lighting.Ambient = Color3.fromRGB(170, 170, 180)
        else
            self:Restore()
        end
    end, function()
        self:Restore()
        self:RestoreFog()
    end)
end
function Lighting:Destroy()
    self.H.Scheduler:Remove("Lighting")
    self:Restore()
    self:RestoreFog()
    self.H.Connections:Remove("HESTIA.Fog.Lighting")
    self.H.Connections:Remove("HESTIA.Fog.World")
end
return Lighting
