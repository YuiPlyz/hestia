local Connections = {}
Connections.__index = Connections
function Connections.new()
    return setmetatable({ Entries = {} }, Connections)
end
function Connections:Add(name, connection)
    self:Remove(name)
    self.Entries[name] = connection
    return connection
end
function Connections:Remove(name)
    local entry = self.Entries[name]
    self.Entries[name] = nil
    if entry then
        entry:Disconnect()
    end
end
function Connections:DisconnectAll()
    for name in pairs(self.Entries) do
        self:Remove(name)
    end
end
return Connections
