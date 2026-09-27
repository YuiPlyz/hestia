local Adapter = {}
Adapter.__index = Adapter
-- HESTIA: the only module that knows experience layout and interaction contracts.
Adapter.Folders = {
    Characters = { "Characters", "NPCs", "Enemies" },
    Items = { "DroppedItems", "Items", "Drops" },
    Structures = { "Structures", "PlayerStructures", "Buildings" },
    Storage = { "Storage", "Storages" },
}
function Adapter.new(h, hooks)
    local self = setmetatable({ H = h, Hooks = hooks or {}, Lookup = {}, Watched = {}, NextId = 0 }, Adapter)
    for category, names in pairs(h:Import("Items")) do
        for _, name in ipairs(names) do
            self.Lookup[name] = category
        end
    end
    return self
end
function Adapter:Call(name, ...)
    local hook = self.Hooks[name]
    if not hook then
        self.H.Notifications:Send("Connect GameAdapter hook: " .. name, "HESTIA Integration", name, 60)
        return false, "Unsupported hook: " .. name
    end
    local results = table.pack(pcall(hook, ...))
    if not results[1] then
        self.H.Logger:Log("ERROR", name .. ": " .. tostring(results[2]))
        return false, tostring(results[2])
    end
    return table.unpack(results, 2, results.n)
end
function Adapter:Folder(kind)
    for _, name in ipairs(self.Folders[kind] or {}) do
        local folder = workspace:FindFirstChild(name)
        if folder then
            return folder
        end
    end
end
function Adapter:GetCharactersFolder()
    return self:Folder("Characters")
end
function Adapter:GetDroppedItemsFolder()
    return self:Folder("Items")
end
function Adapter:GetStructuresFolder()
    return self:Folder("Structures")
end
function Adapter:GetStorage()
    if self.Hooks.GetStorage then
        return self.Hooks.GetStorage()
    end
    local folder = self:Folder("Storage")
    return folder and (folder:IsA("Model") and folder or folder:FindFirstChildWhichIsA("Model"))
end
function Adapter:Root(object)
    if not object then
        return nil
    end
    if object:IsA("BasePart") then
        return object
    end
    if object:IsA("Model") then
        return object.PrimaryPart
            or object:FindFirstChild("HumanoidRootPart")
            or object:FindFirstChildWhichIsA("BasePart", true)
    end
    if object:IsA("Tool") then
        return object:FindFirstChild("Handle")
    end
end
function Adapter:Character()
    local player = self.H.Services.Players.LocalPlayer
    return player and player.Character
end
function Adapter:Humanoid()
    local character = self:Character()
    return character and character:FindFirstChildOfClass("Humanoid")
end
function Adapter:Distance(object)
    local root, target = self:Root(self:Character()), self:Root(object)
    return root and target and (root.Position - target.Position).Magnitude or math.huge
end
function Adapter:Valid(object)
    return typeof(object) == "Instance" and object:IsDescendantOf(workspace) and self:Root(object) ~= nil
end
function Adapter:Health(object)
    local hum = object and object:FindFirstChildOfClass("Humanoid")
    if hum then
        return hum.Health, hum.MaxHealth
    end
    if not object then
        return nil, nil
    end
    return object:GetAttribute("Health"), object:GetAttribute("MaxHealth")
end
function Adapter:Category(object)
    return object:GetAttribute("HestiaCategory")
        or (object.Name == "Scrap" and "Scrap")
        or self.Lookup[object.Name]
end
function Adapter:Classify(object)
    local sets = {}
    if not (object:IsA("Model") or object:IsA("BasePart") or object:IsA("Tool")) then
        return sets
    end
    local cs = self.H.Services.CollectionService
    for _, key in ipairs({ "Enemies", "Items", "Scrap", "Fuel", "Structures", "Generator", "Chest" }) do
        if cs:HasTag(object, "HESTIA_" .. key) then
            sets[key] = true
        end
    end
    local parent = object.Parent
    if parent == self:GetDroppedItemsFolder() then
        sets.Items = true
        local cat = self:Category(object)
        if cat == "Scrap" or cat == "Fuel" then
            sets[cat] = true
        end
    end
    if
        parent == self:GetCharactersFolder()
        and object:IsA("Model")
        and not self.H.Services.Players:GetPlayerFromCharacter(object)
    then
        sets.Enemies = true
    end
    if parent == self:GetStructuresFolder() then
        sets.Structures = true
    end
    if object.Name == "Generator" then
        sets.Generator = true
    end
    if object.Name == "Chest" then
        sets.Chest = true
    end
    if sets.Scrap or sets.Fuel then
        sets.Items = true
    end
    if object:IsA("Model") and self.H.Services.Players:GetPlayerFromCharacter(object) then
        sets = { Players = true }
    end
    return sets
end
function Adapter:Refresh(object)
    local sets = object:IsDescendantOf(workspace) and self:Classify(object) or {}
    for kind, registry in pairs(self.H.Registry) do
        registry[object] = sets[kind] or nil
    end
end
function Adapter:Watch(object)
    if self.Watched[object] or not (object:IsA("Model") or object:IsA("BasePart") or object:IsA("Tool")) then
        return
    end
    -- Models and tools can move into tracked folders later. Ignore decorative parts.
    if object:IsA("BasePart") and not next(self:Classify(object)) then
        return
    end
    self.NextId = self.NextId + 1
    local id = "HESTIA.Registry." .. self.NextId
    self.Watched[object] = id
    self.H.Connections:Add(
        id,
        object.AncestryChanged:Connect(function()
            self:Refresh(object)
        end)
    )
    self.H.Connections:Add(
        id .. ".Category",
        object:GetAttributeChangedSignal("HestiaCategory"):Connect(function()
            self:Refresh(object)
        end)
    )
    self:Refresh(object)
end
function Adapter:Forget(object)
    for _, registry in pairs(self.H.Registry) do
        registry[object] = nil
    end
    local id = self.Watched[object]
    if id then
        self.H.Connections:Remove(id)
        self.H.Connections:Remove(id .. ".Category")
    end
    self.Watched[object] = nil
end
function Adapter:Start()
    local function bindFolder(folder)
        for _, names in pairs(self.Folders) do
            if table.find(names, folder.Name) then
                self.H.Connections:Add(
                    "HESTIA.Folder." .. folder.Name,
                    folder.ChildAdded:Connect(function(object)
                        self:Watch(object)
                        self:Refresh(object)
                    end)
                )
                for _, object in ipairs(folder:GetChildren()) do
                    self:Watch(object)
                    self:Refresh(object)
                end
            end
        end
    end
    self.H.Connections:Add("HESTIA.FolderAdded", workspace.ChildAdded:Connect(bindFolder))
    for _, folder in ipairs(workspace:GetChildren()) do
        bindFolder(folder)
    end
    self.H.Connections:Add(
        "HESTIA.Registry.Add",
        workspace.DescendantAdded:Connect(function(object)
            self:Watch(object)
        end)
    )
    self.H.Connections:Add(
        "HESTIA.Registry.Remove",
        workspace.DescendantRemoving:Connect(function(object)
            self:Forget(object)
        end)
    )
    for kind in pairs(self.H.Registry) do
        local tag = "HESTIA_" .. kind
        self.H.Connections:Add(
            tag .. ".Add",
            self.H.Services.CollectionService:GetInstanceAddedSignal(tag):Connect(function(object)
                self:Watch(object)
                self:Refresh(object)
            end)
        )
        self.H.Connections:Add(
            tag .. ".Remove",
            self.H.Services.CollectionService:GetInstanceRemovedSignal(tag):Connect(function(object)
                self:Refresh(object)
            end)
        )
    end
    -- One initial scan; all subsequent registry changes are event driven.
    for _, object in ipairs(workspace:GetDescendants()) do
        self:Watch(object)
    end
    self.H.Logger:Log("SUCCESS", "Object registries initialized")
end
function Adapter:GetEnemies()
    return self.H.Registry.Enemies
end
function Adapter:GetScrap()
    return self.H.Registry.Scrap
end
function Adapter:GetFuel()
    return self.H.Registry.Fuel
end
function Adapter:GetGenerator()
    for object in pairs(self.H.Registry.Generator) do
        if self:Valid(object) then
            return object
        end
    end
end
function Adapter:GetFuelPercent()
    local generator = self:GetGenerator()
    if self.Hooks.GetFuelPercent then
        return self.Hooks.GetFuelPercent(generator)
    end
    if not generator then
        return nil
    end
    local fuel, maximum = generator:GetAttribute("Fuel"), generator:GetAttribute("MaxFuel")
    if type(fuel) == "number" and type(maximum) == "number" and maximum > 0 then
        return math.clamp(fuel / maximum * 100, 0, 100)
    end
end
function Adapter:GetInventory()
    if self.Hooks.GetInventory then
        return self.Hooks.GetInventory()
    end
    local result = {}
    local player = self.H.Services.Players.LocalPlayer
    for _, container in pairs({ player:FindFirstChild("Backpack"), self:Character() }) do
        for _, object in ipairs(container:GetChildren()) do
            if object:IsA("Tool") then
                table.insert(result, {
                    Instance = object,
                    Name = object.Name,
                    Category = self:Category(object),
                    Quantity = object:GetAttribute("Quantity") or 1,
                })
            end
        end
    end
    return result
end
function Adapter:InventoryFull()
    if self.Hooks.InventoryFull then
        return self.Hooks.InventoryFull()
    end
    local player = self.H.Services.Players.LocalPlayer
    local capacity = player:GetAttribute("InventoryCapacity")
    return type(capacity) == "number" and #self:GetInventory() >= capacity
end
function Adapter:Vitals()
    if self.Hooks.Vitals then
        return self.Hooks.Vitals()
    end
    local char = self:Character()
    local hp, max = self:Health(char)
    return {
        Health = hp and max and max > 0 and hp / max * 100 or 100,
        Hunger = char and char:GetAttribute("Hunger") or 100,
        Thirst = char and char:GetAttribute("Thirst") or 100,
        Bleeding = char and char:GetAttribute("Bleeding") == true,
    }
end
function Adapter:CollectItem(item)
    return self:Call("CollectItem", item)
end
function Adapter:AddFuel(generator, fuel)
    return self:Call("AddFuel", generator, fuel)
end
function Adapter:AttackTarget(target)
    if not target:IsA("Model") then
        return false, "NPC models only"
    end
    if self.H.Services.Players:GetPlayerFromCharacter(target) then
        return false, "NPC targets only"
    end
    return self:Call("AttackTarget", target)
end
function Adapter:StoreItem(item, quantity, storage)
    return self:Call("StoreItem", item, quantity, storage)
end
function Adapter:RepairStructure(object)
    return self:Call("RepairStructure", object)
end
function Adapter:UseSurvival(kind)
    return self:Call("UseSurvival", kind)
end
function Adapter:HasRepairEquipment()
    for _, item in ipairs(self:GetInventory()) do
        if item.Name == "Repair Hammer" then
            return true
        end
    end
    return false
end
function Adapter:EquipWeapon()
    if self.Hooks.EquipWeapon then
        return self.Hooks.EquipWeapon()
    end
    local best, speed = nil, math.huge
    for _, item in ipairs(self:GetInventory()) do
        local data = self.H:Import("Weapons")[item.Name]
        if data and data.SwingDelay < speed then
            best, speed = item.Instance, data.SwingDelay
        end
    end
    local hum = self:Humanoid()
    if best and hum then
        hum:EquipTool(best)
        return true
    end
    return false
end
function Adapter:CanUseMovement()
    return self.H.Services.RunService:IsStudio()
        or self.H.Services.Players.LocalPlayer:GetAttribute("HESTIA_AllowMovement") == true
end
function Adapter:Teleport(cframe)
    if self.Hooks.Teleport then
        return self.Hooks.Teleport(cframe)
    end
    if not self:CanUseMovement() then
        return false, "Movement permission required"
    end
    local char = self:Character()
    if char then
        char:PivotTo(cframe)
        return true
    end
    return false, "No character"
end
function Adapter:GetLocation(name)
    if self.Hooks.GetLocation then
        return self.Hooks.GetLocation(name)
    end
    local path = self.H:Import("Locations")[name]
    local node = workspace
    for _, part in ipairs(path or {}) do
        node = node and node:FindFirstChild(part)
    end
    if not node and name == "Spawn" then
        node = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
    end
    local root = path and self:Root(node)
    return root and root.CFrame
end
function Adapter:Destroy()
    for object in pairs(self.Watched) do
        self:Forget(object)
    end
end
return Adapter
