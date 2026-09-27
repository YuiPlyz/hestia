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
function Lighting:Start()
    self.H.Scheduler:Add("Lighting", 0.5, function()
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
    end)
end
function Lighting:Destroy()
    self.H.Scheduler:Remove("Lighting")
    self:Restore()
end
return Lighting
