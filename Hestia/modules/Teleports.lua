local Teleports = {}
Teleports.__index = Teleports
function Teleports.new(h)
    return setmetatable({ H = h }, Teleports)
end
function Teleports:Save(name)
    assert(
        type(name) == "string" and #name > 0 and #name <= 64,
        "HESTIA location name must be 1-64 characters"
    )
    local root = self.H.Adapter:Root(self.H.Adapter:Character())
    if root then
        self.H.Config.Teleports.Saved[name] = { root.CFrame:GetComponents() }
        return true
    end
    return false
end
function Teleports:Resolve(name)
    local h = self.H
    local saved = h.Config.Teleports.Saved[name]
    if saved then
        return CFrame.new(table.unpack(saved))
    end
    if name == "Spawn" then
        return h.Adapter:GetLocation("Spawn")
    end
    local object
    if name == "Generator" then
        object = h.Adapter:GetGenerator()
    elseif name == "Selected Player" then
        local player = h.Services.Players:FindFirstChild(h.Config.Teleports.SelectedPlayer)
        object = player and player.Character
    else
        local set = ({
            ["Nearest Scrap"] = "Scrap",
            ["Nearest Fuel"] = "Fuel",
            ["Nearest Chest"] = "Chest",
            ["Nearest Enemy"] = "Enemies",
        })[name]
        if set then
            object = h:Import("Utilities").Nearest(h, h.Registry[set], math.huge)
        end
    end
    local root = h.Adapter:Root(object)
    return root and root.CFrame + Vector3.new(0, 4, 0)
end
function Teleports:Go(name)
    local target = self:Resolve(name)
    if not target then
        return false, "Location unavailable: " .. name
    end
    self.H.Tasks:Request("Teleport", 120)
    local ok, reason = self.H.Adapter:Teleport(target)
    self.H.Tasks:Release("Teleport")
    return ok, reason
end
return Teleports
