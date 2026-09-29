local Noclip = {}
Noclip.__index = Noclip
function Noclip.new(h)
    return setmetatable({ H = h, Original = {} }, Noclip)
end
function Noclip:Step()
    local char = self.H.Adapter:Character()
    if self.Character ~= char then
        self:Stop()
        self.Character = char
    end
    if not char then
        return
    end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if self.Original[part] == nil then
                self.Original[part] = part.CanCollide
            end
            part.CanCollide = false
        end
    end
end
function Noclip:Stop()
    for part, value in pairs(self.Original) do
        if part.Parent then
            part.CanCollide = value
        end
    end
    table.clear(self.Original)
    self.Character = nil
end
Noclip.Destroy = Noclip.Stop
return Noclip
